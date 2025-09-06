package domain

import (
	"fmt"
	"time"
)

// UnitID uniquely identifies a unit on the board
type UnitID string

// Unit represents a unit on the game board
type Unit struct {
	ID          UnitID    `json:"id"`
	CardID      CardID    `json:"cardId"`      // The card that created this unit
	PlayerIndex int       `json:"playerIndex"` // Which player controls this unit
	Position    Point     `json:"position"`    // Current position on board
	Attack      int       `json:"attack"`
	Health      int       `json:"health"`
	MaxHealth   int       `json:"maxHealth"`
	Armor       int       `json:"armor"`
	Speed       int       `json:"speed"`      // Movement points per turn
	Range       int       `json:"range"`      // Attack range
	MovesLeft   int       `json:"movesLeft"`  // Moves remaining this turn
	CanAttack   bool      `json:"canAttack"`  // Can attack this turn
	Abilities   []string  `json:"abilities"`  // List of ability keywords
	Counters    map[string]int `json:"counters"` // Turn-based counters
	IsSummoned  bool      `json:"isSummoned"` // Just summoned this turn (summoning sickness)
}

// NewUnit creates a new unit from a card's unit stats
func NewUnit(cardID CardID, playerIndex int, position Point, stats *UnitStats) *Unit {
	return &Unit{
		ID:          UnitID(fmt.Sprintf("unit_%s_%d", cardID, time.Now().UnixNano())),
		CardID:      cardID,
		PlayerIndex: playerIndex,
		Position:    position,
		Attack:      stats.Attack,
		Health:      stats.Health,
		MaxHealth:   stats.Health,
		Armor:       stats.Armor,
		Speed:       stats.Speed,
		Range:       stats.Range,
		MovesLeft:   0, // Can't move on summon turn
		CanAttack:   false, // Summoning sickness
		Abilities:   []string{},
		Counters:    make(map[string]int),
		IsSummoned:  true,
	}
}

// TakeDamage applies damage to the unit, accounting for armor
func (u *Unit) TakeDamage(damage int) bool {
	effectiveDamage := damage - u.Armor
	if effectiveDamage < 0 {
		effectiveDamage = 0
	}
	u.Health -= effectiveDamage
	if u.Health <= 0 {
		u.Health = 0
		return true // Unit is destroyed
	}
	return false
}

// Heal restores health to the unit up to its maximum
func (u *Unit) Heal(amount int) {
	u.Health += amount
	if u.Health > u.MaxHealth {
		u.Health = u.MaxHealth
	}
}

// ResetMovement resets the unit's movement for a new turn
func (u *Unit) ResetMovement() {
	u.MovesLeft = u.Speed
	u.CanAttack = true
	u.IsSummoned = false
}

// CanMoveTo checks if the unit can move to a target position
func (u *Unit) CanMoveTo(target Point) bool {
	if u.MovesLeft <= 0 {
		return false
	}
	
	// Calculate Manhattan distance
	distance := abs(target.Row-u.Position.Row) + abs(target.Col-u.Position.Col)
	return distance <= u.MovesLeft
}

// MoveTo moves the unit to a new position
func (u *Unit) MoveTo(target Point) {
	distance := abs(target.Row-u.Position.Row) + abs(target.Col-u.Position.Col)
	u.Position = target
	u.MovesLeft -= distance
	if u.MovesLeft < 0 {
		u.MovesLeft = 0
	}
}

// CanAttackTarget checks if the unit can attack a target at the given position
func (u *Unit) CanAttackTarget(targetPos Point) bool {
	if !u.CanAttack {
		return false
	}
	
	// Calculate distance (using Manhattan distance for simplicity)
	distance := abs(targetPos.Row-u.Position.Row) + abs(targetPos.Col-u.Position.Col)
	return distance <= u.Range
}

// HasAbility checks if the unit has a specific ability
func (u *Unit) HasAbility(ability string) bool {
	for _, a := range u.Abilities {
		if a == ability {
			return true
		}
	}
	return false
}

// IncrementCounter increments a named counter on the unit
func (u *Unit) IncrementCounter(name string) {
	if u.Counters == nil {
		u.Counters = make(map[string]int)
	}
	u.Counters[name]++
}

// GetCounter gets the value of a named counter
func (u *Unit) GetCounter(name string) int {
	if u.Counters == nil {
		return 0
	}
	return u.Counters[name]
}

// Building represents a building on the game board
type Building struct {
	ID          string   `json:"id"`
	CardID      CardID   `json:"cardId"`
	PlayerIndex int      `json:"playerIndex"`
	Position    Point    `json:"position"`
	Health      int      `json:"health"`
	MaxHealth   int      `json:"maxHealth"`
	Armor       int      `json:"armor"`
	Attack      *int     `json:"attack,omitempty"` // For defensive buildings
	Range       *int     `json:"range,omitempty"`  // For defensive buildings
	Abilities   []string `json:"abilities"`
	Counters    map[string]int `json:"counters"`
}

// NewBuilding creates a new building from a card's building stats
func NewBuilding(cardID CardID, playerIndex int, position Point, stats *BuildingStats) *Building {
	return &Building{
		ID:          fmt.Sprintf("building_%s_%d", cardID, time.Now().UnixNano()),
		CardID:      cardID,
		PlayerIndex: playerIndex,
		Position:    position,
		Health:      stats.Health,
		MaxHealth:   stats.Health,
		Armor:       stats.Armor,
		Attack:      stats.Attack,
		Range:       stats.Range,
		Abilities:   []string{},
		Counters:    make(map[string]int),
	}
}

// TakeDamage applies damage to the building
func (b *Building) TakeDamage(damage int) bool {
	effectiveDamage := damage - b.Armor
	if effectiveDamage < 0 {
		effectiveDamage = 0
	}
	b.Health -= effectiveDamage
	if b.Health <= 0 {
		b.Health = 0
		return true // Building is destroyed
	}
	return false
}

// BoardState represents the current state of the game board
type BoardState struct {
	Units     map[UnitID]*Unit      `json:"units"`
	Buildings map[string]*Building   `json:"buildings"`
	Grid      [][]string             `json:"grid"` // 2D grid showing what's at each position
}

// NewBoardState creates a new empty board state
func NewBoardState(rows, cols int) *BoardState {
	grid := make([][]string, rows)
	for i := range grid {
		grid[i] = make([]string, cols)
	}
	
	return &BoardState{
		Units:     make(map[UnitID]*Unit),
		Buildings: make(map[string]*Building),
		Grid:      grid,
	}
}

// AddUnit adds a unit to the board
func (bs *BoardState) AddUnit(unit *Unit) {
	bs.Units[unit.ID] = unit
	bs.UpdateGrid()
}

// RemoveUnit removes a unit from the board
func (bs *BoardState) RemoveUnit(unitID UnitID) {
	delete(bs.Units, unitID)
	bs.UpdateGrid()
}

// AddBuilding adds a building to the board
func (bs *BoardState) AddBuilding(building *Building) {
	bs.Buildings[building.ID] = building
	bs.UpdateGrid()
}

// RemoveBuilding removes a building from the board
func (bs *BoardState) RemoveBuilding(buildingID string) {
	delete(bs.Buildings, buildingID)
	bs.UpdateGrid()
}

// GetUnitAt returns the unit at the specified position, if any
func (bs *BoardState) GetUnitAt(pos Point) *Unit {
	for _, unit := range bs.Units {
		if unit.Position.Row == pos.Row && unit.Position.Col == pos.Col {
			return unit
		}
	}
	return nil
}

// GetBuildingAt returns the building at the specified position, if any
func (bs *BoardState) GetBuildingAt(pos Point) *Building {
	for _, building := range bs.Buildings {
		if building.Position.Row == pos.Row && building.Position.Col == pos.Col {
			return building
		}
	}
	return nil
}

// IsPositionOccupied checks if a position is occupied by a unit or building
func (bs *BoardState) IsPositionOccupied(pos Point) bool {
	return bs.GetUnitAt(pos) != nil || bs.GetBuildingAt(pos) != nil
}

// UpdateGrid updates the grid representation of the board
func (bs *BoardState) UpdateGrid() {
	// Clear grid
	for i := range bs.Grid {
		for j := range bs.Grid[i] {
			bs.Grid[i][j] = ""
		}
	}
	
	// Add units
	for _, unit := range bs.Units {
		if unit.Position.Row >= 0 && unit.Position.Row < len(bs.Grid) &&
		   unit.Position.Col >= 0 && unit.Position.Col < len(bs.Grid[0]) {
			bs.Grid[unit.Position.Row][unit.Position.Col] = string(unit.ID)
		}
	}
	
	// Add buildings
	for _, building := range bs.Buildings {
		if building.Position.Row >= 0 && building.Position.Row < len(bs.Grid) &&
		   building.Position.Col >= 0 && building.Position.Col < len(bs.Grid[0]) {
			bs.Grid[building.Position.Row][building.Position.Col] = building.ID
		}
	}
}

// GetPlayerUnits returns all units belonging to a player
func (bs *BoardState) GetPlayerUnits(playerIndex int) []*Unit {
	var units []*Unit
	for _, unit := range bs.Units {
		if unit.PlayerIndex == playerIndex {
			units = append(units, unit)
		}
	}
	return units
}

// GetPlayerBuildings returns all buildings belonging to a player
func (bs *BoardState) GetPlayerBuildings(playerIndex int) []*Building {
	var buildings []*Building
	for _, building := range bs.Buildings {
		if building.PlayerIndex == playerIndex {
			buildings = append(buildings, building)
		}
	}
	return buildings
}

// Helper function for absolute value
func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}