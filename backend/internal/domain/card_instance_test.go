package domain

import (
	"testing"
)

func TestCardInstance(t *testing.T) {
	t.Run("should create unique instances for same card type", func(t *testing.T) {
		// Create multiple instances of the same card
		instance1 := NewCardInstance("lightning-bolt")
		instance2 := NewCardInstance("lightning-bolt")
		instance3 := NewCardInstance("lightning-bolt")

		// All instances should have the same card ID
		if instance1.CardID != "lightning-bolt" {
			t.Errorf("Expected CardID to be 'lightning-bolt', got %s", instance1.CardID)
		}
		if instance2.CardID != "lightning-bolt" {
			t.Errorf("Expected CardID to be 'lightning-bolt', got %s", instance2.CardID)
		}
		if instance3.CardID != "lightning-bolt" {
			t.Errorf("Expected CardID to be 'lightning-bolt', got %s", instance3.CardID)
		}

		// But different instance IDs
		if instance1.InstanceID == instance2.InstanceID {
			t.Error("Instance IDs should be unique")
		}
		if instance2.InstanceID == instance3.InstanceID {
			t.Error("Instance IDs should be unique")
		}
		if instance1.InstanceID == instance3.InstanceID {
			t.Error("Instance IDs should be unique")
		}
	})

	t.Run("should handle a deck with duplicate cards", func(t *testing.T) {
		// Simulate a draw pile with 3 Lightning Bolts and 2 Fireballs
		drawPile := []CardInstance{
			NewCardInstance("lightning-bolt"),
			NewCardInstance("fireball"),
			NewCardInstance("lightning-bolt"),
			NewCardInstance("fireball"),
			NewCardInstance("lightning-bolt"),
		}

		// Count cards by type
		cardCounts := make(map[CardID]int)
		for _, instance := range drawPile {
			cardCounts[instance.CardID]++
		}

		if cardCounts["lightning-bolt"] != 3 {
			t.Errorf("Expected 3 lightning-bolt cards, got %d", cardCounts["lightning-bolt"])
		}
		if cardCounts["fireball"] != 2 {
			t.Errorf("Expected 2 fireball cards, got %d", cardCounts["fireball"])
		}

		// Each instance should be unique
		instanceIDs := make(map[CardInstanceID]bool)
		for _, instance := range drawPile {
			if instanceIDs[instance.InstanceID] {
				t.Error("Found duplicate instance ID")
			}
			instanceIDs[instance.InstanceID] = true
		}

		if len(instanceIDs) != 5 {
			t.Errorf("Expected 5 unique instances, got %d", len(instanceIDs))
		}
	})

	t.Run("should allow discarding specific duplicates", func(t *testing.T) {
		// Create a hand with 3 Lightning Bolts
		hand := []CardInstance{
			NewCardInstance("lightning-bolt"),
			NewCardInstance("lightning-bolt"),
			NewCardInstance("lightning-bolt"),
		}

		// Select only the second Lightning Bolt for discard
		selectedForDiscard := hand[1].InstanceID

		// Simulate discarding
		var remainingHand []CardInstance
		var discardPile []CardInstance

		for _, card := range hand {
			if card.InstanceID == selectedForDiscard {
				discardPile = append(discardPile, card)
			} else {
				remainingHand = append(remainingHand, card)
			}
		}

		// Check results
		if len(discardPile) != 1 {
			t.Errorf("Expected 1 card in discard pile, got %d", len(discardPile))
		}
		if len(remainingHand) != 2 {
			t.Errorf("Expected 2 cards remaining in hand, got %d", len(remainingHand))
		}

		// All cards should still be Lightning Bolts
		for _, card := range remainingHand {
			if card.CardID != "lightning-bolt" {
				t.Errorf("Expected all remaining cards to be lightning-bolt, got %s", card.CardID)
			}
		}
	})
}