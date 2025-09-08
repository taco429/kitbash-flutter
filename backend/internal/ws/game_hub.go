package ws

import (
	"context"
	"encoding/json"
	"net/http"
	"sync"
	"math/rand"
	"time"

	"kitbash/backend/internal/config"
	"kitbash/backend/internal/domain"
	"kitbash/backend/internal/logger"
	"kitbash/backend/internal/repository"

	"github.com/gorilla/websocket"
)

// GameClient represents a connected client for a specific game.
type GameClient struct {
	Conn     *websocket.Conn
	GameID   domain.GameID
	PlayerID domain.PlayerID
}

// GameHub manages WebSocket connections for game instances.
type GameHub struct {
	mu         sync.RWMutex
	gameRepo   repository.GameRepository
	deckRepo   domain.DeckRepository
	clients    map[domain.GameID]map[*websocket.Conn]*GameClient
	upgrader   websocket.Upgrader
	log        *logger.Logger
	cfg        config.Config
	phaseTimers map[domain.GameID]*time.Timer
}

// NewGameHub creates a new game hub with game state management.
func NewGameHub(gameRepo repository.GameRepository, log *logger.Logger, cfg config.Config) *GameHub {
	if log == nil {
		log = logger.Default()
	}
	return &GameHub{
		gameRepo: gameRepo,
		clients:  make(map[domain.GameID]map[*websocket.Conn]*GameClient),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		},
		log: log,
		cfg: cfg,
		phaseTimers: make(map[domain.GameID]*time.Timer),
	}
}

// NewGameHubWithRepos creates a new game hub with both game and deck repositories.
func NewGameHubWithRepos(gameRepo repository.GameRepository, deckRepo domain.DeckRepository, log *logger.Logger, cfg config.Config) *GameHub {
	hub := NewGameHub(gameRepo, log, cfg)
	hub.deckRepo = deckRepo
	return hub
}

// HandleGameWS handles WebSocket connections for specific games.
func (h *GameHub) HandleGameWS(w http.ResponseWriter, r *http.Request, gameID string) {
	h.log.WithContext(r.Context()).Info("Game WebSocket upgrade requested",
		"game_id", gameID,
		"remote_addr", r.RemoteAddr)

	conn, err := h.upgrader.Upgrade(w, r, nil)
	if err != nil {
		h.log.LogError(r.Context(), err, "WebSocket upgrade failed")
		http.Error(w, "upgrade failed", http.StatusBadRequest)
		return
	}

	// Get or create game state
	gameState, err := h.getOrCreateGameState(r.Context(), gameID)
	if err != nil {
		h.log.LogError(r.Context(), err, "Failed to get/create game state")
		conn.Close()
		return
	}

	// Create client
	client := &GameClient{
		Conn:     conn,
		GameID:   domain.GameID(gameID),
		PlayerID: "player", // TODO: Get from authentication
	}

	// Add client to game
	h.addClient(client)

	h.log.WithContext(r.Context()).Info("Game WebSocket connection established",
		"game_id", gameID,
		"remote_addr", conn.RemoteAddr().String())

	// Send initial game state
	if err := h.sendGameState(client, gameState); err != nil {
		h.log.LogError(r.Context(), err, "Failed to send initial game state")
	}

	defer func() {
		h.removeClient(client)
		h.log.WithContext(r.Context()).Info("Game WebSocket connection closed",
			"game_id", gameID,
			"remote_addr", conn.RemoteAddr().String())
		conn.Close()
	}()

	// Handle messages
	for {
		messageType, msg, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				h.log.LogError(r.Context(), err, "WebSocket read error")
			}
			break
		}

		h.log.LogWebSocketEvent(r.Context(), "game_message_received", map[string]interface{}{
			"game_id":      gameID,
			"remote_addr":  conn.RemoteAddr().String(),
			"message_type": messageType,
			"message":      string(msg),
		})

		if err := h.handleGameMessage(r.Context(), client, msg); err != nil {
			h.log.LogError(r.Context(), err, "Error handling game message")
		}
	}
}

// addClient adds a client to a game's client list.
func (h *GameHub) addClient(client *GameClient) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.clients[client.GameID] == nil {
		h.clients[client.GameID] = make(map[*websocket.Conn]*GameClient)
	}
	h.clients[client.GameID][client.Conn] = client
}

// removeClient removes a client from a game's client list.
func (h *GameHub) removeClient(client *GameClient) {
	h.mu.Lock()
	defer h.mu.Unlock()

	if gameClients, exists := h.clients[client.GameID]; exists {
		delete(gameClients, client.Conn)
		if len(gameClients) == 0 {
			delete(h.clients, client.GameID)
		}
	}
}

// getOrCreateGameState retrieves existing game state or creates a new one.
func (h *GameHub) getOrCreateGameState(ctx context.Context, gameID string) (*domain.GameState, error) {
	// Try to get existing game state
	gameState, err := h.gameRepo.Get(ctx, domain.GameID(gameID))
	if err == nil {
		return gameState, nil
	}

	// Create new game state with default players
	players := []domain.Player{
		{ID: "player", Name: "Player"},
		{ID: "cpu", Name: "CPU"},
	}

	gameState, err = h.gameRepo.Create(ctx, domain.GameID(gameID), players, h.cfg.BoardRows, h.cfg.BoardCols)
	if err != nil {
		return nil, err
	}

	// Assign decks and draw initial hands if deck repository is available
	if h.deckRepo != nil {
		h.assignTestDecksAndHands(ctx, gameState)
	}

	// Start the game immediately for testing
	gameState.StartGame()
	// Set initial phase to Draw & Income
	gameState.SetPhase(domain.PhaseDrawIncome)
	if err := h.gameRepo.Update(ctx, gameState); err != nil {
		h.log.LogError(ctx, err, "Failed to update game state after starting")
	}

	// Start the phase progression
	go func() {
		time.Sleep(2 * time.Second)
		h.advanceToPhase(context.Background(), gameState.ID, domain.PhasePlanning)
	}()

	return gameState, nil
}

// sendGameState sends the current game state to a client.
func (h *GameHub) sendGameState(client *GameClient, gameState *domain.GameState) error {
	message := map[string]interface{}{
		"type":      "game_state",
		"gameState": gameState,
	}
	return client.Conn.WriteJSON(message)
}

// broadcastGameState sends the game state to all clients in a game.
func (h *GameHub) broadcastGameState(ctx context.Context, gameID domain.GameID) error {
	gameState, err := h.gameRepo.Get(ctx, gameID)
	if err != nil {
		return err
	}

	h.mu.RLock()
	gameClients, exists := h.clients[gameID]
	if !exists {
		h.mu.RUnlock()
		return nil
	}

	// Create a copy of clients to avoid holding the lock during broadcast
	clients := make([]*GameClient, 0, len(gameClients))
	for _, client := range gameClients {
		clients = append(clients, client)
	}
	h.mu.RUnlock()

	message := map[string]interface{}{
		"type":      "game_state",
		"gameState": gameState,
	}

	for _, client := range clients {
		if err := client.Conn.WriteJSON(message); err != nil {
			h.log.LogError(ctx, err, "Failed to send game state to client")
		}
	}

	return nil
}

// handleGameMessage processes incoming game messages.
func (h *GameHub) handleGameMessage(ctx context.Context, client *GameClient, msg []byte) error {
	var message map[string]interface{}
	if err := json.Unmarshal(msg, &message); err != nil {
		return err
	}

	msgType, ok := message["type"].(string)
	if !ok {
		return nil
	}

	switch msgType {
	case "deal_damage":
		return h.handleDealDamage(ctx, client, message)
	case "get_game_state":
		return h.handleGetGameState(ctx, client)
	case "lock_choice":
		return h.handleLockChoice(ctx, client, message)
	case "submit_actions":
		return h.handleSubmitActions(ctx, client, message)
	case "advance_phase":
		return h.handleAdvancePhase(ctx, client)
	default:
		h.log.WithContext(ctx).Debug("Unknown message type", "type", msgType)
	}

	return nil
}

// handleDealDamage processes damage dealing actions.
func (h *GameHub) handleDealDamage(ctx context.Context, client *GameClient, message map[string]interface{}) error {
	playerIndex, ok := message["playerIndex"].(float64)
	if !ok {
		return nil
	}

	damage, ok := message["damage"].(float64)
	if !ok {
		damage = 10 // Default damage
	}

	gameState, err := h.gameRepo.Get(ctx, client.GameID)
	if err != nil {
		return err
	}

	destroyed := gameState.DealDamageToCommandCenter(int(playerIndex), int(damage))

	if err := h.gameRepo.Update(ctx, gameState); err != nil {
		return err
	}

	h.log.WithContext(ctx).Info("Damage dealt to command center",
		"game_id", client.GameID,
		"player_index", int(playerIndex),
		"damage", int(damage),
		"destroyed", destroyed)

	// Broadcast updated game state to all clients
	return h.broadcastGameState(ctx, client.GameID)
}

// handleGetGameState sends the current game state to the requesting client.
func (h *GameHub) handleGetGameState(ctx context.Context, client *GameClient) error {
	gameState, err := h.gameRepo.Get(ctx, client.GameID)
	if err != nil {
		return err
	}

	return h.sendGameState(client, gameState)
}

// handleLockChoice processes player choice locking for simultaneous turns.
func (h *GameHub) handleLockChoice(ctx context.Context, client *GameClient, message map[string]interface{}) error {
	playerIndex, ok := message["playerIndex"].(float64)
	if !ok {
		return nil
	}

	gameState, err := h.gameRepo.Get(ctx, client.GameID)
	if err != nil {
		return err
	}

	// Only allow locking during Planning phase
	if gameState.CurrentPhase != domain.PhasePlanning {
		h.log.WithContext(ctx).Warn("Lock choice attempted outside planning phase",
			"game_id", client.GameID,
			"current_phase", gameState.CurrentPhase)
		return nil
	}

	// Queue discard cards if provided (processed at end of round)
	if discardCards, ok := message["discardCards"].([]interface{}); ok && len(discardCards) > 0 {
		var instanceIDs []domain.CardInstanceID
		for _, card := range discardCards {
			if cardStr, ok := card.(string); ok {
				instanceIDs = append(instanceIDs, domain.CardInstanceID(cardStr))
			}
		}
		if len(instanceIDs) > 0 {
			if int(playerIndex) >= 0 && int(playerIndex) < len(gameState.PlayerStates) {
				ps := &gameState.PlayerStates[int(playerIndex)]
				ps.PendingDiscards = append(ps.PendingDiscards, instanceIDs...)
				h.log.WithContext(ctx).Info("Cards queued for discard",
					"game_id", client.GameID,
					"player_index", int(playerIndex),
					"cards", instanceIDs)
			}
		}
	}

	// Lock the player's choice
	gameState.LockPlayerChoice(int(playerIndex))

	// Save the updated game state
	if err := h.gameRepo.Update(ctx, gameState); err != nil {
		return err
	}

	h.log.WithContext(ctx).Info("Player locked choice",
		"game_id", client.GameID,
		"player_index", int(playerIndex),
		"current_turn", gameState.CurrentTurn,
		"current_phase", gameState.CurrentPhase)

	// Notify all clients that a player has locked
	h.broadcastPlayerLocked(ctx, client.GameID, int(playerIndex))

	// Check if all players have locked their choices
	if gameState.AreAllPlayersLocked() {
		h.log.WithContext(ctx).Info("All players locked - advancing to Reveal & Resolve",
			"game_id", client.GameID,
			"current_turn", gameState.CurrentTurn)

		// Cancel the planning phase timer if it exists
		h.cancelPhaseTimer(client.GameID)

		// Advance to Reveal & Resolve phase
		return h.advanceToPhase(ctx, client.GameID, domain.PhaseRevealResolve)
	}

	return h.broadcastGameState(ctx, client.GameID)
}

// handleSubmitActions receives a player's action queue for the current round.
func (h *GameHub) handleSubmitActions(ctx context.Context, client *GameClient, message map[string]interface{}) error {
	playerIndexF, ok := message["playerIndex"].(float64)
	if !ok {
		return nil
	}
	actionsRaw, ok := message["actions"].([]interface{})
	if !ok {
		return nil
	}

	gameState, err := h.gameRepo.Get(ctx, client.GameID)
	if err != nil {
		return err
	}

	queue := make(domain.ActionQueue, 0, len(actionsRaw))
	for _, a := range actionsRaw {
		b, _ := json.Marshal(a)
		var act domain.Action
		if err := json.Unmarshal(b, &act); err == nil {
			act.PlayerIndex = int(playerIndexF)
			queue = append(queue, act)
		}
	}

	if gameState.PendingActions == nil {
		gameState.PendingActions = map[int]domain.ActionQueue{0: {}, 1: {}}
	}
	gameState.PendingActions[int(playerIndexF)] = queue

	if err := h.gameRepo.Update(ctx, gameState); err != nil {
		return err
	}

	h.log.WithContext(ctx).Info("Player submitted actions",
		"game_id", client.GameID,
		"player_index", int(playerIndexF),
		"count", len(queue))

	return h.broadcastGameState(ctx, client.GameID)
}

// broadcastPlayerLocked notifies all clients that a player has locked their choice.
func (h *GameHub) broadcastPlayerLocked(ctx context.Context, gameID domain.GameID, playerIndex int) {
	h.mu.RLock()
	gameClients, exists := h.clients[gameID]
	if !exists {
		h.mu.RUnlock()
		return
	}

	clients := make([]*GameClient, 0, len(gameClients))
	for _, client := range gameClients {
		clients = append(clients, client)
	}
	h.mu.RUnlock()

	message := map[string]interface{}{
		"type":        "player_locked",
		"playerIndex": playerIndex,
	}

	for _, client := range clients {
		if err := client.Conn.WriteJSON(message); err != nil {
			h.log.LogError(ctx, err, "Failed to send player locked notification")
		}
	}
}

// broadcastTurnAdvanced notifies all clients that the turn has advanced.
func (h *GameHub) broadcastTurnAdvanced(ctx context.Context, gameID domain.GameID, newTurn int) {
	h.mu.RLock()
	gameClients, exists := h.clients[gameID]
	if !exists {
		h.mu.RUnlock()
		return
	}

	clients := make([]*GameClient, 0, len(gameClients))
	for _, client := range gameClients {
		clients = append(clients, client)
	}
	h.mu.RUnlock()

	message := map[string]interface{}{
		"type":    "turn_advanced",
		"newTurn": newTurn,
	}

	for _, client := range clients {
		if err := client.Conn.WriteJSON(message); err != nil {
			h.log.LogError(ctx, err, "Failed to send turn advanced notification")
		}
	}
}

// assignTestDecksAndHands assigns prebuilt decks and draws initial hands for players.
func (h *GameHub) assignTestDecksAndHands(ctx context.Context, gs *domain.GameState) {
	decks, err := h.deckRepo.GetPrebuiltDecks(ctx)
	if err != nil || len(decks) == 0 {
		h.log.WithContext(ctx).Warn("No prebuilt decks available for assignment")
		return
	}

	// Choose two decks: randomly for variety
	rand.Seed(time.Now().UnixNano())
	var idx0 = 0
	var idx1 = 1
	if len(decks) > 1 {
		idx0 = rand.Intn(len(decks))
		for {
			idx1 = rand.Intn(len(decks))
			if idx1 != idx0 {
				break
			}
		}
	}
	deck0 := decks[idx0]
	deck1 := decks[idx1%len(decks)]

	gs.PlayerStates = make([]domain.PlayerBattleState, 2)
	gs.PlayerStates[0] = buildPlayerStateFromDeck(0, deck0)
	gs.PlayerStates[1] = buildPlayerStateFromDeck(1, deck1)

	// Draw initial hands (7 cards)
	drawCardsForPlayer(&gs.PlayerStates[0], 7)
	drawCardsForPlayer(&gs.PlayerStates[1], 7)
}

// handleAdvancePhase manually advances to the next phase (for testing or timeout).
func (h *GameHub) handleAdvancePhase(ctx context.Context, client *GameClient) error {
	gameState, err := h.gameRepo.Get(ctx, client.GameID)
	if err != nil {
		return err
	}

	var nextPhase domain.GamePhase
	switch gameState.CurrentPhase {
	case domain.PhaseDrawIncome:
		nextPhase = domain.PhasePlanning
	case domain.PhasePlanning:
		nextPhase = domain.PhaseRevealResolve
	case domain.PhaseRevealResolve:
		nextPhase = domain.PhaseCleanup
	case domain.PhaseCleanup:
		// Start new turn
		gameState.AdvanceTurn()
		if err := h.gameRepo.Update(ctx, gameState); err != nil {
			return err
		}
		h.broadcastTurnAdvanced(ctx, client.GameID, gameState.CurrentTurn)
		return h.advanceToPhase(ctx, client.GameID, domain.PhaseDrawIncome)
	default:
		nextPhase = domain.PhaseDrawIncome
	}

	return h.advanceToPhase(ctx, client.GameID, nextPhase)
}

// advanceToPhase transitions the game to the specified phase.
func (h *GameHub) advanceToPhase(ctx context.Context, gameID domain.GameID, phase domain.GamePhase) error {
	gameState, err := h.gameRepo.Get(ctx, gameID)
	if err != nil {
		return err
	}

	gameState.SetPhase(phase)

	// Save the updated game state
	if err := h.gameRepo.Update(ctx, gameState); err != nil {
		return err
	}

	h.log.WithContext(ctx).Info("Phase advanced",
		"game_id", gameID,
		"new_phase", phase,
		"turn", gameState.CurrentTurn)

	// Broadcast phase change
	h.broadcastPhaseChange(ctx, gameID, phase)

	// Handle phase-specific logic
	switch phase {
	case domain.PhaseDrawIncome:
		// Execute Upkeep and then advance to Planning
		upkeepLog := domain.ExecuteUpkeepPhase(gameState)
		if err := h.gameRepo.Update(ctx, gameState); err != nil {
			return err
		}
		// Broadcast timeline for upkeep
		h.broadcastResolutionTimeline(ctx, gameID, upkeepLog)
		// Advance to Planning after brief delay
		time.AfterFunc(1*time.Second, func() {
			h.advanceToPhase(context.Background(), gameID, domain.PhasePlanning)
		})

	case domain.PhasePlanning:
		// Start 30-second timer for Planning phase
		h.startPlanningTimer(ctx, gameID)

	case domain.PhaseRevealResolve:
		// Resolve actions deterministically
		p1 := gameState.PendingActions[0]
		p2 := gameState.PendingActions[1]
		resolutionLog := domain.ExecuteResolutionPhase(gameState, p1, p2)
		// Clear pending actions after resolution
		gameState.PendingActions[0] = domain.ActionQueue{}
		gameState.PendingActions[1] = domain.ActionQueue{}
		if err := h.gameRepo.Update(ctx, gameState); err != nil {
			return err
		}
		// Broadcast timeline for resolution
		h.broadcastResolutionTimeline(ctx, gameID, resolutionLog)
		// Automatically advance to Cleanup shortly
		time.AfterFunc(500*time.Millisecond, func() {
			h.advanceToPhase(context.Background(), gameID, domain.PhaseCleanup)
		})

	case domain.PhaseCleanup:
		// Next round starts immediately after minimal delay
		time.AfterFunc(500*time.Millisecond, func() {
			gs, _ := h.gameRepo.Get(context.Background(), gameID)
			if gs != nil {
				gs.AdvanceTurn()
				h.gameRepo.Update(context.Background(), gs)
				h.broadcastTurnAdvanced(context.Background(), gameID, gs.CurrentTurn)
				h.advanceToPhase(context.Background(), gameID, domain.PhaseDrawIncome)
			}
		})
	}

	// Broadcast updated game state
	return h.broadcastGameState(ctx, gameID)
}

// startPlanningTimer starts a 30-second timer for the Planning phase.
func (h *GameHub) startPlanningTimer(ctx context.Context, gameID domain.GameID) {
	h.mu.Lock()
	// Cancel existing timer if any
	if timer, exists := h.phaseTimers[gameID]; exists {
		timer.Stop()
	}

	// Create new timer
	timer := time.AfterFunc(30*time.Second, func() {
		gameState, err := h.gameRepo.Get(context.Background(), gameID)
		if err != nil {
			return
		}

		// Only advance if still in Planning phase
		if gameState.CurrentPhase == domain.PhasePlanning {
			h.log.WithContext(context.Background()).Info("Planning phase timer expired",
				"game_id", gameID)
			h.advanceToPhase(context.Background(), gameID, domain.PhaseRevealResolve)
		}
	})

	h.phaseTimers[gameID] = timer
	h.mu.Unlock()
}

// broadcastResolutionTimeline sends the event log for the round to all clients.
func (h *GameHub) broadcastResolutionTimeline(ctx context.Context, gameID domain.GameID, log *domain.EventLog) {
	h.mu.RLock()
	gameClients, exists := h.clients[gameID]
	if !exists {
		h.mu.RUnlock()
		return
	}
	clients := make([]*GameClient, 0, len(gameClients))
	for _, client := range gameClients {
		clients = append(clients, client)
	}
	h.mu.RUnlock()

	message := map[string]interface{}{
		"type":  "resolution_timeline",
		"round": log.RoundNumber,
		"events": log.Events,
	}

	for _, client := range clients {
		if err := client.Conn.WriteJSON(message); err != nil {
			h.log.LogError(ctx, err, "Failed to send resolution timeline to client")
		}
	}
}

// cancelPhaseTimer cancels the phase timer for a game.
func (h *GameHub) cancelPhaseTimer(gameID domain.GameID) {
	h.mu.Lock()
	if timer, exists := h.phaseTimers[gameID]; exists {
		timer.Stop()
		delete(h.phaseTimers, gameID)
	}
	h.mu.Unlock()
}

// broadcastPhaseChange notifies all clients about a phase change.
func (h *GameHub) broadcastPhaseChange(ctx context.Context, gameID domain.GameID, phase domain.GamePhase) {
	h.mu.RLock()
	gameClients, exists := h.clients[gameID]
	if !exists {
		h.mu.RUnlock()
		return
	}

	clients := make([]*GameClient, 0, len(gameClients))
	for _, client := range gameClients {
		clients = append(clients, client)
	}
	h.mu.RUnlock()

	message := map[string]interface{}{
		"type":  "phase_changed",
		"phase": phase,
	}

	for _, client := range clients {
		if err := client.Conn.WriteJSON(message); err != nil {
			h.log.LogError(ctx, err, "Failed to send phase change notification")
		}
	}
}

// buildPlayerStateFromDeck expands deck entries into a shuffled draw pile and initializes state.
func buildPlayerStateFromDeck(playerIndex int, deck *domain.Deck) domain.PlayerBattleState {
	// Expand deck entries to card instances by quantity
	var drawPile []domain.CardInstance
	for _, entry := range deck.GetAllCards() {
		for i := 0; i < entry.Quantity; i++ {
			// Create a unique instance for each card
			instance := domain.NewCardInstance(entry.CardID)
			drawPile = append(drawPile, instance)
		}
	}
	// Shuffle drawPile
	for i := len(drawPile) - 1; i > 0; i-- {
		j := rand.Intn(i + 1)
		drawPile[i], drawPile[j] = drawPile[j], drawPile[i]
	}

	return domain.PlayerBattleState{
		PlayerIndex: playerIndex,
		DeckID:      deck.ID,
		Hand:        []domain.CardInstance{},
		DeckCount:   len(drawPile),
		DrawPile:    drawPile,
		DiscardPile: []domain.CardInstance{},
		Gold:        0,
		Mana:        0,
		ManaMax:     3,
		GoldIncome:  1,
		HandLimit:   7,
	}
}

// drawCardsForPlayer draws up to count cards from player's draw pile into hand.
func drawCardsForPlayer(ps *domain.PlayerBattleState, count int) {
	if count <= 0 || len(ps.DrawPile) == 0 {
		return
	}
	if count > len(ps.DrawPile) {
		count = len(ps.DrawPile)
	}
	drawn := ps.DrawPile[len(ps.DrawPile)-count:]
	ps.DrawPile = ps.DrawPile[:len(ps.DrawPile)-count]
	ps.Hand = append(ps.Hand, drawn...)
	ps.DeckCount = len(ps.DrawPile)
}