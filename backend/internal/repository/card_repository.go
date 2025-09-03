package repository

import (
	"context"
	"fmt"
	"sync"
	"time"

	"kitbash/backend/internal/domain"
	"kitbash/backend/internal/logger"
)

// InMemoryCardRepository implements the CardRepository interface using in-memory storage.
type InMemoryCardRepository struct {
	cards map[domain.CardID]*domain.Card
	mutex sync.RWMutex
	log   *logger.Logger
}

// NewInMemoryCardRepository creates a new in-memory card repository.
func NewInMemoryCardRepository(log *logger.Logger) *InMemoryCardRepository {
	repo := &InMemoryCardRepository{
		cards: make(map[domain.CardID]*domain.Card),
		log:   log,
	}
	
	// Initialize with default cards
	repo.seedDefaultCards()
	
	return repo
}

// seedDefaultCards populates the repository with initial card data.
func (r *InMemoryCardRepository) seedDefaultCards() {
	now := time.Now()
	
	// Helper function to create string pointers
	strPtr := func(s string) *string { return &s }
	
	defaultCards := []*domain.Card{
		// Red Pawn - Goblin (according to docs: 2/2, Armor 0, Melee)
		{
			ID:          "red_pawn_goblin",
			Name:        "Goblin",
			Description: "Summons a Goblin unit.",
			GoldCost:    1,
			ManaCost:    0,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee"},
			FlavorText: strPtr("Scrappy fighters of the warband."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		// Purple Pawn - Ghoul (according to docs: 1/2, Rekindle, Melee)
		{
			ID:          "purple_pawn_ghoul",
			Name:        "Ghoul",
			Description: "Summons a Ghoul unit.",
			GoldCost:    1,
			ManaCost:    0,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 1,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Rekindle", "Melee"},
			FlavorText: strPtr("Undead servants that refuse to stay dead."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		// Simple Red Unit Card - Orc Warrior
		{
			ID:          "red_unit_orc_warrior",
			Name:        "Orc Warrior",
			Description: "Summons an Orc Warrior unit.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee"},
			FlavorText: strPtr("Fierce warriors of the warband."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		// Simple Purple Spell Card
		{
			ID:          "purple_spell_drain",
			Name:        "Drain Life",
			Description: "Target unit takes 2 damage. You gain 2 health.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorPurple,
			SpellEffect: &domain.SpellEffect{
				TargetType: "unit",
				Effect:     "Deal 2 damage to target unit. Heal 2 health.",
			},
			Abilities:  []string{},
			FlavorText: strPtr("Life force flows from enemy to caster."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
	}
	
	for _, card := range defaultCards {
		r.cards[card.ID] = card
	}
	
	r.log.Info("Seeded card repository with default cards", "count", len(defaultCards))
}

// GetCard retrieves a card by its ID.
func (r *InMemoryCardRepository) GetCard(ctx context.Context, id domain.CardID) (*domain.Card, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	card, exists := r.cards[id]
	if !exists {
		return nil, fmt.Errorf("card with ID %s not found", id)
	}
	
	// Return a copy to prevent external modifications
	cardCopy := *card
	return &cardCopy, nil
}

// GetAllCards retrieves all cards.
func (r *InMemoryCardRepository) GetAllCards(ctx context.Context) ([]*domain.Card, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	cards := make([]*domain.Card, 0, len(r.cards))
	for _, card := range r.cards {
		cardCopy := *card
		cards = append(cards, &cardCopy)
	}
	
	return cards, nil
}

// GetCardsByColor retrieves cards of a specific color.
func (r *InMemoryCardRepository) GetCardsByColor(ctx context.Context, color domain.CardColor) ([]*domain.Card, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	var cards []*domain.Card
	for _, card := range r.cards {
		if card.Color == color {
			cardCopy := *card
			cards = append(cards, &cardCopy)
		}
	}
	
	return cards, nil
}

// GetCardsByType retrieves cards of a specific type.
func (r *InMemoryCardRepository) GetCardsByType(ctx context.Context, cardType domain.CardType) ([]*domain.Card, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	var cards []*domain.Card
	for _, card := range r.cards {
		if card.Type == cardType {
			cardCopy := *card
			cards = append(cards, &cardCopy)
		}
	}
	
	return cards, nil
}

// CreateCard creates a new card.
func (r *InMemoryCardRepository) CreateCard(ctx context.Context, card *domain.Card) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.cards[card.ID]; exists {
		return fmt.Errorf("card with ID %s already exists", card.ID)
	}
	
	now := time.Now()
	card.CreatedAt = now
	card.UpdatedAt = now
	
	r.cards[card.ID] = card
	r.log.Info("Created card", "name", card.Name, "id", card.ID)
	
	return nil
}

// UpdateCard updates an existing card.
func (r *InMemoryCardRepository) UpdateCard(ctx context.Context, card *domain.Card) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.cards[card.ID]; !exists {
		return fmt.Errorf("card with ID %s not found", card.ID)
	}
	
	card.UpdatedAt = time.Now()
	r.cards[card.ID] = card
	r.log.Info("Updated card", "name", card.Name, "id", card.ID)
	
	return nil
}

// DeleteCard deletes a card by its ID.
func (r *InMemoryCardRepository) DeleteCard(ctx context.Context, id domain.CardID) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.cards[id]; !exists {
		return fmt.Errorf("card with ID %s not found", id)
	}
	
	delete(r.cards, id)
	r.log.Info("Deleted card", "id", id)
	
	return nil
}