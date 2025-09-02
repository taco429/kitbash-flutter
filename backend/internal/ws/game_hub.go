package ws

import (
	"context"
	"encoding/json"
	"net/http"
	"sync"

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
	clients    map[domain.GameID]map[*websocket.Conn]*GameClient
	upgrader   websocket.Upgrader
	log        *logger.Logger
	cfg        config.Config
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
	}
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

	// Start the game immediately for testing
	gameState.StartGame()
	if err := h.gameRepo.Update(ctx, gameState); err != nil {
		h.log.LogError(ctx, err, "Failed to update game state after starting")
	}

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