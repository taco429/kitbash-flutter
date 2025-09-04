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
	TurnCount           int              `json:"turnCount"`
	BoardRows           int              `json:"boardRows"`
	BoardCols           int              `json:"boardCols"`
	PlayerChoicesLocked map[int]bool     `json:"playerChoicesLocked"`
	CreatedAt           time.Time        `json:"createdAt"`
	UpdatedAt           time.Time        `json:"updatedAt"`
}

// NewGameState creates a new game state with default command centers.
func NewGameState(gameID GameID, players []Player, boardRows, boardCols int) *GameState {
	commandCenters := computeDefaultCommandCenters(boardRows, boardCols)
	
	return &GameState{
		ID:                  gameID,
		Status:              GameStatusWaiting,
		Players:             players,
		CommandCenters:      commandCenters,
		PlayerStates:        []PlayerBattleState{},
		CurrentTurn:         0,
		TurnCount:           0,
		BoardRows:           boardRows,
		BoardCols:           boardCols,
		PlayerChoicesLocked: map[int]bool{0: false, 1: false},
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