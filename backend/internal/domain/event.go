package domain

import (
	"time"
)

// EventType defines the type of game event
type EventType string

const (
	// Phase events
	EventPhaseStart    EventType = "phase_start"
	EventPhaseEnd      EventType = "phase_end"
	EventRoundStart    EventType = "round_start"
	EventRoundEnd      EventType = "round_end"
	
	// Resource events
	EventResourceGain  EventType = "resource_gain"
	EventResourceSpend EventType = "resource_spend"
	EventManaReset     EventType = "mana_reset"
	
	// Card events
	EventCardDrawn     EventType = "card_drawn"
	EventCardPlayed    EventType = "card_played"
	EventCardDiscarded EventType = "card_discarded"
	EventHandRefilled  EventType = "hand_refilled"
	
	// Unit events
	EventUnitSpawned   EventType = "unit_spawned"
	EventUnitMoved     EventType = "unit_moved"
	EventUnitAttacked  EventType = "unit_attacked"
	EventUnitDamaged   EventType = "unit_damaged"
	EventUnitDestroyed EventType = "unit_destroyed"
	EventUnitAbility   EventType = "unit_ability"
	
	// Combat events
	EventCombatStart   EventType = "combat_start"
	EventCombatDamage  EventType = "combat_damage"
	EventCombatEnd     EventType = "combat_end"
	
	// Building events
	EventBuildingPlaced    EventType = "building_placed"
	EventBuildingDamaged   EventType = "building_damaged"
	EventBuildingDestroyed EventType = "building_destroyed"
	
	// Command Center events
	EventCommandCenterDamaged EventType = "command_center_damaged"
	EventCommandCenterDestroyed EventType = "command_center_destroyed"
	
	// Trigger events
	EventTriggerActivated EventType = "trigger_activated"
	EventCounterUpdated   EventType = "counter_updated"
	
	// Game state events
	EventGameWon      EventType = "game_won"
	EventGameDraw     EventType = "game_draw"
	EventPlayerLocked EventType = "player_locked"
	EventTimerExpired EventType = "timer_expired"
	
	// Movement collision
	EventMovementCancelled EventType = "movement_cancelled"
)

// GameEvent represents a discrete event that occurred during game processing
type GameEvent struct {
	ID          string                 `json:"id"`
	Type        EventType              `json:"type"`
	Timestamp   time.Time              `json:"timestamp"`
	PlayerIndex *int                   `json:"playerIndex,omitempty"` // Which player triggered/owns this event
	SourceID    string                 `json:"sourceId,omitempty"`    // ID of the source (unit, card, etc.)
	TargetID    string                 `json:"targetId,omitempty"`    // ID of the target
	Position    *Point                 `json:"position,omitempty"`    // Position on board if relevant
	OldPosition *Point                 `json:"oldPosition,omitempty"` // Previous position for movement
	Value       int                    `json:"value,omitempty"`       // Numeric value (damage, resources, etc.)
	CardID      CardID                 `json:"cardId,omitempty"`      // Card involved in the event
	Message     string                 `json:"message"`               // Human-readable description
	Metadata    map[string]interface{} `json:"metadata,omitempty"`    // Additional event-specific data
}

// EventLog is a chronological list of all events that occurred
type EventLog struct {
	Events []GameEvent `json:"events"`
}

// NewEventLog creates a new empty event log
func NewEventLog() *EventLog {
	return &EventLog{
		Events: []GameEvent{},
	}
}

// AddEvent adds a new event to the log
func (el *EventLog) AddEvent(event GameEvent) {
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}
	el.Events = append(el.Events, event)
}

// AddPhaseStartEvent logs the start of a phase
func (el *EventLog) AddPhaseStartEvent(phase GamePhase) {
	el.AddEvent(GameEvent{
		Type:    EventPhaseStart,
		Message: "Phase " + string(phase) + " started",
		Metadata: map[string]interface{}{
			"phase": phase,
		},
	})
}

// AddPhaseEndEvent logs the end of a phase
func (el *EventLog) AddPhaseEndEvent(phase GamePhase) {
	el.AddEvent(GameEvent{
		Type:    EventPhaseEnd,
		Message: "Phase " + string(phase) + " ended",
		Metadata: map[string]interface{}{
			"phase": phase,
		},
	})
}

// AddResourceGainEvent logs resource gain
func (el *EventLog) AddResourceGainEvent(playerIndex int, resourceType string, amount int) {
	el.AddEvent(GameEvent{
		Type:        EventResourceGain,
		PlayerIndex: &playerIndex,
		Value:       amount,
		Message:     "Player gained " + string(amount) + " " + resourceType,
		Metadata: map[string]interface{}{
			"resourceType": resourceType,
			"amount":       amount,
		},
	})
}

// AddCardDrawnEvent logs a card being drawn
func (el *EventLog) AddCardDrawnEvent(playerIndex int, cardID CardID) {
	el.AddEvent(GameEvent{
		Type:        EventCardDrawn,
		PlayerIndex: &playerIndex,
		CardID:      cardID,
		Message:     "Player drew a card",
	})
}

// AddCardPlayedEvent logs a card being played
func (el *EventLog) AddCardPlayedEvent(playerIndex int, cardID CardID, position *Point) {
	el.AddEvent(GameEvent{
		Type:        EventCardPlayed,
		PlayerIndex: &playerIndex,
		CardID:      cardID,
		Position:    position,
		Message:     "Player played a card",
	})
}

// AddUnitMovedEvent logs unit movement
func (el *EventLog) AddUnitMovedEvent(unitID string, oldPos, newPos Point) {
	el.AddEvent(GameEvent{
		Type:        EventUnitMoved,
		SourceID:    unitID,
		OldPosition: &oldPos,
		Position:    &newPos,
		Message:     "Unit moved",
	})
}

// AddCombatDamageEvent logs combat damage
func (el *EventLog) AddCombatDamageEvent(attackerID, targetID string, damage int) {
	el.AddEvent(GameEvent{
		Type:     EventCombatDamage,
		SourceID: attackerID,
		TargetID: targetID,
		Value:    damage,
		Message:  "Combat damage dealt",
	})
}

// AddMovementCancelledEvent logs when movements are cancelled due to collision
func (el *EventLog) AddMovementCancelledEvent(unitIDs []string, targetPos Point) {
	el.AddEvent(GameEvent{
		Type:     EventMovementCancelled,
		Position: &targetPos,
		Message:  "Movement cancelled due to collision",
		Metadata: map[string]interface{}{
			"unitIDs":        unitIDs,
			"collisionPoint": targetPos,
		},
	})
}

// GetEventsByType returns all events of a specific type
func (el *EventLog) GetEventsByType(eventType EventType) []GameEvent {
	var filtered []GameEvent
	for _, event := range el.Events {
		if event.Type == eventType {
			filtered = append(filtered, event)
		}
	}
	return filtered
}

// GetPlayerEvents returns all events for a specific player
func (el *EventLog) GetPlayerEvents(playerIndex int) []GameEvent {
	var filtered []GameEvent
	for _, event := range el.Events {
		if event.PlayerIndex != nil && *event.PlayerIndex == playerIndex {
			filtered = append(filtered, event)
		}
	}
	return filtered
}