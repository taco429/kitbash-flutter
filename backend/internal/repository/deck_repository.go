package repository

import (
	"context"
	"fmt"
	"sync"
	"time"

	"kitbash/backend/internal/domain"
	"kitbash/backend/internal/logger"
)

// InMemoryDeckRepository implements the DeckRepository interface using in-memory storage.
type InMemoryDeckRepository struct {
	decks map[domain.DeckID]*domain.Deck
	mutex sync.RWMutex
	log   *logger.Logger
}

// NewInMemoryDeckRepository creates a new in-memory deck repository.
func NewInMemoryDeckRepository(log *logger.Logger) *InMemoryDeckRepository {
	repo := &InMemoryDeckRepository{
		decks: make(map[domain.DeckID]*domain.Deck),
		log:   log,
	}
	
	// Initialize with default decks
	repo.seedDefaultDecks()
	
	return repo
}

// seedDefaultDecks populates the repository with initial deck data.
func (r *InMemoryDeckRepository) seedDefaultDecks() {
	now := time.Now()
	
	defaultDecks := []*domain.Deck{
		{
			ID:          "red_deck_001",
			Name:        "Goblin Swarm",
			Description: "An aggressive deck full of fierce goblins ready for battle. Quick strikes and overwhelming numbers.",
			Color:       domain.CardColorRed,
			Cards: []domain.DeckCardEntry{
				{CardID: "goblin_001", Quantity: 23}, // Goblin Raiders
				{CardID: "goblin_002", Quantity: 7},  // Goblin Chieftains
			},
			IsPrebuilt: true,
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_deck_001",
			Name:        "Undead Legion",
			Description: "A strategic deck of undead warriors that never truly die. Balanced mix of melee and ranged units.",
			Color:       domain.CardColorPurple,
			Cards: []domain.DeckCardEntry{
				{CardID: "skeleton_001", Quantity: 15}, // Skeleton Warriors
				{CardID: "skeleton_002", Quantity: 15}, // Skeleton Archers
			},
			IsPrebuilt: true,
			CreatedAt:  now,
			UpdatedAt:  now,
		},
	}
	
	for _, deck := range defaultDecks {
		r.decks[deck.ID] = deck
	}
	
	r.log.Info("Seeded deck repository with default decks", "count", len(defaultDecks))
}

// GetDeck retrieves a deck by its ID.
func (r *InMemoryDeckRepository) GetDeck(ctx context.Context, id domain.DeckID) (*domain.Deck, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	deck, exists := r.decks[id]
	if !exists {
		return nil, fmt.Errorf("deck with ID %s not found", id)
	}
	
	// Return a copy to prevent external modifications
	deckCopy := *deck
	deckCopy.Cards = make([]domain.DeckCardEntry, len(deck.Cards))
	copy(deckCopy.Cards, deck.Cards)
	
	return &deckCopy, nil
}

// GetAllDecks retrieves all decks.
func (r *InMemoryDeckRepository) GetAllDecks(ctx context.Context) ([]*domain.Deck, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	decks := make([]*domain.Deck, 0, len(r.decks))
	for _, deck := range r.decks {
		deckCopy := *deck
		deckCopy.Cards = make([]domain.DeckCardEntry, len(deck.Cards))
		copy(deckCopy.Cards, deck.Cards)
		decks = append(decks, &deckCopy)
	}
	
	return decks, nil
}

// GetPrebuiltDecks retrieves all prebuilt decks.
func (r *InMemoryDeckRepository) GetPrebuiltDecks(ctx context.Context) ([]*domain.Deck, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	var decks []*domain.Deck
	for _, deck := range r.decks {
		if deck.IsPrebuilt {
			deckCopy := *deck
			deckCopy.Cards = make([]domain.DeckCardEntry, len(deck.Cards))
			copy(deckCopy.Cards, deck.Cards)
			decks = append(decks, &deckCopy)
		}
	}
	
	return decks, nil
}

// GetDecksByColor retrieves decks of a specific color.
func (r *InMemoryDeckRepository) GetDecksByColor(ctx context.Context, color domain.CardColor) ([]*domain.Deck, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	var decks []*domain.Deck
	for _, deck := range r.decks {
		if deck.Color == color {
			deckCopy := *deck
			deckCopy.Cards = make([]domain.DeckCardEntry, len(deck.Cards))
			copy(deckCopy.Cards, deck.Cards)
			decks = append(decks, &deckCopy)
		}
	}
	
	return decks, nil
}

// CreateDeck creates a new deck.
func (r *InMemoryDeckRepository) CreateDeck(ctx context.Context, deck *domain.Deck) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.decks[deck.ID]; exists {
		return fmt.Errorf("deck with ID %s already exists", deck.ID)
	}
	
	now := time.Now()
	deck.CreatedAt = now
	deck.UpdatedAt = now
	
	r.decks[deck.ID] = deck
	r.log.Info("Created deck", "name", deck.Name, "id", deck.ID)
	
	return nil
}

// UpdateDeck updates an existing deck.
func (r *InMemoryDeckRepository) UpdateDeck(ctx context.Context, deck *domain.Deck) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.decks[deck.ID]; !exists {
		return fmt.Errorf("deck with ID %s not found", deck.ID)
	}
	
	deck.UpdatedAt = time.Now()
	r.decks[deck.ID] = deck
	r.log.Info("Updated deck", "name", deck.Name, "id", deck.ID)
	
	return nil
}

// DeleteDeck deletes a deck by its ID.
func (r *InMemoryDeckRepository) DeleteDeck(ctx context.Context, id domain.DeckID) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.decks[id]; !exists {
		return fmt.Errorf("deck with ID %s not found", id)
	}
	
	delete(r.decks, id)
	r.log.Info("Deleted deck", "id", id)
	
	return nil
}