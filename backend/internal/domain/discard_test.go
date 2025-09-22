package domain

import (
	"testing"
)

func TestDiscardDuringResolution(t *testing.T) {
	// Create a game state with test data
	gs := &GameState{
		ID: "test-game",
		PlayerStates: []PlayerBattleState{
			{
				PlayerIndex: 0,
				Hand: []CardInstance{
					{InstanceID: "card-1", CardID: "lightning_bolt"},
					{InstanceID: "card-2", CardID: "fireball"},
					{InstanceID: "card-3", CardID: "heal"},
				},
				DiscardPile:     []CardInstance{},
				PendingDiscards: []CardInstanceID{"card-1", "card-3"}, // Mark cards 1 and 3 for discard
			},
			{
				PlayerIndex: 1,
				Hand: []CardInstance{
					{InstanceID: "card-4", CardID: "shield"},
					{InstanceID: "card-5", CardID: "sword"},
				},
				DiscardPile:     []CardInstance{},
				PendingDiscards: []CardInstanceID{"card-5"}, // Mark card 5 for discard
			},
		},
	}

	// Execute resolution phase
	log := ExecuteResolutionPhase(gs, ActionQueue{}, ActionQueue{}, nil)

	// Verify player 0's cards were discarded correctly
	p0 := &gs.PlayerStates[0]
	if len(p0.Hand) != 1 {
		t.Errorf("Player 0 should have 1 card in hand, got %d", len(p0.Hand))
	}
	if p0.Hand[0].InstanceID != "card-2" {
		t.Errorf("Player 0 should have card-2 in hand, got %s", p0.Hand[0].InstanceID)
	}
	if len(p0.DiscardPile) != 2 {
		t.Errorf("Player 0 should have 2 cards in discard pile, got %d", len(p0.DiscardPile))
	}
	if len(p0.PendingDiscards) != 0 {
		t.Errorf("Player 0 should have no pending discards, got %d", len(p0.PendingDiscards))
	}

	// Verify player 1's cards were discarded correctly
	p1 := &gs.PlayerStates[1]
	if len(p1.Hand) != 1 {
		t.Errorf("Player 1 should have 1 card in hand, got %d", len(p1.Hand))
	}
	if p1.Hand[0].InstanceID != "card-4" {
		t.Errorf("Player 1 should have card-4 in hand, got %s", p1.Hand[0].InstanceID)
	}
	if len(p1.DiscardPile) != 1 {
		t.Errorf("Player 1 should have 1 card in discard pile, got %d", len(p1.DiscardPile))
	}
	if len(p1.PendingDiscards) != 0 {
		t.Errorf("Player 1 should have no pending discards, got %d", len(p1.PendingDiscards))
	}

	// Verify discard events were logged
	discardEventCount := 0
	for _, event := range log.Events {
		if event.Type == EventTypeDiscard {
			discardEventCount++
		}
	}
	if discardEventCount != 2 {
		t.Errorf("Should have 2 discard events, got %d", discardEventCount)
	}
}
