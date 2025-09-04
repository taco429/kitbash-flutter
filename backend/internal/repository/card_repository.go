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
		// ========== RED DECK CARDS ==========
		
		// Red Hero - Korg, Orc Barbarian
		{
			ID:          "red_hero_korg",
			Name:        "Korg, Orc Barbarian",
			Description: "A mighty orc barbarian hero.",
			GoldCost:    3,
			ManaCost:    3,
			Type:        domain.CardTypeHero,
			Color:       domain.CardColorRed,
			HeroStats: &domain.HeroStats{
				Attack:   4,
				Health:   8,
				Armor:    1,
				Speed:    1,
				Range:    1, // Melee
				Cooldown: 2, // 2 turn respawn after death
			},
			Abilities:  []string{"Melee", "Berserker"},
			FlavorText: strPtr("Blood and glory!"),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Hero Signature Card - Rage
		{
			ID:          "red_spell_rage",
			Name:        "Rage",
			Description: "Target friendly unit gains +3 attack this turn.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorRed,
			SpellEffect: &domain.SpellEffect{
				TargetType: "unit",
				Effect:     "Target friendly unit gains +3 attack until end of turn.",
			},
			Abilities:  []string{"Signature"},
			FlavorText: strPtr("Korg's signature battle cry."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Pawn - Goblin (used as pawn but still a unit summoning card)
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
		
		// Red Unit - Orc
		{
			ID:          "red_unit_orc",
			Name:        "Orc",
			Description: "Summons an Orc warrior.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 3,
				Armor:  0,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee"},
			FlavorText: strPtr("Standard orc warrior."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Unit - Big Orc
		{
			ID:          "red_unit_big_orc",
			Name:        "Big Orc",
			Description: "Summons a Big Orc warrior.",
			GoldCost:    4,
			ManaCost:    2,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 5,
				Health: 5,
				Armor:  1,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee", "Taunt"},
			FlavorText: strPtr("Me smash!"),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Unit - Fast Orc
		{
			ID:          "red_unit_fast_orc",
			Name:        "Fast Orc",
			Description: "Summons a Fast Orc scout.",
			GoldCost:    3,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 2,
				Armor:  0,
				Speed:  2, // Faster movement
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee", "Charge"},
			FlavorText: strPtr("Strike fast, strike hard!"),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Unit - Suicide Goblin
		{
			ID:          "red_unit_suicide_goblin",
			Name:        "Suicide Goblin",
			Description: "Summons a Suicide Goblin bomber.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 4,
				Health: 1,
				Armor:  0,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee", "Explode on Death"},
			FlavorText: strPtr("For the horde!"),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Unit - Goblin Buffer
		{
			ID:          "red_unit_goblin_buffer",
			Name:        "Goblin Buffer",
			Description: "Summons a Goblin Buffer support unit.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 1,
				Health: 3,
				Armor:  0,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee", "Adjacent units get +1 attack"},
			FlavorText: strPtr("Fight harder, you gits!"),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Spell - Rush
		{
			ID:          "red_spell_rush",
			Name:        "Rush",
			Description: "All friendly units gain +1 speed this turn.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorRed,
			SpellEffect: &domain.SpellEffect{
				TargetType: "global",
				Effect:     "All friendly units gain +1 speed until end of turn.",
			},
			Abilities:  []string{},
			FlavorText: strPtr("Charge forward!"),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Unit - Goblin Character
		{
			ID:          "red_unit_goblin_character",
			Name:        "Goblin Warchief",
			Description: "Summons a Goblin Warchief leader.",
			GoldCost:    5,
			ManaCost:    3,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 4,
				Armor:  1,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee", "All goblins get +1/+1"},
			FlavorText: strPtr("Leader of the goblin warband."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Red Spell - Bloodlust
		{
			ID:          "red_spell_bloodlust",
			Name:        "Bloodlust",
			Description: "All friendly units gain +2 attack this turn.",
			GoldCost:    0,
			ManaCost:    4,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorRed,
			SpellEffect: &domain.SpellEffect{
				TargetType: "global",
				Effect:     "All friendly units gain +2 attack until end of turn.",
			},
			Abilities:  []string{},
			FlavorText: strPtr("The scent of blood drives them mad!"),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// ========== PURPLE DECK CARDS ==========
		
		// Purple Hero - Hazialim, Tormented Spirit
		{
			ID:          "purple_hero_hazialim",
			Name:        "Hazialim, Tormented Spirit",
			Description: "A tormented spirit hero bound to undeath.",
			GoldCost:    3,
			ManaCost:    3,
			Type:        domain.CardTypeHero,
			Color:       domain.CardColorPurple,
			HeroStats: &domain.HeroStats{
				Attack:   3,
				Health:   7,
				Armor:    0,
				Speed:    1,
				Range:    2, // Ranged
				Cooldown: 2, // 2 turn respawn after death
			},
			Abilities:  []string{"Ranged", "Ethereal"},
			FlavorText: strPtr("Death is only the beginning."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Hero Signature Card - Painful Memories
		{
			ID:          "purple_spell_painful_memories",
			Name:        "Painful Memories",
			Description: "Deal 2 damage to all enemy units.",
			GoldCost:    0,
			ManaCost:    3,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorPurple,
			SpellEffect: &domain.SpellEffect{
				TargetType: "global",
				Effect:     "Deal 2 damage to all enemy units.",
			},
			Abilities:  []string{"Signature"},
			FlavorText: strPtr("Hazialim's tormented past haunts all."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Pawn - Ghoul (used as pawn but still a unit summoning card)
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
		
		// Purple Unit - Cultist
		{
			ID:          "purple_unit_cultist",
			Name:        "Cultist",
			Description: "Summons a Cultist devotee.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 3,
				Armor:  0,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee", "Death: Draw a card"},
			FlavorText: strPtr("Death is a gift to be shared."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Unit - Shackled Spirit
		{
			ID:          "purple_unit_shackled_spirit",
			Name:        "Shackled Spirit",
			Description: "Summons a Shackled Spirit bound to this plane.",
			GoldCost:    3,
			ManaCost:    2,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  2, // Ranged
			},
			Abilities:  []string{"Ranged", "Flying", "Ethereal"},
			FlavorText: strPtr("Bound between life and death."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Unit - Skeletal Archer
		{
			ID:          "purple_unit_skeletal_archer",
			Name:        "Skeletal Archer",
			Description: "Summons a Skeletal Archer.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  3, // Long range
			},
			Abilities:  []string{"Ranged"},
			FlavorText: strPtr("Death does not dull their aim."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Spell - Putrid Miasma
		{
			ID:          "purple_spell_putrid_miasma",
			Name:        "Putrid Miasma",
			Description: "Deal 1 damage to all units. Heal friendly undead for 1.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorPurple,
			SpellEffect: &domain.SpellEffect{
				TargetType: "global",
				Effect:     "Deal 1 damage to all units. Heal friendly undead units for 1 health.",
			},
			Abilities:  []string{},
			FlavorText: strPtr("The stench of decay fills the battlefield."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Unit - Flesh Golem
		{
			ID:          "purple_unit_flesh_golem",
			Name:        "Flesh Golem",
			Description: "Summons a Flesh Golem abomination.",
			GoldCost:    5,
			ManaCost:    3,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 4,
				Health: 6,
				Armor:  1,
				Speed:  1,
				Range:  1, // Melee
			},
			Abilities:  []string{"Melee", "Taunt", "Regenerate 1"},
			FlavorText: strPtr("Stitched together from the fallen."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Spell - Bone Spike
		{
			ID:          "purple_spell_bone_spike",
			Name:        "Bone Spike",
			Description: "Deal 3 damage to target unit.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorPurple,
			SpellEffect: &domain.SpellEffect{
				TargetType: "unit",
				Effect:     "Deal 3 damage to target unit.",
			},
			Abilities:  []string{},
			FlavorText: strPtr("Sharpened bones pierce through armor."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Unit - Human Wizard
		{
			ID:          "purple_unit_human_wizard",
			Name:        "Dark Wizard",
			Description: "Summons a Human Wizard corrupted by dark magic.",
			GoldCost:    4,
			ManaCost:    2,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 3,
				Armor:  0,
				Speed:  1,
				Range:  3, // Ranged
			},
			Abilities:  []string{"Ranged", "Spell Power +1"},
			FlavorText: strPtr("Once noble, now fallen to darkness."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		
		// Purple Unit - Necromancer
		{
			ID:          "purple_unit_necromancer",
			Name:        "Necromancer",
			Description: "Summons a Necromancer master of undeath.",
			GoldCost:    6,
			ManaCost:    4,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 5,
				Armor:  0,
				Speed:  1,
				Range:  2, // Ranged
			},
			Abilities:  []string{"Ranged", "Death: Summon 2 Ghouls"},
			FlavorText: strPtr("Master of life and death."),
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