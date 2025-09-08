package domain

import (
	"fmt"
	"github.com/google/uuid"
)

// CardInstanceID uniquely identifies a specific card instance in a game.
// This is different from CardID which identifies the card type/definition.
type CardInstanceID string

// NewCardInstanceID generates a new unique card instance ID.
func NewCardInstanceID() CardInstanceID {
	return CardInstanceID(uuid.New().String())
}

// CardInstance represents a specific instance of a card in a game.
// Each physical card in a deck has its own CardInstance, even if multiple
// cards share the same CardID (duplicates of the same card type).
type CardInstance struct {
	InstanceID CardInstanceID `json:"instanceId"`
	CardID     CardID         `json:"cardId"`
}

// NewCardInstance creates a new card instance for a given card type.
func NewCardInstance(cardID CardID) CardInstance {
	return CardInstance{
		InstanceID: NewCardInstanceID(),
		CardID:     cardID,
	}
}

// String returns a string representation of the card instance.
func (ci CardInstance) String() string {
	return fmt.Sprintf("CardInstance{ID: %s, Card: %s}", ci.InstanceID, ci.CardID)
}