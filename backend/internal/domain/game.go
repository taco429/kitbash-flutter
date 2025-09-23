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
	PhaseDrawIncome   GamePhase = "draw_income"    // Draw & Income phase
	PhasePlanning     GamePhase = "planning"       // Planning phase (30s)
	PhaseRevealResolve GamePhase = "reveal_resolve" // Reveal & Resolve phase
	PhaseCleanup      GamePhase = "cleanup"        // Cleanup phase
)

// PlannedPlay represents a staged intention to play a card at a specific tile
// during the current Planning phase. The card remains in hand until resolution.
type PlannedPlay struct {
    PlayerIndex   int             `json:"playerIndex"`
    CardInstance  CardInstanceID  `json:"cardInstanceId"`
    CardID        CardID          `json:"cardId"`
    Position      Point           `json:"position"`
}

// PlayerBattleState represents per-player runtime state such as deck/hand.
type PlayerBattleState struct {
	PlayerIndex int        `json:"playerIndex"`
	DeckID      DeckID     `json:"deckId"`
	// Hand contains the visible cards in the player's hand (as CardInstances).
	Hand        []CardInstance   `json:"hand"`
	// DeckCount is the remaining number of cards in the player's deck/draw pile.
	DeckCount   int        `json:"deckCount"`
	// DrawPile and DiscardPile - now exposed to clients for viewing
	DrawPile    []CardInstance   `json:"drawPile"`
	DiscardPile []CardInstance   `json:"discardPile"`
	// Resources - Gold accumulates, Mana is ephemeral (resets each turn)
	Resources   Resources  `json:"resources"`
	// Resource income per turn (from buildings)
	ResourceIncome ResourceGeneration `json:"resourceIncome"`
	// Limits
	HandLimit   int        `json:"handLimit"`
	// Queues - using instance IDs for discards
	PendingDiscards []CardInstanceID   `json:"-"`
}

// CommandCenter represents a player's command center with health and building functionality.
type CommandCenter struct {
	PlayerIndex int                `json:"playerIndex"`
	TopLeftRow  int                `json:"topLeftRow"`
	TopLeftCol  int                `json:"topLeftCol"`
	Health      int                `json:"health"`
	MaxHealth   int                `json:"maxHealth"`
	Building    *Building          `json:"building"`
}

// NewCommandCenter creates a new command center with default health and building.
func NewCommandCenter(playerIndex, topLeftRow, topLeftCol int) *CommandCenter {
	return &CommandCenter{
		PlayerIndex: playerIndex,
		TopLeftRow:  topLeftRow,
		TopLeftCol:  topLeftCol,
		Health:      100,
		MaxHealth:   100,
		Building:    NewBuilding(BuildingCommandCenter, playerIndex, topLeftRow, topLeftCol),
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
	PlayerChoicesLocked map[int]bool     `json:"playerChoicesLocked"`
	PendingActions      map[int]ActionQueue `json:"-"`
    // PlannedPlays are the staged plays during Planning phase, exposed to clients
    PlannedPlays        map[int][]PlannedPlay `json:"plannedPlays"`
	// Units on the board
	Units               []*Unit          `json:"units"`
	// Track refunds that need to be processed
	PendingRefunds      map[int][]Resources `json:"-"`
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
		CurrentPhase:        PhaseDrawIncome,
		PhaseStartTime:      time.Now(),
		TurnCount:           0,
		BoardRows:           boardRows,
		BoardCols:           boardCols,
		PlayerChoicesLocked: map[int]bool{0: false, 1: false},
		PendingActions:      map[int]ActionQueue{0: {}, 1: {}},
        PlannedPlays:        map[int][]PlannedPlay{0: []PlannedPlay{}, 1: []PlannedPlay{}},
		Units:               []*Unit{},
		PendingRefunds:      map[int][]Resources{0: {}, 1: {}},
		CreatedAt:           time.Now(),
		UpdatedAt:           time.Now(),
	}
}

// computeDefaultCommandCenters creates the default command center positions.
func computeDefaultCommandCenters(rows, cols int) []*CommandCenter {
    // Desired bottom-center (southern) tile positions for a 2x2 footprint:
    // Player 0 (top side):    (row=11, col=6)
    // Player 1 (bottom side): (row=1,  col=6)
    // Given a 2x2 footprint, the bottom-center anchor is at (topLeftRow+1, topLeftCol+0.5).
    // So we compute top-left as (row-1, col-1) and clamp into the board.

    // Helper to clamp top-left from a requested bottom-center
    clampTopLeft := func(bottomRow, bottomCol int) (int, int) {
        tlr := bottomRow - 1
        tlc := bottomCol - 1
        // Ensure the 2x2 fits inside the board
        if tlr < 0 {
            tlr = 0
        }
        if tlc < 0 {
            tlc = 0
        }
        if tlr > rows-2 {
            tlr = rows - 2
        }
        if tlc > cols-2 {
            tlc = cols - 2
        }
        return tlr, tlc
    }

    // Target anchors
    p0BottomRow, p0BottomCol := 11, 6
    p1BottomRow, p1BottomCol := 1, 6

    p0TLR, p0TLC := clampTopLeft(p0BottomRow, p0BottomCol)
    p1TLR, p1TLC := clampTopLeft(p1BottomRow, p1BottomCol)

    return []*CommandCenter{
        NewCommandCenter(0, p0TLR, p0TLC),
        NewCommandCenter(1, p1TLR, p1TLC),
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

// IsPlayerLocked returns true if a specific player has locked their choice.
func (gs *GameState) IsPlayerLocked(playerIndex int) bool {
	if gs.PlayerChoicesLocked == nil {
		return false
	}
	return gs.PlayerChoicesLocked[playerIndex]
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
	// Clear pending actions for new turn
	if gs.PendingActions == nil {
		gs.PendingActions = map[int]ActionQueue{0: {}, 1: {}}
	} else {
		gs.PendingActions[0] = ActionQueue{}
		gs.PendingActions[1] = ActionQueue{}
	}
    // Clear planned plays
    if gs.PlannedPlays == nil {
        gs.PlannedPlays = map[int][]PlannedPlay{0: {}, 1: {}}
    } else {
        gs.PlannedPlays[0] = []PlannedPlay{}
        gs.PlannedPlays[1] = []PlannedPlay{}
    }
	
	// Process building upgrades first, then resource generation
	// This ensures upgraded buildings generate their new resource amounts
	gs.ProcessBuildingUpgrades()
	gs.ProcessResourceGeneration()
	
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
func (gs *GameState) DiscardCards(playerIndex int, instanceIDs []CardInstanceID) {
	if playerIndex < 0 || playerIndex >= len(gs.PlayerStates) {
		return
	}
	
	playerState := &gs.PlayerStates[playerIndex]
	
	// Remove cards from hand and add to discard pile
	for _, instanceID := range instanceIDs {
		// Find and remove from hand
		for i, handCard := range playerState.Hand {
			if handCard.InstanceID == instanceID {
				// Remove from hand
				playerState.Hand = append(playerState.Hand[:i], playerState.Hand[i+1:]...)
				// Add to discard pile
				playerState.DiscardPile = append(playerState.DiscardPile, handCard)
				break
			}
		}
	}
	
	gs.UpdatedAt = time.Now()
}

// IsTileOccupied returns true if the given tile currently contains a structure
// or unit that occupies the space.
func (gs *GameState) IsTileOccupied(row, col int) bool {
    // Check command centers
    for _, cc := range gs.CommandCenters {
        if row >= cc.TopLeftRow && row < cc.TopLeftRow+2 &&
            col >= cc.TopLeftCol && col < cc.TopLeftCol+2 {
            return true
        }
    }
    
    // Check units
    for _, unit := range gs.Units {
        if unit.IsAlive && unit.Position.Row == row && unit.Position.Col == col {
            return true
        }
    }
    
    // Also treat any existing planned play position as occupied to avoid conflicts
    if gs.PlannedPlays != nil {
        for _, plays := range gs.PlannedPlays {
            for _, p := range plays {
                if p.Position.Row == row && p.Position.Col == col {
                    return true
                }
            }
        }
    }
    return false
}

// AddPlannedPlay stages a planned play for a player, replacing any existing
// plan for the same card instance.
func (gs *GameState) AddPlannedPlay(play PlannedPlay) {
    if gs.PlannedPlays == nil {
        gs.PlannedPlays = map[int][]PlannedPlay{0: {}, 1: {}}
    }
    // Remove any existing plan with the same instance id for that player
    existing := gs.PlannedPlays[play.PlayerIndex]
    filtered := make([]PlannedPlay, 0, len(existing))
    for _, p := range existing {
        if p.CardInstance != play.CardInstance {
            filtered = append(filtered, p)
        }
    }
    filtered = append(filtered, play)
    gs.PlannedPlays[play.PlayerIndex] = filtered
    gs.UpdatedAt = time.Now()
}

// RemovePlannedPlay removes a specific planned play for a player by card instance ID.
func (gs *GameState) RemovePlannedPlay(playerIndex int, cardInstanceID CardInstanceID) {
    if gs.PlannedPlays == nil {
        return
    }
    existing := gs.PlannedPlays[playerIndex]
    filtered := make([]PlannedPlay, 0, len(existing))
    for _, p := range existing {
        if p.CardInstance != cardInstanceID {
            filtered = append(filtered, p)
        }
    }
    gs.PlannedPlays[playerIndex] = filtered
    gs.UpdatedAt = time.Now()
}

// ClearPlayerPlannedPlays removes all planned plays for a specific player.
func (gs *GameState) ClearPlayerPlannedPlays(playerIndex int) {
    if gs.PlannedPlays == nil {
        gs.PlannedPlays = map[int][]PlannedPlay{0: {}, 1: {}}
    }
    gs.PlannedPlays[playerIndex] = []PlannedPlay{}
    gs.UpdatedAt = time.Now()
}

// ClearPlannedPlays removes all planned plays for both players.
func (gs *GameState) ClearPlannedPlays() {
    if gs.PlannedPlays == nil {
        gs.PlannedPlays = map[int][]PlannedPlay{0: {}, 1: {}}
        return
    }
    gs.PlannedPlays[0] = []PlannedPlay{}
    gs.PlannedPlays[1] = []PlannedPlay{}
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

// ProcessResourceGeneration generates resources for all players based on their buildings
func (gs *GameState) ProcessResourceGeneration() {
	// Process each player's resource generation
	for i := range gs.PlayerStates {
		if i >= len(gs.PlayerStates) {
			continue
		}
		
		playerState := &gs.PlayerStates[i]
		
		// Reset mana to 0 (ephemeral resource)
		playerState.Resources.Mana = 0
		
		// Calculate total resource income from all buildings
		totalIncome := ResourceGeneration{Gold: 0, Mana: 0}
		
		// Get resources from command center
		cc := gs.GetCommandCenter(i)
		if cc != nil && cc.Building != nil {
			income := cc.Building.GetResourceGeneration()
			totalIncome.Gold += income.Gold
			totalIncome.Mana += income.Mana
		}
		
		// Update player's resource income (for display)
		playerState.ResourceIncome = totalIncome
		
		// Add gold (accumulates)
		playerState.Resources.Gold += totalIncome.Gold
		
		// Set mana (ephemeral, doesn't accumulate)
		playerState.Resources.Mana = totalIncome.Mana
	}
}

// ProcessBuildingUpgrades checks and processes automatic building upgrades
func (gs *GameState) ProcessBuildingUpgrades() {
	// Process command center upgrades
	for _, cc := range gs.CommandCenters {
		if cc.Building != nil {
			// Check if it should upgrade before incrementing
			if cc.Building.ShouldUpgrade() {
				cc.Building.Upgrade()
			} else {
				// Only increment if not upgrading (upgrade resets the counter)
				cc.Building.IncrementTurnCounter()
			}
		}
	}
}

// GetPlayerResources returns the resources for a specific player
func (gs *GameState) GetPlayerResources(playerIndex int) Resources {
	if playerIndex < 0 || playerIndex >= len(gs.PlayerStates) {
		return Resources{Gold: 0, Mana: 0}
	}
	return gs.PlayerStates[playerIndex].Resources
}

// SpendResources attempts to spend resources for a player
func (gs *GameState) SpendResources(playerIndex int, cost Resources) bool {
	if playerIndex < 0 || playerIndex >= len(gs.PlayerStates) {
		return false
	}
	
	playerState := &gs.PlayerStates[playerIndex]
	
	// Check if player has enough resources
	if playerState.Resources.Gold < cost.Gold || playerState.Resources.Mana < cost.Mana {
		return false
	}
	
	// Deduct resources
	playerState.Resources.Gold -= cost.Gold
	playerState.Resources.Mana -= cost.Mana
	
	gs.UpdatedAt = time.Now()
	return true
}

// RefundResources gives resources back to a player
func (gs *GameState) RefundResources(playerIndex int, amount Resources) {
	if playerIndex < 0 || playerIndex >= len(gs.PlayerStates) {
		return
	}
	
	playerState := &gs.PlayerStates[playerIndex]
	playerState.Resources.Gold += amount.Gold
	playerState.Resources.Mana += amount.Mana
	
	gs.UpdatedAt = time.Now()
}

// AddPendingRefund adds a refund to be processed later
func (gs *GameState) AddPendingRefund(playerIndex int, amount Resources) {
	if gs.PendingRefunds == nil {
		gs.PendingRefunds = map[int][]Resources{0: {}, 1: {}}
	}
	gs.PendingRefunds[playerIndex] = append(gs.PendingRefunds[playerIndex], amount)
}

// ProcessPendingRefunds applies all pending refunds
func (gs *GameState) ProcessPendingRefunds() {
	if gs.PendingRefunds == nil {
		return
	}
	
	for playerIndex, refunds := range gs.PendingRefunds {
		for _, refund := range refunds {
			gs.RefundResources(playerIndex, refund)
		}
	}
	
	// Clear pending refunds
	gs.PendingRefunds = map[int][]Resources{0: {}, 1: {}}
}

// SpawnUnit creates a new unit on the board from a card
func (gs *GameState) SpawnUnit(cardID CardID, playerIndex int, position Point, stats *UnitStats) *Unit {
	unit := NewUnit(cardID, playerIndex, position, stats, gs.TurnCount)
	gs.Units = append(gs.Units, unit)
	gs.UpdatedAt = time.Now()
	return unit
}

// GetUnitAt returns the unit at the given position, or nil if none
func (gs *GameState) GetUnitAt(position Point) *Unit {
	for _, unit := range gs.Units {
		if unit.IsAlive && unit.IsAt(position) {
			return unit
		}
	}
	return nil
}

// GetUnitsForPlayer returns all alive units belonging to a player
func (gs *GameState) GetUnitsForPlayer(playerIndex int) []*Unit {
	var units []*Unit
	for _, unit := range gs.Units {
		if unit.IsAlive && unit.PlayerIndex == playerIndex {
			units = append(units, unit)
		}
	}
	return units
}

// GetEnemyUnits returns all alive enemy units for a given player
func (gs *GameState) GetEnemyUnits(playerIndex int) []*Unit {
	var units []*Unit
	for _, unit := range gs.Units {
		if unit.IsAlive && unit.PlayerIndex != playerIndex {
			units = append(units, unit)
		}
	}
	return units
}

// RemoveDeadUnits removes all dead units from the board
func (gs *GameState) RemoveDeadUnits() {
	aliveUnits := make([]*Unit, 0, len(gs.Units))
	for _, unit := range gs.Units {
		if unit.IsAlive {
			aliveUnits = append(aliveUnits, unit)
		}
	}
	gs.Units = aliveUnits
	gs.UpdatedAt = time.Now()
}

// GetEnemyCommandCenterPosition returns the position of the enemy command center
func (gs *GameState) GetEnemyCommandCenterPosition(playerIndex int) Point {
	enemyIndex := 1 - playerIndex // Toggle between 0 and 1
	cc := gs.GetCommandCenter(enemyIndex)
	if cc != nil {
		// Return center of 2x2 command center
		return Point{
			Row: cc.TopLeftRow + 1,
			Col: cc.TopLeftCol + 1,
		}
	}
	// Fallback position
	if playerIndex == 0 {
		return Point{Row: gs.BoardRows - 1, Col: gs.BoardCols / 2}
	}
	return Point{Row: 0, Col: gs.BoardCols / 2}
}