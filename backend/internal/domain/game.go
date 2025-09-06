package domain

import (
	"time"
)

// GameID uniquely identifies a game instance.
type GameID string

// GameStatus represents the current state of a game.
type GameStatus string

const (
	GameStatusWaiting    GameStatus = "waiting"
	GameStatusInProgress GameStatus = "in_progress"
	GameStatusFinished   GameStatus = "finished"
)

// GamePhase represents the current phase within a round.
type GamePhase string

const (
	// New three-phase system
	PhaseUpkeep     GamePhase = "upkeep"      // Upkeep phase (automatic)
	PhaseDecision   GamePhase = "decision"    // Decision phase (player input)
	PhaseResolution GamePhase = "resolution"  // Resolution phase (automatic)
	
	// Legacy phases (for compatibility)
	PhaseDrawIncome   GamePhase = "draw_income"    // Draw & Income phase
	PhasePlanning     GamePhase = "planning"       // Planning phase (30s)
	PhaseRevealResolve GamePhase = "reveal_resolve" // Reveal & Resolve phase
	PhaseCleanup      GamePhase = "cleanup"        // Cleanup phase
)

// PlayerBattleState represents per-player runtime state such as deck/hand.
type PlayerBattleState struct {
    PlayerIndex int        `json:"playerIndex"`
    DeckID      DeckID     `json:"deckId"`
    // Hand contains the visible cards in the player's hand (by CardID).
    Hand        []CardID   `json:"hand"`
    // DeckCount is the remaining number of cards in the player's deck/draw pile.
    DeckCount   int        `json:"deckCount"`
    // DrawPile and DiscardPile are server-internal and not serialized to clients.
    DrawPile    []CardID   `json:"-"`
    DiscardPile []CardID   `json:"-"`
    // Resources
    Gold        int        `json:"gold"`
    MaxGold     int        `json:"maxGold"`
    GoldIncome  int        `json:"goldIncome"`
    Mana        int        `json:"mana"`
    MaxMana     int        `json:"maxMana"`
    // Hand management
    HandLimit   int        `json:"handLimit"`
    DrawPerTurn int        `json:"drawPerTurn"`
}

// CommandCenter represents a player's command center with health.
type CommandCenter struct {
	PlayerIndex int `json:"playerIndex"`
	TopLeftRow  int `json:"topLeftRow"`
	TopLeftCol  int `json:"topLeftCol"`
	Health      int `json:"health"`
	MaxHealth   int `json:"maxHealth"`
}

// NewCommandCenter creates a new command center with default health.
func NewCommandCenter(playerIndex, topLeftRow, topLeftCol int) *CommandCenter {
	return &CommandCenter{
		PlayerIndex: playerIndex,
		TopLeftRow:  topLeftRow,
		TopLeftCol:  topLeftCol,
		Health:      100,
		MaxHealth:   100,
	}
}

// TakeDamage reduces the command center's health by the specified amount.
// Returns true if the command center is destroyed (health <= 0).
func (cc *CommandCenter) TakeDamage(damage int) bool {
	cc.Health -= damage
	if cc.Health < 0 {
		cc.Health = 0
	}
	return cc.Health <= 0
}

// IsDestroyed returns true if the command center has no health remaining.
func (cc *CommandCenter) IsDestroyed() bool {
	return cc.Health <= 0
}

// GameState represents the current state of a game.
type GameState struct {
	ID                  GameID           `json:"id"`
	Status              GameStatus       `json:"status"`
	Players             []Player         `json:"players"`
	CommandCenters      []*CommandCenter `json:"commandCenters"`
	PlayerStates        []PlayerBattleState `json:"playerStates"`
	CurrentTurn         int              `json:"currentTurn"`
	CurrentPhase        GamePhase        `json:"currentPhase"`
	PhaseStartTime      time.Time        `json:"phaseStartTime"`
	TurnCount           int              `json:"turnCount"`
	BoardRows           int              `json:"boardRows"`
	BoardCols           int              `json:"boardCols"`
	BoardState          *BoardState      `json:"boardState"`
	PlayerChoicesLocked map[int]bool     `json:"playerChoicesLocked"`
	PlayerActions       map[int]*PlayerActions `json:"-"` // Server-side only, stores submitted actions
	LastEventLog        *EventLog        `json:"lastEventLog,omitempty"` // Log from last resolution
	CreatedAt           time.Time        `json:"createdAt"`
	UpdatedAt           time.Time        `json:"updatedAt"`
}

// NewGameState creates a new game state with default command centers.
func NewGameState(gameID GameID, players []Player, boardRows, boardCols int) *GameState {
	commandCenters := computeDefaultCommandCenters(boardRows, boardCols)
	
	// Initialize player states with default resources
	playerStates := make([]PlayerBattleState, len(players))
	for i := range players {
		playerStates[i] = PlayerBattleState{
			PlayerIndex: i,
			Hand:        []CardID{},
			DrawPile:    []CardID{},
			DiscardPile: []CardID{},
			Gold:        3,      // Starting gold
			MaxGold:     10,     // Max gold storage
			GoldIncome:  2,      // Gold per turn
			Mana:        0,      // Mana resets each turn
			MaxMana:     5,      // Starting max mana
			HandLimit:   7,      // Max cards in hand
			DrawPerTurn: 1,      // Cards drawn per turn
		}
	}
	
	return &GameState{
		ID:                  gameID,
		Status:              GameStatusWaiting,
		Players:             players,
		CommandCenters:      commandCenters,
		PlayerStates:        playerStates,
		CurrentTurn:         0,
		CurrentPhase:        PhaseUpkeep,
		PhaseStartTime:      time.Now(),
		TurnCount:           0,
		BoardRows:           boardRows,
		BoardCols:           boardCols,
		BoardState:          NewBoardState(boardRows, boardCols),
		PlayerChoicesLocked: map[int]bool{0: false, 1: false},
		PlayerActions:       make(map[int]*PlayerActions),
		CreatedAt:           time.Now(),
		UpdatedAt:           time.Now(),
	}
}

// computeDefaultCommandCenters creates the default command center positions.
func computeDefaultCommandCenters(rows, cols int) []*CommandCenter {
	centerCol := cols / 2
	topLeftCol := max(0, min(centerCol-2, cols-2))

	topPlayerRow := max(0, min(1, rows-2))
	bottomPlayerRow := max(0, min(rows-3, rows-2))

	return []*CommandCenter{
		NewCommandCenter(0, topPlayerRow, topLeftCol),
		NewCommandCenter(1, bottomPlayerRow, topLeftCol),
	}
}

// GetCommandCenter returns the command center for the specified player.
func (gs *GameState) GetCommandCenter(playerIndex int) *CommandCenter {
	for _, cc := range gs.CommandCenters {
		if cc.PlayerIndex == playerIndex {
			return cc
		}
	}
	return nil
}

// DealDamageToCommandCenter deals damage to a player's command center.
// Returns true if the command center is destroyed.
func (gs *GameState) DealDamageToCommandCenter(playerIndex, damage int) bool {
	cc := gs.GetCommandCenter(playerIndex)
	if cc == nil {
		return false
	}
	
	destroyed := cc.TakeDamage(damage)
	gs.UpdatedAt = time.Now()
	
	if destroyed {
		gs.Status = GameStatusFinished
	}
	
	return destroyed
}

// IsGameOver returns true if any command center is destroyed.
func (gs *GameState) IsGameOver() bool {
	for _, cc := range gs.CommandCenters {
		if cc.IsDestroyed() {
			return true
		}
	}
	return false
}

// GetWinner returns the player index of the winner, or -1 if no winner yet.
func (gs *GameState) GetWinner() int {
	for _, cc := range gs.CommandCenters {
		if cc.IsDestroyed() {
			// The other player wins
			return 1 - cc.PlayerIndex
		}
	}
	return -1
}

// StartGame transitions the game from waiting to in progress.
func (gs *GameState) StartGame() {
	if gs.Status == GameStatusWaiting {
		gs.Status = GameStatusInProgress
		gs.UpdatedAt = time.Now()
	}
}

// LockPlayerChoice marks a player's choice as locked for the current turn.
func (gs *GameState) LockPlayerChoice(playerIndex int) {
	if gs.PlayerChoicesLocked == nil {
		gs.PlayerChoicesLocked = map[int]bool{0: false, 1: false}
	}
	gs.PlayerChoicesLocked[playerIndex] = true
	gs.UpdatedAt = time.Now()
}

// AreAllPlayersLocked returns true if all players have locked their choices.
func (gs *GameState) AreAllPlayersLocked() bool {
	if gs.PlayerChoicesLocked == nil {
		return false
	}
	for _, locked := range gs.PlayerChoicesLocked {
		if !locked {
			return false
		}
	}
	return true
}

// AdvanceTurn increments the turn counter and resets player locks.
func (gs *GameState) AdvanceTurn() {
	gs.CurrentTurn++
	gs.TurnCount++
	// Reset phase to Draw & Income for new turn
	gs.CurrentPhase = PhaseDrawIncome
	gs.PhaseStartTime = time.Now()
	// Reset all player locks for the new turn
	if gs.PlayerChoicesLocked == nil {
		gs.PlayerChoicesLocked = map[int]bool{0: false, 1: false}
	} else {
		for key := range gs.PlayerChoicesLocked {
			gs.PlayerChoicesLocked[key] = false
		}
	}
	gs.UpdatedAt = time.Now()
}

// SetPhase sets the current phase of the game.
func (gs *GameState) SetPhase(phase GamePhase) {
	gs.CurrentPhase = phase
	gs.PhaseStartTime = time.Now()
	gs.UpdatedAt = time.Now()
}

// GetPhaseDuration returns how long the current phase has been active.
func (gs *GameState) GetPhaseDuration() time.Duration {
	return time.Since(gs.PhaseStartTime)
}

// ShouldAutoAdvancePhase checks if the current phase should auto-advance based on timing.
func (gs *GameState) ShouldAutoAdvancePhase() bool {
	// Only Planning phase has a timer (30 seconds)
	if gs.CurrentPhase == PhasePlanning {
		return gs.GetPhaseDuration() >= 30*time.Second
	}
	return false
}

// DiscardCards moves specified cards from a player's hand to their discard pile.
func (gs *GameState) DiscardCards(playerIndex int, cardIDs []CardID) {
	if playerIndex < 0 || playerIndex >= len(gs.PlayerStates) {
		return
	}
	
	playerState := &gs.PlayerStates[playerIndex]
	
	// Remove cards from hand and add to discard pile
	for _, cardID := range cardIDs {
		// Find and remove from hand
		for i, handCard := range playerState.Hand {
			if handCard == cardID {
				// Remove from hand
				playerState.Hand = append(playerState.Hand[:i], playerState.Hand[i+1:]...)
				// Add to discard pile
				playerState.DiscardPile = append(playerState.DiscardPile, cardID)
				break
			}
		}
	}
	
	gs.UpdatedAt = time.Now()
}

// SubmitPlayerActions stores a player's actions for the current round
func (gs *GameState) SubmitPlayerActions(playerIndex int, actions ActionQueue) {
	if gs.PlayerActions == nil {
		gs.PlayerActions = make(map[int]*PlayerActions)
	}
	
	gs.PlayerActions[playerIndex] = &PlayerActions{
		PlayerIndex: playerIndex,
		Actions:     actions,
		LockedAt:    time.Now(),
	}
	
	gs.LockPlayerChoice(playerIndex)
}

// GetPlayerActions retrieves a player's submitted actions
func (gs *GameState) GetPlayerActions(playerIndex int) *PlayerActions {
	if gs.PlayerActions == nil {
		return nil
	}
	return gs.PlayerActions[playerIndex]
}

// ClearPlayerActions clears all submitted actions (after resolution)
func (gs *GameState) ClearPlayerActions() {
	gs.PlayerActions = make(map[int]*PlayerActions)
	// Also reset player locks
	if gs.PlayerChoicesLocked == nil {
		gs.PlayerChoicesLocked = map[int]bool{0: false, 1: false}
	} else {
		for key := range gs.PlayerChoicesLocked {
			gs.PlayerChoicesLocked[key] = false
		}
	}
}

// DrawCards draws cards from a player's draw pile to their hand
func (gs *GameState) DrawCards(playerIndex int, count int) []CardID {
	if playerIndex < 0 || playerIndex >= len(gs.PlayerStates) {
		return nil
	}
	
	playerState := &gs.PlayerStates[playerIndex]
	drawnCards := []CardID{}
	
	for i := 0; i < count && len(playerState.DrawPile) > 0; i++ {
		// Draw from top of deck (end of slice)
		cardID := playerState.DrawPile[len(playerState.DrawPile)-1]
		playerState.DrawPile = playerState.DrawPile[:len(playerState.DrawPile)-1]
		playerState.Hand = append(playerState.Hand, cardID)
		playerState.DeckCount = len(playerState.DrawPile)
		drawnCards = append(drawnCards, cardID)
	}
	
	gs.UpdatedAt = time.Now()
	return drawnCards
}

// RefillHand draws cards until the player reaches their hand limit
func (gs *GameState) RefillHand(playerIndex int) []CardID {
	if playerIndex < 0 || playerIndex >= len(gs.PlayerStates) {
		return nil
	}
	
	playerState := &gs.PlayerStates[playerIndex]
	cardsToDraw := playerState.HandLimit - len(playerState.Hand)
	
	if cardsToDraw <= 0 {
		return nil
	}
	
	return gs.DrawCards(playerIndex, cardsToDraw)
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}