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
			ID:              "red_deck_001",
			Name:            "Orc Warband",
			Description:     "An aggressive red deck led by Korg, featuring orcs and goblins in overwhelming assault tactics.",
			Color:           domain.CardColorRed,
			HeroCardID:      "red_hero_korg",  // Korg, Orc Barbarian
			SignatureCardID: "red_spell_rage", // Rage - Korg's signature spell
			PawnCards: []domain.DeckCardEntry{
				{CardID: "red_pawn_goblin", Quantity: 10}, // 10 Goblin pawns
			},
			MainCards: []domain.DeckCardEntry{
				// Units (16 cards)
				{CardID: "red_unit_orc", Quantity: 3},
				{CardID: "red_unit_big_orc", Quantity: 3},
				{CardID: "red_unit_fast_orc", Quantity: 3},
				{CardID: "red_unit_suicide_goblin", Quantity: 3},
				{CardID: "red_unit_goblin_buffer", Quantity: 3},
				{CardID: "red_unit_goblin_character", Quantity: 1}, // Goblin Warchief
				// Spells (4 cards)
				{CardID: "red_spell_rush", Quantity: 3},
				{CardID: "red_spell_bloodlust", Quantity: 1},
				// Total: 20 cards (as requested by user, signature card handled separately)
			},
			IsPrebuilt: true,
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:              "purple_deck_001",
			Name:            "Tormented Spirits",
			Description:     "A purple deck led by Hazialim, harnessing undeath and dark magic to control the battlefield.",
			Color:           domain.CardColorPurple,
			HeroCardID:      "purple_hero_hazialim",           // Hazialim, Tormented Spirit
			SignatureCardID: "purple_spell_painful_memories", // Painful Memories - Hazialim's signature spell
			PawnCards: []domain.DeckCardEntry{
				{CardID: "purple_pawn_ghoul", Quantity: 10}, // 10 Ghoul pawns
			},
			MainCards: []domain.DeckCardEntry{
				// Units (14 cards)
				{CardID: "purple_unit_cultist", Quantity: 3},
				{CardID: "purple_unit_shackled_spirit", Quantity: 3},
				{CardID: "purple_unit_skeletal_archer", Quantity: 3},
				{CardID: "purple_unit_flesh_golem", Quantity: 3},
				{CardID: "purple_unit_human_wizard", Quantity: 1}, // Dark Wizard
				{CardID: "purple_unit_necromancer", Quantity: 1},
				// Spells (6 cards)
				{CardID: "purple_spell_putrid_miasma", Quantity: 3},
				{CardID: "purple_spell_bone_spike", Quantity: 3},
				// Total: 20 cards (as requested by user, signature card handled separately)
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
	deckCopy.PawnCards = make([]domain.DeckCardEntry, len(deck.PawnCards))
	copy(deckCopy.PawnCards, deck.PawnCards)
	deckCopy.MainCards = make([]domain.DeckCardEntry, len(deck.MainCards))
	copy(deckCopy.MainCards, deck.MainCards)
	
	return &deckCopy, nil
}

// GetAllDecks retrieves all decks.
func (r *InMemoryDeckRepository) GetAllDecks(ctx context.Context) ([]*domain.Deck, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	decks := make([]*domain.Deck, 0, len(r.decks))
	for _, deck := range r.decks {
		deckCopy := *deck
		deckCopy.PawnCards = make([]domain.DeckCardEntry, len(deck.PawnCards))
		copy(deckCopy.PawnCards, deck.PawnCards)
		deckCopy.MainCards = make([]domain.DeckCardEntry, len(deck.MainCards))
		copy(deckCopy.MainCards, deck.MainCards)
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
			deckCopy.PawnCards = make([]domain.DeckCardEntry, len(deck.PawnCards))
			copy(deckCopy.PawnCards, deck.PawnCards)
			deckCopy.MainCards = make([]domain.DeckCardEntry, len(deck.MainCards))
			copy(deckCopy.MainCards, deck.MainCards)
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
			deckCopy.PawnCards = make([]domain.DeckCardEntry, len(deck.PawnCards))
			copy(deckCopy.PawnCards, deck.PawnCards)
			deckCopy.MainCards = make([]domain.DeckCardEntry, len(deck.MainCards))
			copy(deckCopy.MainCards, deck.MainCards)
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