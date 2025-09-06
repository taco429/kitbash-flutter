package domain

// ActionType defines the kind of action (e.g., PlayCard, MoveUnit, CastSpell).
type ActionType string

const (
    ActionTypePlayCard   ActionType = "play_card"
    ActionTypeCastSpell  ActionType = "cast_spell"
    ActionTypeMoveUnit   ActionType = "move_unit"
    ActionTypeAttack     ActionType = "attack"
    ActionTypeDealDamage ActionType = "deal_damage_cc" // direct damage to a command center
)

// ActionSpeed categorizes timing for resolution windows.
type ActionSpeed string

const (
    ActionSpeedFast   ActionSpeed = "fast"
    ActionSpeedNormal ActionSpeed = "normal"
    ActionSpeedSlow   ActionSpeed = "slow"
)

// Point represents a board coordinate.
type Point struct {
    Row int `json:"row"`
    Col int `json:"col"`
}

// Action represents a single decision made by a player for the round.
type Action struct {
    // Who submitted the action
    PlayerIndex  int         `json:"playerIndex"`
    // Classification
    Type         ActionType  `json:"type"`
    Speed        ActionSpeed `json:"speed"`
    // Entities and parameters
    SourceID     string      `json:"sourceId"`
    TargetID     string      `json:"targetId"`
    Position     Point       `json:"position"`
    CardInHandID string      `json:"cardInHandId"`
    Params       map[string]any `json:"params,omitempty"`
}

// ActionQueue is the list of all actions a player locks in for the round.
type ActionQueue []Action

