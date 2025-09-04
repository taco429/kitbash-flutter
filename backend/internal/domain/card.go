package domain

import (
	"context"
	"time"
)

// CardID uniquely identifies a card definition.
type CardID string

// CardType represents the type of card.
type CardType string

const (
	CardTypeUnit     CardType = "unit"
	CardTypeSpell    CardType = "spell"
	CardTypeBuilding CardType = "building"
	CardTypeOrder    CardType = "order"
	CardTypeHero     CardType = "hero"
)

// CardColor represents the faction/color of a card.
type CardColor string

const (
	CardColorRed    CardColor = "red"
	CardColorOrange CardColor = "orange"
	CardColorYellow CardColor = "yellow"
	CardColorGreen  CardColor = "green"
	CardColorBlue   CardColor = "blue"
	CardColorPurple CardColor = "purple"
)

// Card represents a card definition in the game.
type Card struct {
	ID          CardID    `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	GoldCost    int       `json:"goldCost"`
	ManaCost    int       `json:"manaCost"`
	Type        CardType  `json:"type"`
	Color       CardColor `json:"color"`
	// Unit creation properties (for Unit cards)
	UnitStats   *UnitStats `json:"unitStats,omitempty"`
	// Spell properties (for Spell cards)
	SpellEffect *SpellEffect `json:"spellEffect,omitempty"`
	// Building properties (for Building cards)
	BuildingStats *BuildingStats `json:"buildingStats,omitempty"`
	// Hero properties (for Hero cards)
	HeroStats   *HeroStats `json:"heroStats,omitempty"`
	// General properties
	Abilities   []string  `json:"abilities"`
	FlavorText  *string   `json:"flavorText,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// UnitStats represents the stats of a unit created by a Unit card.
type UnitStats struct {
	Attack int `json:"attack"`
	Health int `json:"health"`
	Armor  int `json:"armor"`
	Speed  int `json:"speed"`
	Range  int `json:"range"`
}

// SpellEffect represents the effect of a spell card.
type SpellEffect struct {
	TargetType string `json:"targetType"` // ground, unit, building, hero, global
	Effect     string `json:"effect"`
}

// BuildingStats represents the stats of a building created by a Building card.
type BuildingStats struct {
	Health int  `json:"health"`
	Armor  int  `json:"armor"`
	Attack *int `json:"attack,omitempty"` // Optional for defensive buildings
	Range  *int `json:"range,omitempty"`  // Optional for defensive buildings
}

// HeroStats represents the stats of a hero.
type HeroStats struct {
	Attack   int `json:"attack"`
	Health   int `json:"health"`
	Armor    int `json:"armor"`
	Speed    int `json:"speed"`
	Range    int `json:"range"`
	Cooldown int `json:"cooldown"` // Turns before hero can respawn
}

// IsUnit returns true if the card is a unit card.
func (c *Card) IsUnit() bool {
	return c.Type == CardTypeUnit
}

// IsSpell returns true if the card is a spell.
func (c *Card) IsSpell() bool {
	return c.Type == CardTypeSpell
}

// IsBuilding returns true if the card is a building.
func (c *Card) IsBuilding() bool {
	return c.Type == CardTypeBuilding
}

// IsOrder returns true if the card is an order.
func (c *Card) IsOrder() bool {
	return c.Type == CardTypeOrder
}

// IsHero returns true if the card is a hero.
func (c *Card) IsHero() bool {
	return c.Type == CardTypeHero
}

// TotalCost calculates the total resource cost of a card.
func (c *Card) TotalCost() int {
	return c.GoldCost + c.ManaCost
}

// PowerLevel calculates the power level of a card based on what it creates.
func (c *Card) PowerLevel() int {
	switch c.Type {
	case CardTypeUnit:
		if c.UnitStats != nil {
			return c.UnitStats.Attack + c.UnitStats.Health
		}
	case CardTypeBuilding:
		if c.BuildingStats != nil {
			return c.BuildingStats.Health + (c.BuildingStats.Armor * 2)
		}
	case CardTypeHero:
		if c.HeroStats != nil {
			return c.HeroStats.Attack + c.HeroStats.Health
		}
	}
	return c.TotalCost() // For spells and orders, use total cost
}

// DeckCardEntry represents a card in a deck with quantity.
type DeckCardEntry struct {
	CardID   CardID `json:"cardId"`
	Quantity int    `json:"quantity"`
}

// DeckID uniquely identifies a deck.
type DeckID string

// Deck represents a collection of cards that a player can use.
// According to requirements: Hero + 10 pawns + 20 cards of choice
type Deck struct {
	ID          DeckID          `json:"id"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Color       CardColor       `json:"color"`
	HeroCardID  CardID          `json:"heroCardId"`  // The hero card
	HeroSignatureCardID CardID  `json:"heroSignatureCardId"` // The hero's signature card
	PawnCards   []DeckCardEntry `json:"pawnCards"`   // 10 pawn cards
	MainCards   []DeckCardEntry `json:"mainCards"`   // 20 cards of choice
	IsPrebuilt  bool            `json:"isPrebuilt"`
	CreatedAt   time.Time       `json:"createdAt"`
	UpdatedAt   time.Time       `json:"updatedAt"`
}

// GetAllCards returns all cards in the deck (hero + pawns + main cards).
func (d *Deck) GetAllCards() []DeckCardEntry {
	var allCards []DeckCardEntry
	
	// Add hero card
	allCards = append(allCards, DeckCardEntry{
		CardID:   d.HeroCardID,
		Quantity: 1,
	})
	// Add hero signature card if present
	if d.HeroSignatureCardID != "" {
		allCards = append(allCards, DeckCardEntry{
			CardID:   d.HeroSignatureCardID,
			Quantity: 1,
		})
	}
	
	// Add pawn cards
	allCards = append(allCards, d.PawnCards...)
	
	// Add main cards
	allCards = append(allCards, d.MainCards...)
	
	return allCards
}

// CardCount returns the total number of cards in the deck.
func (d *Deck) CardCount() int {
	total := 1 // Hero card
	
	// Include hero signature card if present
	if d.HeroSignatureCardID != "" {
		total += 1
	}
	
	// Add pawn cards
	for _, entry := range d.PawnCards {
		total += entry.Quantity
	}
	
	// Add main cards
	for _, entry := range d.MainCards {
		total += entry.Quantity
	}
	
	return total
}

// HasCard returns true if the deck contains the specified card.
func (d *Deck) HasCard(cardID CardID) bool {
	if d.HeroCardID == cardID {
		return true
	}
	
	if d.HeroSignatureCardID == cardID {
		return true
	}
	
	for _, entry := range d.PawnCards {
		if entry.CardID == cardID {
			return true
		}
	}
	
	for _, entry := range d.MainCards {
		if entry.CardID == cardID {
			return true
		}
	}
	
	return false
}

// GetCardQuantity returns the quantity of a specific card in the deck.
func (d *Deck) GetCardQuantity(cardID CardID) int {
	if d.HeroCardID == cardID {
		return 1
	}
	
	if d.HeroSignatureCardID == cardID {
		return 1
	}
	
	for _, entry := range d.PawnCards {
		if entry.CardID == cardID {
			return entry.Quantity
		}
	}
	
	for _, entry := range d.MainCards {
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