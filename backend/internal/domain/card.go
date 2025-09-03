package domain

import (
	"context"
	"time"
)

// CardID uniquely identifies a card definition.
type CardID string

// CardType represents the type of card (creature, spell, etc.).
type CardType string

const (
	CardTypeCreature CardType = "creature"
	CardTypeSpell    CardType = "spell"
	CardTypeArtifact CardType = "artifact"
)

// CardColor represents the faction/color of a card.
type CardColor string

const (
	CardColorRed     CardColor = "red"
	CardColorPurple  CardColor = "purple"
	CardColorBlue    CardColor = "blue"
	CardColorGreen   CardColor = "green"
	CardColorWhite   CardColor = "white"
	CardColorBlack   CardColor = "black"
	CardColorNeutral CardColor = "neutral"
)

// Card represents a card definition in the game.
type Card struct {
	ID          CardID    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	Cost        int       `json:"cost"`
	Type        CardType  `json:"type"`
	Color       CardColor `json:"color"`
	Attack      *int      `json:"attack,omitempty"`      // Only for creatures
	Health      *int      `json:"health,omitempty"`      // Only for creatures
	Abilities   []string  `json:"abilities"`
	FlavorText  *string   `json:"flavorText,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// IsCreature returns true if the card is a creature.
func (c *Card) IsCreature() bool {
	return c.Type == CardTypeCreature
}

// IsSpell returns true if the card is a spell.
func (c *Card) IsSpell() bool {
	return c.Type == CardTypeSpell
}

// PowerLevel calculates the power level of a card.
// For creatures, it's attack + health. For other cards, it's the cost.
func (c *Card) PowerLevel() int {
	if c.IsCreature() && c.Attack != nil && c.Health != nil {
		return *c.Attack + *c.Health
	}
	return c.Cost
}

// DeckCardEntry represents a card in a deck with quantity.
type DeckCardEntry struct {
	CardID   CardID `json:"cardId"`
	Quantity int    `json:"quantity"`
}

// DeckID uniquely identifies a deck.
type DeckID string

// Deck represents a collection of cards that a player can use.
type Deck struct {
	ID          DeckID          `json:"id"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Color       CardColor       `json:"color"`
	Cards       []DeckCardEntry `json:"cards"`
	IsPrebuilt  bool            `json:"isPrebuilt"`
	CreatedAt   time.Time       `json:"createdAt"`
	UpdatedAt   time.Time       `json:"updatedAt"`
}

// CardCount returns the total number of cards in the deck.
func (d *Deck) CardCount() int {
	total := 0
	for _, entry := range d.Cards {
		total += entry.Quantity
	}
	return total
}

// HasCard returns true if the deck contains the specified card.
func (d *Deck) HasCard(cardID CardID) bool {
	for _, entry := range d.Cards {
		if entry.CardID == cardID {
			return true
		}
	}
	return false
}

// GetCardQuantity returns the quantity of a specific card in the deck.
func (d *Deck) GetCardQuantity(cardID CardID) int {
	for _, entry := range d.Cards {
		if entry.CardID == cardID {
			return entry.Quantity
		}
	}
	return 0
}

// CardRepository defines the interface for card data access.
type CardRepository interface {
	// GetCard retrieves a card by its ID.
	GetCard(ctx context.Context, id CardID) (*Card, error)
	
	// GetAllCards retrieves all cards.
	GetAllCards(ctx context.Context) ([]*Card, error)
	
	// GetCardsByColor retrieves cards of a specific color.
	GetCardsByColor(ctx context.Context, color CardColor) ([]*Card, error)
	
	// GetCardsByType retrieves cards of a specific type.
	GetCardsByType(ctx context.Context, cardType CardType) ([]*Card, error)
	
	// CreateCard creates a new card.
	CreateCard(ctx context.Context, card *Card) error
	
	// UpdateCard updates an existing card.
	UpdateCard(ctx context.Context, card *Card) error
	
	// DeleteCard deletes a card by its ID.
	DeleteCard(ctx context.Context, id CardID) error
}

// DeckRepository defines the interface for deck data access.
type DeckRepository interface {
	// GetDeck retrieves a deck by its ID.
	GetDeck(ctx context.Context, id DeckID) (*Deck, error)
	
	// GetAllDecks retrieves all decks.
	GetAllDecks(ctx context.Context) ([]*Deck, error)
	
	// GetPrebuiltDecks retrieves all prebuilt decks.
	GetPrebuiltDecks(ctx context.Context) ([]*Deck, error)
	
	// GetDecksByColor retrieves decks of a specific color.
	GetDecksByColor(ctx context.Context, color CardColor) ([]*Deck, error)
	
	// CreateDeck creates a new deck.
	CreateDeck(ctx context.Context, deck *Deck) error
	
	// UpdateDeck updates an existing deck.
	UpdateDeck(ctx context.Context, deck *Deck) error
	
	// DeleteDeck deletes a deck by its ID.
	DeleteDeck(ctx context.Context, id DeckID) error
}