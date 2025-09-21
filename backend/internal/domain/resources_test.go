package domain

import (
	"testing"
)

func TestResourceGeneration(t *testing.T) {
	t.Run("command center generates correct resources per level", func(t *testing.T) {
		cc := NewBuilding(BuildingCommandCenter, 0, 5, 5)
		
		// Level 1
		gen := cc.GetResourceGeneration()
		if gen.Gold != 3 || gen.Mana != 2 {
			t.Errorf("Level 1: expected 3 gold, 2 mana; got %d gold, %d mana", gen.Gold, gen.Mana)
		}
		
		// Level 2
		cc.Level = Level2
		gen = cc.GetResourceGeneration()
		if gen.Gold != 6 || gen.Mana != 4 {
			t.Errorf("Level 2: expected 6 gold, 4 mana; got %d gold, %d mana", gen.Gold, gen.Mana)
		}
		
		// Level 3
		cc.Level = Level3
		gen = cc.GetResourceGeneration()
		if gen.Gold != 10 || gen.Mana != 6 {
			t.Errorf("Level 3: expected 10 gold, 6 mana; got %d gold, %d mana", gen.Gold, gen.Mana)
		}
	})
	
	t.Run("building upgrades after 3 turns", func(t *testing.T) {
		building := NewBuilding(BuildingCommandCenter, 0, 5, 5)
		
		// Should not upgrade before 3 turns
		if building.ShouldUpgrade() {
			t.Error("Building should not upgrade at turn 0")
		}
		
		building.IncrementTurnCounter()
		if building.ShouldUpgrade() {
			t.Error("Building should not upgrade at turn 1")
		}
		
		building.IncrementTurnCounter()
		if building.ShouldUpgrade() {
			t.Error("Building should not upgrade at turn 2")
		}
		
		building.IncrementTurnCounter()
		if !building.ShouldUpgrade() {
			t.Error("Building should upgrade at turn 3")
		}
		
		// Upgrade and check level
		if !building.Upgrade() {
			t.Error("Building should upgrade successfully")
		}
		if building.Level != Level2 {
			t.Errorf("Building should be level 2, got %v", building.Level)
		}
		if building.TurnsSinceUpgrade != 0 {
			t.Errorf("Turns since upgrade should reset to 0, got %d", building.TurnsSinceUpgrade)
		}
	})
	
	t.Run("building cannot upgrade past level 3", func(t *testing.T) {
		building := NewBuilding(BuildingCommandCenter, 0, 5, 5)
		building.Level = Level3
		building.TurnsSinceUpgrade = 10
		
		if building.ShouldUpgrade() {
			t.Error("Level 3 building should not upgrade")
		}
		
		if building.Upgrade() {
			t.Error("Level 3 building upgrade should return false")
		}
	})
}

func TestGameStateResourceGeneration(t *testing.T) {
	t.Run("resources are generated each turn", func(t *testing.T) {
		// Create a game state with 2 players
		gameState := NewGameState("test-game", []Player{
			{ID: "p1", Name: "Player 1"},
			{ID: "p2", Name: "Player 2"},
		}, 13, 13)
		
		// Initialize player states
		gameState.PlayerStates = []PlayerBattleState{
			{
				PlayerIndex: 0,
				Resources: Resources{Gold: 0, Mana: 0},
			},
			{
				PlayerIndex: 1,
				Resources: Resources{Gold: 0, Mana: 0},
			},
		}
		
		// Process resource generation
		gameState.ProcessResourceGeneration()
		
		// Check that resources were generated based on command centers
		for i := range gameState.PlayerStates {
			ps := &gameState.PlayerStates[i]
			
			// Should have Level 1 command center resources
			if ps.Resources.Gold != 3 {
				t.Errorf("Player %d: expected 3 gold, got %d", i, ps.Resources.Gold)
			}
			if ps.Resources.Mana != 2 {
				t.Errorf("Player %d: expected 2 mana, got %d", i, ps.Resources.Mana)
			}
			if ps.ResourceIncome.Gold != 3 {
				t.Errorf("Player %d: expected 3 gold income, got %d", i, ps.ResourceIncome.Gold)
			}
			if ps.ResourceIncome.Mana != 2 {
				t.Errorf("Player %d: expected 2 mana income, got %d", i, ps.ResourceIncome.Mana)
			}
		}
	})
	
	t.Run("gold accumulates, mana resets", func(t *testing.T) {
		gameState := NewGameState("test-game", []Player{
			{ID: "p1", Name: "Player 1"},
			{ID: "p2", Name: "Player 2"},
		}, 13, 13)
		
		// Initialize player states with existing resources
		gameState.PlayerStates = []PlayerBattleState{
			{
				PlayerIndex: 0,
				Resources: Resources{Gold: 10, Mana: 5},
			},
			{
				PlayerIndex: 1,
				Resources: Resources{Gold: 15, Mana: 3},
			},
		}
		
		// Process resource generation
		gameState.ProcessResourceGeneration()
		
		// Check that gold accumulated and mana was reset
		ps0 := &gameState.PlayerStates[0]
		if ps0.Resources.Gold != 13 { // 10 + 3 from level 1 command center
			t.Errorf("Player 0: expected 13 gold (accumulated), got %d", ps0.Resources.Gold)
		}
		if ps0.Resources.Mana != 2 { // Reset to 2 from level 1 command center
			t.Errorf("Player 0: expected 2 mana (reset), got %d", ps0.Resources.Mana)
		}
		
		ps1 := &gameState.PlayerStates[1]
		if ps1.Resources.Gold != 18 { // 15 + 3 from level 1 command center
			t.Errorf("Player 1: expected 18 gold (accumulated), got %d", ps1.Resources.Gold)
		}
		if ps1.Resources.Mana != 2 { // Reset to 2 from level 1 command center
			t.Errorf("Player 1: expected 2 mana (reset), got %d", ps1.Resources.Mana)
		}
	})
	
	t.Run("spend resources", func(t *testing.T) {
		gameState := NewGameState("test-game", []Player{
			{ID: "p1", Name: "Player 1"},
			{ID: "p2", Name: "Player 2"},
		}, 13, 13)
		
		gameState.PlayerStates = []PlayerBattleState{
			{
				PlayerIndex: 0,
				Resources: Resources{Gold: 10, Mana: 5},
			},
			{
				PlayerIndex: 1,
				Resources: Resources{Gold: 3, Mana: 2},
			},
		}
		
		// Try to spend affordable resources
		if !gameState.SpendResources(0, Resources{Gold: 5, Mana: 3}) {
			t.Error("Should be able to spend 5 gold, 3 mana when having 10 gold, 5 mana")
		}
		
		ps0 := &gameState.PlayerStates[0]
		if ps0.Resources.Gold != 5 || ps0.Resources.Mana != 2 {
			t.Errorf("After spending, expected 5 gold, 2 mana; got %d gold, %d mana",
				ps0.Resources.Gold, ps0.Resources.Mana)
		}
		
		// Try to spend unaffordable resources
		if gameState.SpendResources(1, Resources{Gold: 5, Mana: 3}) {
			t.Error("Should not be able to spend 5 gold, 3 mana when having 3 gold, 2 mana")
		}
		
		ps1 := &gameState.PlayerStates[1]
		if ps1.Resources.Gold != 3 || ps1.Resources.Mana != 2 {
			t.Errorf("Resources should not change on failed spend; got %d gold, %d mana",
				ps1.Resources.Gold, ps1.Resources.Mana)
		}
	})
}

func TestBuildingUpgradeIntegration(t *testing.T) {
	t.Run("command centers upgrade automatically", func(t *testing.T) {
		gameState := NewGameState("test-game", []Player{
			{ID: "p1", Name: "Player 1"},
			{ID: "p2", Name: "Player 2"},
		}, 13, 13)
		
		// Buildings start at turn 0, should upgrade after 3 complete turns
		// Turn 1
		gameState.ProcessBuildingUpgrades()
		for _, cc := range gameState.CommandCenters {
			if cc.Building.Level != Level1 {
				t.Errorf("Turn 1: Command center should be level 1, got %v", cc.Building.Level)
			}
			if cc.Building.TurnsSinceUpgrade != 1 {
				t.Errorf("Turn 1: Should have 1 turn since upgrade, got %d", cc.Building.TurnsSinceUpgrade)
			}
		}
		
		// Turn 2
		gameState.ProcessBuildingUpgrades()
		for _, cc := range gameState.CommandCenters {
			if cc.Building.Level != Level1 {
				t.Errorf("Turn 2: Command center should be level 1, got %v", cc.Building.Level)
			}
			if cc.Building.TurnsSinceUpgrade != 2 {
				t.Errorf("Turn 2: Should have 2 turns since upgrade, got %d", cc.Building.TurnsSinceUpgrade)
			}
		}
		
		// Turn 3
		gameState.ProcessBuildingUpgrades()
		for _, cc := range gameState.CommandCenters {
			if cc.Building.Level != Level1 {
				t.Errorf("Turn 3: Command center should be level 1, got %v", cc.Building.Level)
			}
			if cc.Building.TurnsSinceUpgrade != 3 {
				t.Errorf("Turn 3: Should have 3 turns since upgrade, got %d", cc.Building.TurnsSinceUpgrade)
			}
		}
		
		// Turn 4 - should trigger upgrade
		gameState.ProcessBuildingUpgrades()
		for _, cc := range gameState.CommandCenters {
			if cc.Building.Level != Level2 {
				t.Errorf("Turn 4: Command center should be level 2 after 3 complete turns, got %v", cc.Building.Level)
			}
			if cc.Building.TurnsSinceUpgrade != 0 {
				t.Errorf("Turn 4: Should have 0 turns since upgrade (just upgraded), got %d", cc.Building.TurnsSinceUpgrade)
			}
		}
		
		// After upgrade, resources should increase
		gameState.PlayerStates = []PlayerBattleState{
			{PlayerIndex: 0, Resources: Resources{Gold: 0, Mana: 0}},
			{PlayerIndex: 1, Resources: Resources{Gold: 0, Mana: 0}},
		}
		
		gameState.ProcessResourceGeneration()
		
		for i := range gameState.PlayerStates {
			ps := &gameState.PlayerStates[i]
			if ps.Resources.Gold != 6 { // Level 2 generates 6 gold
				t.Errorf("Player %d: expected 6 gold from level 2, got %d", i, ps.Resources.Gold)
			}
			if ps.Resources.Mana != 4 { // Level 2 generates 4 mana
				t.Errorf("Player %d: expected 4 mana from level 2, got %d", i, ps.Resources.Mana)
			}
		}
	})
	
	t.Run("full turn cycle with resource generation", func(t *testing.T) {
		gameState := NewGameState("test-game", []Player{
			{ID: "p1", Name: "Player 1"},
			{ID: "p2", Name: "Player 2"},
		}, 13, 13)
		
		gameState.PlayerStates = []PlayerBattleState{
			{PlayerIndex: 0, Resources: Resources{Gold: 0, Mana: 0}},
			{PlayerIndex: 1, Resources: Resources{Gold: 0, Mana: 0}},
		}
		
		// Simulate multiple turns
		for turn := 1; turn <= 9; turn++ {
			gameState.AdvanceTurn()
			
			// Check resources after each turn
			expectedGold := 0
			expectedMana := 0
			expectedLevel := Level1
			
			// Buildings upgrade every 3 turns:
			// Turn 1-3: Level 1 (3 gold, 2 mana per turn)
			// Turn 4-7: Level 2 (6 gold, 4 mana per turn) - upgrades at start of turn 4
			// Turn 8+: Level 3 (10 gold, 6 mana per turn) - upgrades at start of turn 8
			if turn <= 3 {
				expectedGold = 3 * turn  // 3 gold per turn at level 1
				expectedMana = 2          // 2 mana (reset each turn)
				expectedLevel = Level1
			} else if turn <= 7 {
				expectedGold = 3*3 + 6*(turn-3)  // 9 gold from first 3 turns, then 6 per turn at level 2
				expectedMana = 4                  // 4 mana at level 2
				expectedLevel = Level2
			} else {
				expectedGold = 3*3 + 6*4 + 10*(turn-7)  // 9 + 24 = 33 gold from first 7 turns, then 10 per turn at level 3
				expectedMana = 6                         // 6 mana at level 3
				expectedLevel = Level3
			}
			
			for i, ps := range gameState.PlayerStates {
				if ps.Resources.Gold != expectedGold {
					// Add debug info
					cc := gameState.CommandCenters[i]
					t.Errorf("Turn %d, Player %d: expected %d gold, got %d (building level: %v, turns since upgrade: %d)",
						turn, i, expectedGold, ps.Resources.Gold, cc.Building.Level, cc.Building.TurnsSinceUpgrade)
				}
				if ps.Resources.Mana != expectedMana {
					cc := gameState.CommandCenters[i]
					t.Errorf("Turn %d, Player %d: expected %d mana, got %d (building level: %v)",
						turn, i, expectedMana, ps.Resources.Mana, cc.Building.Level)
				}
			}
			
			// Check building levels
			for _, cc := range gameState.CommandCenters {
				if cc.Building.Level != expectedLevel {
					t.Errorf("Turn %d: expected building level %v, got %v (turns since upgrade: %d)",
						turn, expectedLevel, cc.Building.Level, cc.Building.TurnsSinceUpgrade)
				}
			}
		}
	})
}