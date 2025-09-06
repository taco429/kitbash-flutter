package domain

import "time"

// EventType classifies a single atomic change for the client to animate.
type EventType string

const (
    EventTypeTrigger    EventType = "trigger"
    EventTypeResource   EventType = "resource"
    EventTypeDraw       EventType = "draw"
    EventTypeMovement   EventType = "movement"
    EventTypeDamage     EventType = "damage"
    EventTypeEffect     EventType = "effect"
    EventTypeDiscard    EventType = "discard"
    EventTypeRoundStart EventType = "round_start"
    EventTypeRoundEnd   EventType = "round_end"
)

// Event represents one item in the resolution timeline sent to clients.
type Event struct {
    Type      EventType            `json:"type"`
    Step      string               `json:"step"`       // e.g., upkeep, fast, movement, combat, slow, end_of_round
    Timestamp time.Time            `json:"timestamp"`
    Data      map[string]any       `json:"data,omitempty"`
}

// EventLog accumulates events for one round's processing.
type EventLog struct {
    RoundNumber int     `json:"roundNumber"`
    Events      []Event `json:"events"`
}

// NewEventLog creates a new log for the provided round.
func NewEventLog(round int) *EventLog {
    return &EventLog{RoundNumber: round, Events: make([]Event, 0, 32)}
}

// Add appends an event to the log.
func (l *EventLog) Add(evt Event) {
    l.Events = append(l.Events, evt)
}

// AddSimple adds a simple event with a type, step, and arbitrary data.
func (l *EventLog) AddSimple(t EventType, step string, data map[string]any) {
    l.Add(Event{Type: t, Step: step, Timestamp: time.Now(), Data: data})
}

