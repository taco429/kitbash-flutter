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
	
	// Helper function to create int pointers
	intPtr := func(i int) *int { return &i }
	strPtr := func(s string) *string { return &s }
	
	defaultCards := []*domain.Card{
		{
			ID:          "skeleton_001",
			Name:        "Skeleton Warrior",
			Description: "A reanimated warrior that fights with undying loyalty.",
			Cost:        2,
			Type:        domain.CardTypeCreature,
			Color:       domain.CardColorPurple,
			Attack:      intPtr(2),
			Health:      intPtr(1),
			Abilities:   []string{"Undead"},
			FlavorText:  strPtr("Death is but the beginning of service."),
			CreatedAt:   now,
			UpdatedAt:   now,
		},
		{
			ID:          "skeleton_002",
			Name:        "Skeleton Archer",
			Description: "An undead archer that can strike from a distance.",
			Cost:        3,
			Type:        domain.CardTypeCreature,
			Color:       domain.CardColorPurple,
			Attack:      intPtr(2),
			Health:      intPtr(2),
			Abilities:   []string{"Undead", "Ranged"},
			FlavorText:  strPtr("Even in death, their aim remains true."),
			CreatedAt:   now,
			UpdatedAt:   now,
		},
		{
			ID:          "goblin_001",
			Name:        "Goblin Raider",
			Description: "A fierce and quick goblin warrior ready for battle.",
			Cost:        1,
			Type:        domain.CardTypeCreature,
			Color:       domain.CardColorRed,
			Attack:      intPtr(2),
			Health:      intPtr(1),
			Abilities:   []string{"Haste"},
			FlavorText:  strPtr("Small in stature, big in fury."),
			CreatedAt:   now,
			UpdatedAt:   now,
		},
		{
			ID:          "goblin_002",
			Name:        "Goblin Chieftain",
			Description: "A powerful goblin leader that rallies other goblins.",
			Cost:        3,
			Type:        domain.CardTypeCreature,
			Color:       domain.CardColorRed,
			Attack:      intPtr(3),
			Health:      intPtr(2),
			Abilities:   []string{"Haste", "Rally"},
			FlavorText:  strPtr("Where the chieftain leads, the tribe follows."),
			CreatedAt:   now,
			UpdatedAt:   now,
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