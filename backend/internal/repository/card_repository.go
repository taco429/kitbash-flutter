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
		// ------------------- Additional Red Cards -------------------
		{
			ID:          "red_hero_korg",
			Name:        "Korg, Orc Barbarian",
			Description: "A savage warleader who thrives in the thick of battle.",
			GoldCost:    3,
			ManaCost:    2,
			Type:        domain.CardTypeHero,
			Color:       domain.CardColorRed,
			HeroStats: &domain.HeroStats{
				Attack:   4,
				Health:   8,
				Armor:    0,
				Speed:    1,
				Range:    1,
				Cooldown: 2,
			},
			Abilities:  []string{"Melee", "Berserk"},
			FlavorText: strPtr("Roaring fury given form."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "red_order_rage",
			Name:        "Rage",
			Description: "Give a friendly unit +2 ATK this round.",
			GoldCost:    0,
			ManaCost:    1,
			Type:        domain.CardTypeOrder,
			Color:       domain.CardColorRed,
			Abilities:   []string{"Buff"},
			FlavorText:  strPtr("Let the fury take you."),
			CreatedAt:   now,
			UpdatedAt:   now,
		},
		{
			ID:          "red_unit_orc",
			Name:        "Orc",
			Description: "Summons a brutish Orc.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee"},
			FlavorText: strPtr("Born for war."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "red_unit_big_orc",
			Name:        "Big Orc",
			Description: "Summons a hulking Orc bruiser.",
			GoldCost:    3,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 4,
				Health: 4,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee"},
			FlavorText: strPtr("He breaks lines by himself."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "red_unit_fast_orc",
			Name:        "Fast Orc",
			Description: "Summons a swift Orc raider.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 2,
				Armor:  0,
				Speed:  2,
				Range:  1,
			},
			Abilities:  []string{"Melee", "Haste"},
			FlavorText: strPtr("Strike fast, strike first."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "red_unit_suicide_goblin",
			Name:        "Suicide Goblin",
			Description: "On Death: Deal 2 damage to adjacent units.",
			GoldCost:    1,
			ManaCost:    0,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 1,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee", "Deathrattle"},
			FlavorText: strPtr("Boom goes the goblin."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "red_unit_goblin_buffer",
			Name:        "Goblin Buffer",
			Description: "Aura: Adjacent Goblins get +1 ATK.",
			GoldCost:    2,
			ManaCost:    0,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 1,
				Health: 3,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee", "Aura"},
			FlavorText: strPtr("He yells till they hit harder."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "red_order_rush",
			Name:        "Rush",
			Description: "Target friendly unit may move and attack immediately.",
			GoldCost:    0,
			ManaCost:    1,
			Type:        domain.CardTypeOrder,
			Color:       domain.CardColorRed,
			Abilities:   []string{"Order"},
			FlavorText:  strPtr("Go! Go! Go!"),
			CreatedAt:   now,
			UpdatedAt:   now,
		},
		{
			ID:          "red_unit_goblin_character",
			Name:        "Goblin Character",
			Description: "A notable goblin with a knack for survival.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorRed,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 3,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee", "Lucky"},
			FlavorText: strPtr("Some goblins just refuse to die."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "red_spell_bloodlust",
			Name:        "Bloodlust",
			Description: "A friendly unit gets +2 ATK and +1 SPD this round.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorRed,
			SpellEffect: &domain.SpellEffect{
				TargetType: "unit",
				Effect:     "+2 ATK and +1 SPD this round",
			},
			Abilities:  []string{"Buff"},
			FlavorText: strPtr("See red. Strike true."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		// ------------------- Additional Purple Cards -------------------
		{
			ID:          "purple_hero_hazialim",
			Name:        "Hazialim, Tormented Spirit",
			Description: "A vengeful echo that commands the dead.",
			GoldCost:    3,
			ManaCost:    2,
			Type:        domain.CardTypeHero,
			Color:       domain.CardColorPurple,
			HeroStats: &domain.HeroStats{
				Attack:   3,
				Health:   7,
				Armor:    0,
				Speed:    1,
				Range:    1,
				Cooldown: 2,
			},
			Abilities:  []string{"Melee", "Haunt"},
			FlavorText: strPtr("Memories bind. Agonies guide."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_spell_painful_memories",
			Name:        "Painful Memories",
			Description: "Deal 2 damage to a unit. If it dies, draw a card.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorPurple,
			SpellEffect: &domain.SpellEffect{
				TargetType: "unit",
				Effect:     "Deal 2 damage. If it dies, draw 1.",
			},
			Abilities:  []string{},
			FlavorText: strPtr("Suffering teaches best."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_unit_cultist",
			Name:        "Cultist",
			Description: "Summons a frail devotee.",
			GoldCost:    1,
			ManaCost:    0,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 1,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee"},
			FlavorText: strPtr("Eager to please their master."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_unit_shackled_spirit",
			Name:        "Shackled Spirit",
			Description: "A restless ghost bound to obey.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Phasing"},
			FlavorText: strPtr("Chains rattle with every step."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_unit_skeletal_archer",
			Name:        "Skeletal Archer",
			Description: "Ranged undead that peppers foes from afar.",
			GoldCost:    2,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  2,
			},
			Abilities:  []string{"Ranged"},
			FlavorText: strPtr("No lungs, yet still a steady breath."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_spell_putrid_miasma",
			Name:        "Putrid Miasma",
			Description: "Deal 1 damage to all units in a lane.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorPurple,
			SpellEffect: &domain.SpellEffect{
				TargetType: "lane",
				Effect:     "Deal 1 damage to all units in target lane",
			},
			Abilities:  []string{"Area"},
			FlavorText: strPtr("The air itself rebels."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_unit_flesh_golem",
			Name:        "Flesh Golem",
			Description: "A stitched mass that refuses to fall.",
			GoldCost:    3,
			ManaCost:    1,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 3,
				Health: 5,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee", "Regenerate 1"},
			FlavorText: strPtr("Built to take punishment."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_spell_bone_spike",
			Name:        "Bone Spike",
			Description: "Deal 3 damage to a unit.",
			GoldCost:    0,
			ManaCost:    2,
			Type:        domain.CardTypeSpell,
			Color:       domain.CardColorPurple,
			SpellEffect: &domain.SpellEffect{
				TargetType: "unit",
				Effect:     "Deal 3 damage",
			},
			Abilities:  []string{},
			FlavorText: strPtr("From below, a sudden end."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_unit_human_wizard",
			Name:        "Human Wizard",
			Description: "A mortal master of the arcane.",
			GoldCost:    2,
			ManaCost:    2,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 2,
				Armor:  0,
				Speed:  1,
				Range:  2,
			},
			Abilities:  []string{"Ranged"},
			FlavorText: strPtr("Knowledge is power."),
			CreatedAt:  now,
			UpdatedAt:  now,
		},
		{
			ID:          "purple_unit_necromancer",
			Name:        "Necromancer",
			Description: "On Death: Summon a 1/1 Skeleton.",
			GoldCost:    3,
			ManaCost:    2,
			Type:        domain.CardTypeUnit,
			Color:       domain.CardColorPurple,
			UnitStats: &domain.UnitStats{
				Attack: 2,
				Health: 3,
				Armor:  0,
				Speed:  1,
				Range:  1,
			},
			Abilities:  []string{"Melee", "Summon"},
			FlavorText: strPtr("Death answers his call."),
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