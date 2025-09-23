package ws

import (
	"context"
	"testing"

	"kitbash/backend/internal/config"
	"kitbash/backend/internal/domain"
	"kitbash/backend/internal/logger"
	"kitbash/backend/internal/repository"
)

func TestDiscardFunctionality(t *testing.T) {
	// Setup
	ctx := context.Background()
	log := logger.Default()
	cfg := config.Config{BoardRows: 7, BoardCols: 9}
	gameRepo := repository.NewInMemoryGameRepository(log)
	_ = NewGameHub(gameRepo, log, cfg) // Hub not used in this test

	// Create a game
	gameID := domain.GameID("test-discard-game")
	players := []domain.Player{
		{ID: "player1", Name: "Player 1"},
		{ID: "player2", Name: "Player 2"},
	}
	gameState, err := gameRepo.Create(ctx, gameID, players, cfg.BoardRows, cfg.BoardCols)
	if err != nil {
		t.Fatalf("Failed to create game: %v", err)
	}

	// Setup player states with cards
	gameState.PlayerStates = []domain.PlayerBattleState{
		{
			PlayerIndex: 0,
			Hand: []domain.CardInstance{
				{InstanceID: "card-1", CardID: "lightning_bolt"},
				{InstanceID: "card-2", CardID: "fireball"},
				{InstanceID: "card-3", CardID: "heal"},
			},
			DrawPile:    []domain.CardInstance{},
			DiscardPile: []domain.CardInstance{},
		},
		{
			PlayerIndex: 1,
			Hand: []domain.CardInstance{
				{InstanceID: "card-4", CardID: "shield"},
				{InstanceID: "card-5", CardID: "sword"},
			},
			DrawPile:    []domain.CardInstance{},
			DiscardPile: []domain.CardInstance{},
		},
	}

	// Start the game and set to planning phase
	gameState.StartGame()
	gameState.SetPhase(domain.PhasePlanning)
	if err := gameRepo.Update(ctx, gameState); err != nil {
		t.Fatalf("Failed to update game state: %v", err)
	}

	// Simulate lock choice with discard cards
	message := map[string]interface{}{
		"playerIndex":  float64(0),
		"discardCards": []interface{}{"card-1", "card-3"},
	}

	// Process the lock choice (simulating handleLockChoice logic)
	playerIndex := int(message["playerIndex"].(float64))
	if discardCards, ok := message["discardCards"].([]interface{}); ok && len(discardCards) > 0 {
		var instanceIDs []domain.CardInstanceID
		for _, card := range discardCards {
			if cardStr, ok := card.(string); ok {
				instanceIDs = append(instanceIDs, domain.CardInstanceID(cardStr))
			}
		}
		if len(instanceIDs) > 0 {
			gameState.PlayerStates[playerIndex].PendingDiscards = instanceIDs
			t.Logf("Added pending discards: %v", instanceIDs)
		}
	}

	// Lock player choice
	gameState.LockPlayerChoice(playerIndex)
	if err := gameRepo.Update(ctx, gameState); err != nil {
		t.Fatalf("Failed to update game state after lock: %v", err)
	}

	// Verify pending discards are saved
	savedState, err := gameRepo.Get(ctx, gameID)
	if err != nil {
		t.Fatalf("Failed to get game state: %v", err)
	}
	if len(savedState.PlayerStates[0].PendingDiscards) != 2 {
		t.Errorf("Expected 2 pending discards, got %d", len(savedState.PlayerStates[0].PendingDiscards))
	}

	// Lock second player
	savedState.LockPlayerChoice(1)
	if err := gameRepo.Update(ctx, savedState); err != nil {
		t.Fatalf("Failed to update game state after second lock: %v", err)
	}

	// Advance to reveal/resolve phase
	savedState.SetPhase(domain.PhaseRevealResolve)
	if err := gameRepo.Update(ctx, savedState); err != nil {
		t.Fatalf("Failed to update game state to reveal phase: %v", err)
	}

	// Execute resolution phase
	resolutionLog := domain.ExecuteResolutionPhase(savedState, domain.ActionQueue{}, domain.ActionQueue{}, nil)

	// Verify discards were processed
	if len(savedState.PlayerStates[0].Hand) != 1 {
		t.Errorf("Expected 1 card in hand after discard, got %d", len(savedState.PlayerStates[0].Hand))
	}
	if savedState.PlayerStates[0].Hand[0].InstanceID != "card-2" {
		t.Errorf("Expected card-2 to remain in hand, got %s", savedState.PlayerStates[0].Hand[0].InstanceID)
	}
	if len(savedState.PlayerStates[0].DiscardPile) != 2 {
		t.Errorf("Expected 2 cards in discard pile, got %d", len(savedState.PlayerStates[0].DiscardPile))
	}
	if len(savedState.PlayerStates[0].PendingDiscards) != 0 {
		t.Errorf("Expected pending discards to be cleared, got %d", len(savedState.PlayerStates[0].PendingDiscards))
	}

	// Check resolution log for discard event
	discardEventFound := false
	for _, event := range resolutionLog.Events {
		if event.Type == domain.EventTypeDiscard {
			discardEventFound = true
			if data, ok := event.Data["count"].(int); ok && data != 2 {
				t.Errorf("Expected discard count to be 2, got %d", data)
			}
		}
	}
	if !discardEventFound {
		t.Error("No discard event found in resolution log")
	}

	t.Log("Test completed successfully")
}