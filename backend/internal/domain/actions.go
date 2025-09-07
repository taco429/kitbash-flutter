package domain

// ActionType defines the kind of player-submitted action.
type ActionType string

const (
    // Play a card from hand (units, buildings, spells are all cards)
    ActionTypePlayCard   ActionType = "play_card"
    // Activate an ability printed on a unit/building already in play
    ActionTypeActivateAbility ActionType = "activate_ability"
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
    // Position is used for placement when playing a card or targeted tile effects
    Position     Point       `json:"position"`
    CardInHandID string      `json:"cardInHandId"`
    Params       map[string]any `json:"params,omitempty"`
}

// ActionQueue is the list of all actions a player locks in for the round.
type ActionQueue []Action

