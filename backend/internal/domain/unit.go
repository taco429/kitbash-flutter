package domain

import (
	"fmt"
	"time"
)

// Direction represents the direction a unit is facing/moving
type Direction string

const (
	DirectionNorth     Direction = "north"
	DirectionNorthEast Direction = "northeast"
	DirectionEast      Direction = "east"
	DirectionSouthEast Direction = "southeast"
	DirectionSouth     Direction = "south"
	DirectionSouthWest Direction = "southwest"
	DirectionWest      Direction = "west"
	DirectionNorthWest Direction = "northwest"
)

// UnitID uniquely identifies a unit on the board
type UnitID string

// Unit represents a unit on the game board
type Unit struct {
	ID          UnitID    `json:"id"`
	CardID      CardID    `json:"cardId"`       // The card that created this unit
	PlayerIndex int       `json:"playerIndex"`  // Owner of the unit
	Position    Point     `json:"position"`     // Current position on the board
	Direction   Direction `json:"direction"`    // Direction the unit is facing/moving
	
	// Stats
	Attack      int       `json:"attack"`
	Health      int       `json:"health"`
	MaxHealth   int       `json:"maxHealth"`
	Armor       int       `json:"armor"`
	Speed       int       `json:"speed"`
	Range       int       `json:"range"`
	
	// State flags
	HasMoved    bool      `json:"hasMoved"`     // Whether unit has moved this turn
	HasAttacked bool      `json:"hasAttacked"`  // Whether unit has attacked this turn
	IsAlive     bool      `json:"isAlive"`      // Whether unit is still alive
	TurnSpawned int       `json:"turnSpawned"`  // Turn number when unit was spawned
	
	// Movement target (for pathfinding)
	TargetPosition *Point   `json:"targetPosition,omitempty"` // Where the unit is trying to go
	
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// NewUnit creates a new unit from card stats
func NewUnit(cardID CardID, playerIndex int, position Point, stats *UnitStats, turnNumber int) *Unit {
	unitID := UnitID(fmt.Sprintf("unit_%d_%d_%d_%d", playerIndex, position.Row, position.Col, time.Now().UnixNano()))
	
	// Determine initial direction based on player
	// Player 0 starts facing north (towards opponent)
	// Player 1 starts facing south (towards opponent)
	direction := DirectionNorth
	if playerIndex == 1 {
		direction = DirectionSouth
	}
	
	return &Unit{
		ID:          unitID,
		CardID:      cardID,
		PlayerIndex: playerIndex,
		Position:    position,
		Direction:   direction,
		Attack:      stats.Attack,
		Health:      stats.Health,
		MaxHealth:   stats.Health,
		Armor:       stats.Armor,
		Speed:       stats.Speed,
		Range:       stats.Range,
		HasMoved:    false,
		HasAttacked: false,
		IsAlive:     true,
		TurnSpawned: turnNumber,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}
}

// TakeDamage applies damage to the unit, accounting for armor
func (u *Unit) TakeDamage(damage int) {
	if !u.IsAlive {
		return
	}
	
	// Apply armor reduction
	actualDamage := damage - u.Armor
	if actualDamage < 0 {
		actualDamage = 0
	}
	
	u.Health -= actualDamage
	if u.Health <= 0 {
		u.Health = 0
		u.IsAlive = false
	}
	u.UpdatedAt = time.Now()
}

// CanAttack checks if the unit can attack a target at the given position
func (u *Unit) CanAttack(targetPos Point) bool {
	if !u.IsAlive || u.HasAttacked {
		return false
	}
	
	// Calculate distance (Manhattan distance for now)
	distance := abs(targetPos.Row-u.Position.Row) + abs(targetPos.Col-u.Position.Col)
	return distance <= u.Range
}

// GetNextPosition calculates the next position for the unit based on its movement
func (u *Unit) GetNextPosition(boardRows, boardCols int, occupiedTiles map[Point]bool, enemyCommandCenter Point) Point {
	if !u.IsAlive || u.HasMoved || u.Speed <= 0 {
		return u.Position
	}
	
	// If we have a specific target, move towards it
	targetPos := enemyCommandCenter
	if u.TargetPosition != nil {
		targetPos = *u.TargetPosition
	}
	
	// Simple pathfinding: move towards target
	// For now, prefer moving vertically first, then horizontally
	nextPos := u.Position
	
	for step := 0; step < u.Speed; step++ {
		candidatePos := nextPos
		
		// Calculate direction to target
		deltaRow := targetPos.Row - candidatePos.Row
		deltaCol := targetPos.Col - candidatePos.Col
		
		// Determine next step
		moved := false
		
		// Try to move vertically first
		if deltaRow != 0 {
			if deltaRow > 0 {
				candidatePos.Row++
				u.Direction = DirectionNorth
			} else {
				candidatePos.Row--
				u.Direction = DirectionSouth
			}
			
			// Check if position is valid and not occupied
			if candidatePos.Row >= 0 && candidatePos.Row < boardRows &&
				candidatePos.Col >= 0 && candidatePos.Col < boardCols &&
				!occupiedTiles[candidatePos] {
				nextPos = candidatePos
				moved = true
			} else {
				candidatePos = nextPos // Reset if blocked
			}
		}
		
		// If couldn't move vertically, try horizontally
		if !moved && deltaCol != 0 {
			if deltaCol > 0 {
				candidatePos.Col++
				u.Direction = DirectionEast
			} else {
				candidatePos.Col--
				u.Direction = DirectionWest
			}
			
			// Check if position is valid and not occupied
			if candidatePos.Row >= 0 && candidatePos.Row < boardRows &&
				candidatePos.Col >= 0 && candidatePos.Col < boardCols &&
				!occupiedTiles[candidatePos] {
				nextPos = candidatePos
				moved = true
			} else {
				candidatePos = nextPos // Reset if blocked
			}
		}
		
		// Update direction for diagonal movement
		if deltaRow != 0 && deltaCol != 0 {
			if deltaRow > 0 && deltaCol > 0 {
				u.Direction = DirectionNorthEast
			} else if deltaRow > 0 && deltaCol < 0 {
				u.Direction = DirectionNorthWest
			} else if deltaRow < 0 && deltaCol > 0 {
				u.Direction = DirectionSouthEast
			} else if deltaRow < 0 && deltaCol < 0 {
				u.Direction = DirectionSouthWest
			}
		}
		
		// If we couldn't move at all, stop trying
		if !moved {
			break
		}
	}
	
	return nextPos
}

// Move updates the unit's position
func (u *Unit) Move(newPosition Point) {
	if !u.IsAlive {
		return
	}
	
	u.Position = newPosition
	u.HasMoved = true
	u.UpdatedAt = time.Now()
}

// PerformAttack marks that the unit has performed an attack
func (u *Unit) PerformAttack() {
	if !u.IsAlive {
		return
	}
	
	u.HasAttacked = true
	u.UpdatedAt = time.Now()
}

// ResetTurnState resets the unit's per-turn state flags
func (u *Unit) ResetTurnState() {
	u.HasMoved = false
	u.HasAttacked = false
	u.UpdatedAt = time.Now()
}

// IsAt checks if the unit is at the given position
func (u *Unit) IsAt(position Point) bool {
	return u.Position.Row == position.Row && u.Position.Col == position.Col
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}