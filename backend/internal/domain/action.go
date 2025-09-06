package domain

import (
	"time"
)

// ActionType defines the kind of action a player can take
type ActionType string

const (
	ActionTypePlayCard    ActionType = "play_card"
	ActionTypeMoveUnit    ActionType = "move_unit"
	ActionTypeAttack      ActionType = "attack"
	ActionTypeAbility     ActionType = "ability"
	ActionTypeEndTurn     ActionType = "end_turn"
)

// SpeedType defines the speed of an action (Fast, Normal, Slow)
type SpeedType string

const (
	SpeedFast   SpeedType = "fast"
	SpeedNormal SpeedType = "normal"
	SpeedSlow   SpeedType = "slow"
)

// Point represents a position on the game board
type Point struct {
	Row int `json:"row"`
	Col int `json:"col"`
}

// Action represents a single decision made by a player
type Action struct {
	Type         ActionType            `json:"type"`
	SourceID     string                `json:"sourceId"`     // ID of the card or unit performing the action
	TargetID     string                `json:"targetId"`     // ID of the target, if any
	Position     *Point                `json:"position"`     // For movement or placement
	CardInHandID CardID                `json:"cardInHandId"` // ID for the card being played from hand
	Speed        SpeedType             `json:"speed"`        // Speed of the action
	PlayerIndex  int                   `json:"playerIndex"`  // Which player submitted this action
	Metadata     map[string]interface{} `json:"metadata"`     // Additional action-specific data
}

// ActionQueue is the list of all actions a player locks in for the round
type ActionQueue []Action

// PlayerActions represents all actions submitted by a player for a round
type PlayerActions struct {
	PlayerIndex int         `json:"playerIndex"`
	Actions     ActionQueue `json:"actions"`
	LockedAt    time.Time   `json:"lockedAt"`
}

// GetActionsBySpeed filters actions by their speed type
func (aq ActionQueue) GetActionsBySpeed(speed SpeedType) ActionQueue {
	var filtered ActionQueue
	for _, action := range aq {
		if action.Speed == speed {
			filtered = append(filtered, action)
		}
	}
	return filtered
}

// GetMovementActions returns only movement actions
func (aq ActionQueue) GetMovementActions() ActionQueue {
	var filtered ActionQueue
	for _, action := range aq {
		if action.Type == ActionTypeMoveUnit {
			filtered = append(filtered, action)
		}
	}
	return filtered
}

// GetAttackActions returns only attack actions
func (aq ActionQueue) GetAttackActions() ActionQueue {
	var filtered ActionQueue
	for _, action := range aq {
		if action.Type == ActionTypeAttack {
			filtered = append(filtered, action)
		}
	}
	return filtered
}

// GetCardPlayActions returns only card play actions
func (aq ActionQueue) GetCardPlayActions() ActionQueue {
	var filtered ActionQueue
	for _, action := range aq {
		if action.Type == ActionTypePlayCard {
			filtered = append(filtered, action)
		}
	}
	return filtered
}

// DetermineActionSpeed determines the speed of an action based on its type and context
func DetermineActionSpeed(action Action, card *Card) SpeedType {
	// If speed is already set, use it
	if action.Speed != "" {
		return action.Speed
	}

	// Determine speed based on action type and card properties
	switch action.Type {
	case ActionTypePlayCard:
		if card != nil {
			// Check if card has speed-related abilities
			for _, ability := range card.Abilities {
				if ability == "fast" || ability == "quickcast" {
					return SpeedFast
				}
				if ability == "slow" {
					return SpeedSlow
				}
			}
			// Default speeds by card type
			switch card.Type {
			case CardTypeSpell:
				// Most spells are normal speed unless specified
				return SpeedNormal
			case CardTypeUnit:
				// Units are typically normal speed
				return SpeedNormal
			case CardTypeBuilding:
				// Buildings are slow to construct
				return SpeedSlow
			default:
				return SpeedNormal
			}
		}
	case ActionTypeMoveUnit:
		// Movement happens in its own step, but we'll tag it as normal
		return SpeedNormal
	case ActionTypeAttack:
		// Attacks happen in combat step, but we'll tag as normal
		return SpeedNormal
	case ActionTypeAbility:
		// Abilities can vary, default to normal
		return SpeedNormal
	}

	return SpeedNormal
}