package domain

import (
	"context"
	"testing"
	"time"
)

// MockCardRepository implements a minimal CardRepository for testing
type MockCardRepository struct {
	cards map[CardID]*Card
}

func NewMockCardRepository() *MockCardRepository {
	return &MockCardRepository{
		cards: make(map[CardID]*Card),
	}
}

func (r *MockCardRepository) AddCard(card *Card) {
	r.cards[card.ID] = card
}

func (r *MockCardRepository) GetCard(ctx context.Context, id CardID) (*Card, error) {
	card, ok := r.cards[id]
	if !ok {
		return nil, nil
	}
	return card, nil
}

// Test basic unit creation
func TestNewUnit(t *testing.T) {
	stats := &UnitStats{
		Attack: 5,
		Health: 10,
		Armor:  2,
		Speed:  3,
		Range:  1,
	}

	unit := NewUnit("goblin_warrior", 0, Point{Row: 2, Col: 3}, stats, 1)

	// Verify unit properties
	if unit.CardID != "goblin_warrior" {
		t.Errorf("Expected CardID to be 'goblin_warrior', got %s", unit.CardID)
	}
	if unit.PlayerIndex != 0 {
		t.Errorf("Expected PlayerIndex to be 0, got %d", unit.PlayerIndex)
	}
	if unit.Position.Row != 2 || unit.Position.Col != 3 {
		t.Errorf("Expected position (2,3), got (%d,%d)", unit.Position.Row, unit.Position.Col)
	}
	if unit.Attack != 5 {
		t.Errorf("Expected Attack to be 5, got %d", unit.Attack)
	}
	if unit.Health != 10 {
		t.Errorf("Expected Health to be 10, got %d", unit.Health)
	}
	if unit.MaxHealth != 10 {
		t.Errorf("Expected MaxHealth to be 10, got %d", unit.MaxHealth)
	}
	if unit.Armor != 2 {
		t.Errorf("Expected Armor to be 2, got %d", unit.Armor)
	}
	if unit.Speed != 3 {
		t.Errorf("Expected Speed to be 3, got %d", unit.Speed)
	}
	if unit.Range != 1 {
		t.Errorf("Expected Range to be 1, got %d", unit.Range)
	}
	if !unit.IsAlive {
		t.Error("Expected unit to be alive")
	}
	if unit.HasMoved {
		t.Error("Expected unit to not have moved yet")
	}
	if unit.HasAttacked {
		t.Error("Expected unit to not have attacked yet")
	}
	if unit.TurnSpawned != 1 {
		t.Errorf("Expected TurnSpawned to be 1, got %d", unit.TurnSpawned)
	}

	// Check initial direction based on player
	if unit.Direction != DirectionNorth {
		t.Errorf("Expected player 0 unit to face North, got %s", unit.Direction)
	}

	// Create unit for player 1
	unit2 := NewUnit("goblin_archer", 1, Point{Row: 7, Col: 5}, stats, 2)
	if unit2.Direction != DirectionSouth {
		t.Errorf("Expected player 1 unit to face South, got %s", unit2.Direction)
	}
}

// Test spawning unit on game state
func TestGameStateSpawnUnit(t *testing.T) {
	gs := &GameState{
		ID:        "test-game",
		Status:    GameStatusInProgress,
		TurnCount: 3,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	stats := &UnitStats{
		Attack: 4,
		Health: 8,
		Armor:  1,
		Speed:  2,
		Range:  1,
	}

	// Spawn first unit
	unit1 := gs.SpawnUnit("skeleton_warrior", 0, Point{Row: 3, Col: 4}, stats)

	// Verify unit was added to game state
	if len(gs.Units) != 1 {
		t.Errorf("Expected 1 unit in game state, got %d", len(gs.Units))
	}

	// Verify unit properties
	if unit1.CardID != "skeleton_warrior" {
		t.Errorf("Expected CardID to be 'skeleton_warrior', got %s", unit1.CardID)
	}
	if unit1.PlayerIndex != 0 {
		t.Errorf("Expected PlayerIndex to be 0, got %d", unit1.PlayerIndex)
	}
	if unit1.TurnSpawned != 3 {
		t.Errorf("Expected TurnSpawned to be 3, got %d", unit1.TurnSpawned)
	}

	// Spawn second unit
	stats2 := &UnitStats{
		Attack: 6,
		Health: 12,
		Armor:  2,
		Speed:  1,
		Range:  2,
	}
	unit2 := gs.SpawnUnit("orc_berserker", 1, Point{Row: 6, Col: 2}, stats2)

	// Verify second unit was added
	if len(gs.Units) != 2 {
		t.Errorf("Expected 2 units in game state, got %d", len(gs.Units))
	}

	// Verify second unit properties
	if unit2.Attack != 6 {
		t.Errorf("Expected Attack to be 6, got %d", unit2.Attack)
	}
	if unit2.Health != 12 {
		t.Errorf("Expected Health to be 12, got %d", unit2.Health)
	}
	if unit2.Range != 2 {
		t.Errorf("Expected Range to be 2, got %d", unit2.Range)
	}
}

// Test spawning multiple units at different positions
func TestMultipleUnitSpawning(t *testing.T) {
	gs := &GameState{
		ID:        "test-game-multi",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	// Different stats for variety
	stats1 := &UnitStats{Attack: 3, Health: 5, Armor: 0, Speed: 2, Range: 1}
	stats2 := &UnitStats{Attack: 2, Health: 3, Armor: 1, Speed: 3, Range: 1}
	stats3 := &UnitStats{Attack: 4, Health: 6, Armor: 0, Speed: 1, Range: 3}

	// Spawn units at different positions
	positions := []Point{
		{Row: 1, Col: 1},
		{Row: 1, Col: 3},
		{Row: 2, Col: 2},
		{Row: 5, Col: 4},
		{Row: 7, Col: 7},
	}

	gs.SpawnUnit("unit1", 0, positions[0], stats1)
	gs.SpawnUnit("unit2", 0, positions[1], stats2)
	gs.SpawnUnit("unit3", 0, positions[2], stats3)
	gs.SpawnUnit("unit4", 1, positions[3], stats1)
	gs.SpawnUnit("unit5", 1, positions[4], stats2)

	// Verify all units were spawned
	if len(gs.Units) != 5 {
		t.Errorf("Expected 5 units, got %d", len(gs.Units))
	}

	// Check that each unit has unique position
	positionMap := make(map[Point]bool)
	for _, unit := range gs.Units {
		if positionMap[unit.Position] {
			t.Errorf("Duplicate unit position found at (%d,%d)", unit.Position.Row, unit.Position.Col)
		}
		positionMap[unit.Position] = true
	}

	// Verify player distribution
	player0Count := 0
	player1Count := 0
	for _, unit := range gs.Units {
		if unit.PlayerIndex == 0 {
			player0Count++
		} else if unit.PlayerIndex == 1 {
			player1Count++
		}
	}
	if player0Count != 3 {
		t.Errorf("Expected 3 units for player 0, got %d", player0Count)
	}
	if player1Count != 2 {
		t.Errorf("Expected 2 units for player 1, got %d", player1Count)
	}
}

// Test checking for units at position
func TestGetUnitAt(t *testing.T) {
	gs := &GameState{
		ID:        "test-game-position",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	stats := &UnitStats{Attack: 3, Health: 5, Armor: 1, Speed: 2, Range: 1}

	// Spawn units
	unit1 := gs.SpawnUnit("unit1", 0, Point{Row: 2, Col: 3}, stats)
	unit2 := gs.SpawnUnit("unit2", 1, Point{Row: 4, Col: 5}, stats)
	gs.SpawnUnit("unit3", 0, Point{Row: 6, Col: 7}, stats)

	// Test GetUnitAt for existing units
	foundUnit := gs.GetUnitAt(Point{Row: 2, Col: 3})
	if foundUnit == nil {
		t.Error("Expected to find unit at (2,3)")
	}
	if foundUnit != nil && foundUnit.ID != unit1.ID {
		t.Errorf("Expected unit ID %s, got %s", unit1.ID, foundUnit.ID)
	}

	foundUnit = gs.GetUnitAt(Point{Row: 4, Col: 5})
	if foundUnit == nil {
		t.Error("Expected to find unit at (4,5)")
	}
	if foundUnit != nil && foundUnit.ID != unit2.ID {
		t.Errorf("Expected unit ID %s, got %s", unit2.ID, foundUnit.ID)
	}

	// Test GetUnitAt for empty position
	foundUnit = gs.GetUnitAt(Point{Row: 3, Col: 3})
	if foundUnit != nil {
		t.Error("Expected no unit at (3,3)")
	}

	// Kill a unit and verify it's not returned by GetUnitAt
	unit1.IsAlive = false
	foundUnit = gs.GetUnitAt(Point{Row: 2, Col: 3})
	if foundUnit != nil {
		t.Error("Expected no alive unit at (2,3) after unit death")
	}
}

// Test spawning with invalid or edge case stats
func TestSpawnUnitEdgeCases(t *testing.T) {
	gs := &GameState{
		ID:        "test-edge-cases",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	// Test with zero stats
	zeroStats := &UnitStats{Attack: 0, Health: 0, Armor: 0, Speed: 0, Range: 0}
	unit := gs.SpawnUnit("zero_unit", 0, Point{Row: 0, Col: 0}, zeroStats)
	if unit.Health != 0 {
		t.Errorf("Expected Health to be 0, got %d", unit.Health)
	}
	// Unit with 0 health should still be marked as alive initially
	// (the game logic should handle this separately)
	if !unit.IsAlive {
		t.Error("Expected unit to be marked as alive initially even with 0 health")
	}

	// Test with very large stats
	largeStats := &UnitStats{Attack: 999, Health: 999, Armor: 999, Speed: 999, Range: 999}
	largeUnit := gs.SpawnUnit("large_unit", 1, Point{Row: 1, Col: 1}, largeStats)
	if largeUnit.Attack != 999 {
		t.Errorf("Expected Attack to be 999, got %d", largeUnit.Attack)
	}
	if largeUnit.Health != 999 {
		t.Errorf("Expected Health to be 999, got %d", largeUnit.Health)
	}

	// Test spawning at board boundaries
	boundaryPositions := []Point{
		{Row: 0, Col: 0}, // Top-left corner
		{Row: 0, Col: 9}, // Top-right corner (assuming 10 columns)
		{Row: 9, Col: 0}, // Bottom-left corner (assuming 10 rows)
		{Row: 9, Col: 9}, // Bottom-right corner
	}

	for _, pos := range boundaryPositions {
		stats := &UnitStats{Attack: 1, Health: 1, Armor: 0, Speed: 1, Range: 1}
		boundaryUnit := gs.SpawnUnit("boundary_unit", 0, pos, stats)
		if boundaryUnit.Position.Row != pos.Row || boundaryUnit.Position.Col != pos.Col {
			t.Errorf("Expected position (%d,%d), got (%d,%d)",
				pos.Row, pos.Col, boundaryUnit.Position.Row, boundaryUnit.Position.Col)
		}
	}
}

// Test spawning units during resolution phase (integration test)
func TestSpawnUnitDuringResolution(t *testing.T) {
	// Setup game state with planned plays
	gs := &GameState{
		ID:           "test-resolution",
		Status:       GameStatusInProgress,
		TurnCount:    2,
		CurrentPhase: PhaseRevealResolve,
		Units:        []*Unit{},
		PlayerStates: []PlayerBattleState{
			{
				PlayerIndex: 0,
				Resources:   Resources{Gold: 10, Mana: 10},
			},
			{
				PlayerIndex: 1,
				Resources:   Resources{Gold: 10, Mana: 10},
			},
		},
		PlannedPlays: map[int][]PlannedPlay{
			0: {
				{
					PlayerIndex:  0,
					CardInstance: "inst-1",
					CardID:       "goblin_warrior",
					Position:     Point{Row: 3, Col: 3},
				},
			},
			1: {
				{
					PlayerIndex:  1,
					CardInstance: "inst-2",
					CardID:       "skeleton_archer",
					Position:     Point{Row: 6, Col: 6},
				},
			},
		},
		UpdatedAt: time.Now(),
	}

	// Setup mock card repository
	cardRepo := NewMockCardRepository()
	cardRepo.AddCard(&Card{
		ID:   "goblin_warrior",
		Type: CardTypeUnit,
		UnitStats: &UnitStats{
			Attack: 3,
			Health: 5,
			Armor:  1,
			Speed:  2,
			Range:  1,
		},
	})
	cardRepo.AddCard(&Card{
		ID:   "skeleton_archer",
		Type: CardTypeUnit,
		UnitStats: &UnitStats{
			Attack: 2,
			Health: 3,
			Armor:  0,
			Speed:  1,
			Range:  3,
		},
	})

	// Process planned plays (simplified version of what happens in resolution)
	for _, playerPlays := range gs.PlannedPlays {
		for _, play := range playerPlays {
			card, err := cardRepo.GetCard(nil, play.CardID)
			if err != nil {
				t.Errorf("Error getting card: %v", err)
				continue
			}
			if card != nil && card.IsUnit() && card.UnitStats != nil {
				gs.SpawnUnit(play.CardID, play.PlayerIndex, play.Position, card.UnitStats)
			}
		}
	}

	// Verify units were spawned correctly
	if len(gs.Units) != 2 {
		t.Errorf("Expected 2 units spawned, got %d", len(gs.Units))
	}

	// Verify first unit (goblin warrior)
	goblinFound := false
	for _, unit := range gs.Units {
		if unit.CardID == "goblin_warrior" {
			goblinFound = true
			if unit.PlayerIndex != 0 {
				t.Errorf("Goblin warrior should belong to player 0, got player %d", unit.PlayerIndex)
			}
			if unit.Position.Row != 3 || unit.Position.Col != 3 {
				t.Errorf("Goblin warrior should be at (3,3), got (%d,%d)",
					unit.Position.Row, unit.Position.Col)
			}
			if unit.Attack != 3 || unit.Health != 5 {
				t.Errorf("Goblin warrior stats incorrect: Attack=%d, Health=%d",
					unit.Attack, unit.Health)
			}
		}
	}
	if !goblinFound {
		t.Error("Goblin warrior not found in spawned units")
	}

	// Verify second unit (skeleton archer)
	skeletonFound := false
	for _, unit := range gs.Units {
		if unit.CardID == "skeleton_archer" {
			skeletonFound = true
			if unit.PlayerIndex != 1 {
				t.Errorf("Skeleton archer should belong to player 1, got player %d", unit.PlayerIndex)
			}
			if unit.Position.Row != 6 || unit.Position.Col != 6 {
				t.Errorf("Skeleton archer should be at (6,6), got (%d,%d)",
					unit.Position.Row, unit.Position.Col)
			}
			if unit.Range != 3 {
				t.Errorf("Skeleton archer should have range 3, got %d", unit.Range)
			}
		}
	}
	if !skeletonFound {
		t.Error("Skeleton archer not found in spawned units")
	}
}

// Test blocked spawning (when position is occupied)
func TestBlockedSpawning(t *testing.T) {
	gs := &GameState{
		ID:        "test-blocked",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	stats := &UnitStats{Attack: 3, Health: 5, Armor: 1, Speed: 2, Range: 1}

	// Spawn first unit at position (3,3)
	unit1 := gs.SpawnUnit("unit1", 0, Point{Row: 3, Col: 3}, stats)

	// Attempt to spawn another unit at the same position
	// (This would normally be prevented by game logic, but we test the state)
	unit2 := gs.SpawnUnit("unit2", 1, Point{Row: 3, Col: 3}, stats)

	// Both units should exist in the units array
	if len(gs.Units) != 2 {
		t.Errorf("Expected 2 units in array, got %d", len(gs.Units))
	}

	// Both should have the same position (testing the data structure, not game logic)
	if unit1.Position.Row != unit2.Position.Row || unit1.Position.Col != unit2.Position.Col {
		t.Error("Units should have same position in this test")
	}

	// GetUnitAt should return the first alive unit at that position
	foundUnit := gs.GetUnitAt(Point{Row: 3, Col: 3})
	if foundUnit == nil {
		t.Error("Expected to find a unit at (3,3)")
	}
	// It should return the first unit found (implementation dependent)
	if foundUnit != nil && foundUnit.ID != unit1.ID && foundUnit.ID != unit2.ID {
		t.Error("Found unit should be one of the spawned units")
	}
}

// Test unique unit ID generation
func TestUniqueUnitIDs(t *testing.T) {
	stats := &UnitStats{Attack: 1, Health: 1, Armor: 0, Speed: 1, Range: 1}

	// Create multiple units rapidly
	unitIDs := make(map[UnitID]bool)
	for i := 0; i < 100; i++ {
		unit := NewUnit("test_unit", i%2, Point{Row: i / 10, Col: i % 10}, stats, 1)
		if unitIDs[unit.ID] {
			t.Errorf("Duplicate unit ID generated: %s", unit.ID)
		}
		unitIDs[unit.ID] = true

		// Small delay to ensure different timestamps
		time.Sleep(time.Nanosecond)
	}

	if len(unitIDs) != 100 {
		t.Errorf("Expected 100 unique IDs, got %d", len(unitIDs))
	}
}

// Test turn spawned tracking
func TestTurnSpawnedTracking(t *testing.T) {
	gs := &GameState{
		ID:        "test-turn-tracking",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	stats := &UnitStats{Attack: 2, Health: 4, Armor: 0, Speed: 2, Range: 1}

	// Spawn unit in turn 1
	unit1 := gs.SpawnUnit("unit1", 0, Point{Row: 1, Col: 1}, stats)
	if unit1.TurnSpawned != 1 {
		t.Errorf("Unit spawned in turn 1 should have TurnSpawned=1, got %d", unit1.TurnSpawned)
	}

	// Advance turn
	gs.TurnCount = 5

	// Spawn unit in turn 5
	unit2 := gs.SpawnUnit("unit2", 0, Point{Row: 2, Col: 2}, stats)
	if unit2.TurnSpawned != 5 {
		t.Errorf("Unit spawned in turn 5 should have TurnSpawned=5, got %d", unit2.TurnSpawned)
	}

	// Verify first unit still has original turn
	if unit1.TurnSpawned != 1 {
		t.Errorf("First unit should still have TurnSpawned=1, got %d", unit1.TurnSpawned)
	}
}

// Test spawning with nil stats (error case)
func TestSpawnUnitWithNilStats(t *testing.T) {
	gs := &GameState{
		ID:        "test-nil-stats",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	// Spawn unit with nil stats should not panic
	defer func() {
		if r := recover(); r != nil {
			t.Errorf("SpawnUnit panicked with nil stats: %v", r)
		}
	}()

	unit := gs.SpawnUnit("nil_unit", 0, Point{Row: 1, Col: 1}, nil)

	// Unit should still be created but with zero stats
	if unit == nil {
		t.Error("Expected unit to be created even with nil stats")
	}

	if len(gs.Units) != 1 {
		t.Errorf("Expected 1 unit in game state, got %d", len(gs.Units))
	}
}

// Test concurrent spawning (simulate race conditions)
func TestConcurrentUnitSpawning(t *testing.T) {
	gs := &GameState{
		ID:        "test-concurrent",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	stats := &UnitStats{Attack: 3, Health: 5, Armor: 1, Speed: 2, Range: 1}

	// Spawn multiple units concurrently
	numGoroutines := 10
	done := make(chan bool, numGoroutines)

	for i := 0; i < numGoroutines; i++ {
		go func(index int) {
			gs.SpawnUnit(CardID("unit_"+string(rune(index))), index%2, Point{Row: index / 2, Col: index % 5}, stats)
			done <- true
		}(i)
	}

	// Wait for all goroutines to complete
	for i := 0; i < numGoroutines; i++ {
		<-done
	}

	// Verify all units were spawned
	if len(gs.Units) != numGoroutines {
		t.Errorf("Expected %d units, got %d", numGoroutines, len(gs.Units))
	}

	// Check all units are valid
	for _, unit := range gs.Units {
		if unit == nil {
			t.Error("Found nil unit in units array")
		}
		if unit != nil && !unit.IsAlive {
			t.Error("Found dead unit that should be alive")
		}
	}
}

// Test mass unit spawning performance
func TestMassUnitSpawning(t *testing.T) {
	gs := &GameState{
		ID:        "test-mass-spawn",
		Status:    GameStatusInProgress,
		TurnCount: 1,
		Units:     []*Unit{},
		UpdatedAt: time.Now(),
	}

	stats := &UnitStats{Attack: 1, Health: 1, Armor: 0, Speed: 1, Range: 1}

	// Spawn a large number of units
	numUnits := 1000
	startTime := time.Now()

	for i := 0; i < numUnits; i++ {
		row := i / 100
		col := i % 100
		gs.SpawnUnit(CardID("mass_unit"), i%2, Point{Row: row, Col: col}, stats)
	}

	elapsed := time.Since(startTime)

	// Verify all units were spawned
	if len(gs.Units) != numUnits {
		t.Errorf("Expected %d units, got %d", numUnits, len(gs.Units))
	}

	// Check performance (should be reasonably fast)
	if elapsed > 1*time.Second {
		t.Logf("Warning: Mass spawning %d units took %v (might be slow)", numUnits, elapsed)
	}
}

// Test unit damage mechanics
func TestUnitTakeDamage(t *testing.T) {
	stats := &UnitStats{
		Attack: 5,
		Health: 20,
		Armor:  3,
		Speed:  2,
		Range:  1,
	}

	unit := NewUnit("test_unit", 0, Point{Row: 1, Col: 1}, stats, 1)

	// Test normal damage
	unit.TakeDamage(5)
	if unit.Health != 18 { // 5 damage - 3 armor = 2 actual damage
		t.Errorf("Expected health to be 18 after 5 damage with 3 armor, got %d", unit.Health)
	}
	if !unit.IsAlive {
		t.Error("Unit should still be alive")
	}

	// Test damage less than armor
	unit.TakeDamage(2)
	if unit.Health != 18 { // No damage should be taken (2 < 3 armor)
		t.Errorf("Expected health to remain 18 after 2 damage with 3 armor, got %d", unit.Health)
	}

	// Test lethal damage
	unit.TakeDamage(25) // 25 - 3 = 22 damage, should kill the unit
	if unit.Health != 0 {
		t.Errorf("Expected health to be 0 after lethal damage, got %d", unit.Health)
	}
	if unit.IsAlive {
		t.Error("Unit should be dead after lethal damage")
	}

	// Test damage on dead unit (should do nothing)
	unit.TakeDamage(10)
	if unit.Health != 0 {
		t.Errorf("Dead unit's health should remain 0, got %d", unit.Health)
	}
}

// Test unit attack mechanics
func TestUnitCanAttack(t *testing.T) {
	stats := &UnitStats{
		Attack: 4,
		Health: 10,
		Armor:  1,
		Speed:  2,
		Range:  2, // Range 2 unit
	}

	unit := NewUnit("ranged_unit", 0, Point{Row: 3, Col: 3}, stats, 1)

	// Test attack within range
	if !unit.CanAttack(Point{Row: 3, Col: 5}) { // Distance = 2, within range
		t.Error("Unit should be able to attack target at distance 2 with range 2")
	}

	if !unit.CanAttack(Point{Row: 4, Col: 3}) { // Distance = 1, within range
		t.Error("Unit should be able to attack target at distance 1 with range 2")
	}

	// Test attack out of range
	if unit.CanAttack(Point{Row: 3, Col: 6}) { // Distance = 3, out of range
		t.Error("Unit should not be able to attack target at distance 3 with range 2")
	}

	if unit.CanAttack(Point{Row: 6, Col: 6}) { // Distance = 6, out of range
		t.Error("Unit should not be able to attack target at distance 6 with range 2")
	}

	// Test after attacking
	unit.PerformAttack()
	if unit.CanAttack(Point{Row: 3, Col: 4}) { // Within range but already attacked
		t.Error("Unit should not be able to attack after already attacking")
	}

	// Test dead unit can't attack
	unit.IsAlive = false
	unit.HasAttacked = false // Reset attack flag
	if unit.CanAttack(Point{Row: 3, Col: 4}) {
		t.Error("Dead unit should not be able to attack")
	}
}

// Test unit movement mechanics
func TestUnitMovement(t *testing.T) {
	stats := &UnitStats{
		Attack: 3,
		Health: 8,
		Armor:  1,
		Speed:  3,
		Range:  1,
	}

	unit := NewUnit("mobile_unit", 0, Point{Row: 5, Col: 5}, stats, 1)

	// Test basic movement
	unit.Move(Point{Row: 5, Col: 6})
	if unit.Position.Row != 5 || unit.Position.Col != 6 {
		t.Errorf("Expected unit at (5,6), got (%d,%d)", unit.Position.Row, unit.Position.Col)
	}
	if !unit.HasMoved {
		t.Error("Unit should be marked as HasMoved after moving")
	}

	// Test IsAt function
	if !unit.IsAt(Point{Row: 5, Col: 6}) {
		t.Error("IsAt should return true for unit's current position")
	}
	if unit.IsAt(Point{Row: 5, Col: 5}) {
		t.Error("IsAt should return false for unit's old position")
	}

	// Test movement when dead
	unit.IsAlive = false
	oldPos := unit.Position
	unit.Move(Point{Row: 7, Col: 7})
	if unit.Position != oldPos {
		t.Error("Dead unit should not move")
	}
}

// Test unit pathfinding
func TestUnitGetNextPosition(t *testing.T) {
	stats := &UnitStats{
		Attack: 2,
		Health: 5,
		Armor:  0,
		Speed:  2,
		Range:  1,
	}

	unit := NewUnit("pathfinder", 0, Point{Row: 2, Col: 2}, stats, 1)
	boardRows := 10
	boardCols := 10
	occupiedTiles := make(map[Point]bool)
	enemyCommandCenter := Point{Row: 8, Col: 8}

	// Test movement towards enemy command center
	nextPos := unit.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter)
	// Unit should move towards (8,8) from (2,2) - should move up and/or right
	if nextPos.Row <= unit.Position.Row && nextPos.Col <= unit.Position.Col {
		t.Errorf("Unit should move towards enemy command center. Started at (%d,%d), moved to (%d,%d)",
			unit.Position.Row, unit.Position.Col, nextPos.Row, nextPos.Col)
	}

	// Test movement with obstacles
	occupiedTiles[Point{Row: 3, Col: 2}] = true // Block vertical movement
	occupiedTiles[Point{Row: 2, Col: 3}] = true // Block horizontal movement
	nextPos = unit.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter)
	if nextPos != unit.Position {
		t.Errorf("Unit should not move when blocked. Position (%d,%d) should equal (%d,%d)",
			nextPos.Row, nextPos.Col, unit.Position.Row, unit.Position.Col)
	}

	// Test movement when already moved
	unit.HasMoved = true
	nextPos = unit.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter)
	if nextPos != unit.Position {
		t.Error("Unit that has already moved should not calculate new position")
	}

	// Test movement when dead
	unit.HasMoved = false
	unit.IsAlive = false
	nextPos = unit.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter)
	if nextPos != unit.Position {
		t.Error("Dead unit should not calculate new position")
	}

	// Test with custom target position
	unit.IsAlive = true
	customTarget := Point{Row: 0, Col: 0}
	unit.TargetPosition = &customTarget
	occupiedTiles = make(map[Point]bool) // Clear obstacles
	nextPos = unit.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter)
	// Should move towards (0,0) not (8,8)
	// Unit is at (2,2) and should move towards (0,0), so row and/or col should decrease
	if nextPos.Row > unit.Position.Row || nextPos.Col > unit.Position.Col {
		t.Errorf("Unit should move towards custom target (0,0) not enemy center. Started at (%d,%d), moved to (%d,%d)",
			unit.Position.Row, unit.Position.Col, nextPos.Row, nextPos.Col)
	}
}

// Test unit turn state reset
func TestUnitResetTurnState(t *testing.T) {
	stats := &UnitStats{
		Attack: 3,
		Health: 7,
		Armor:  1,
		Speed:  2,
		Range:  1,
	}

	unit := NewUnit("test_unit", 0, Point{Row: 1, Col: 1}, stats, 1)

	// Set unit as having moved and attacked
	unit.HasMoved = true
	unit.HasAttacked = true

	// Reset turn state
	unit.ResetTurnState()

	if unit.HasMoved {
		t.Error("HasMoved should be false after reset")
	}
	if unit.HasAttacked {
		t.Error("HasAttacked should be false after reset")
	}
}

// Test unit with zero speed
func TestUnitZeroSpeed(t *testing.T) {
	stats := &UnitStats{
		Attack: 5,
		Health: 10,
		Armor:  2,
		Speed:  0, // Zero speed unit
		Range:  1,
	}

	unit := NewUnit("immobile_unit", 0, Point{Row: 3, Col: 3}, stats, 1)
	boardRows := 10
	boardCols := 10
	occupiedTiles := make(map[Point]bool)
	enemyCommandCenter := Point{Row: 8, Col: 8}

	// Test that zero speed unit doesn't move
	nextPos := unit.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter)
	if nextPos != unit.Position {
		t.Errorf("Unit with zero speed should not move. Expected (%d,%d), got (%d,%d)",
			unit.Position.Row, unit.Position.Col, nextPos.Row, nextPos.Col)
	}
}

// Test boundary movement
func TestUnitBoundaryMovement(t *testing.T) {
	stats := &UnitStats{
		Attack: 2,
		Health: 5,
		Armor:  0,
		Speed:  5, // High speed to test boundary checks
		Range:  1,
	}

	boardRows := 10
	boardCols := 10
	occupiedTiles := make(map[Point]bool)

	// Test unit at top-left corner trying to move out of bounds
	unit := NewUnit("corner_unit", 0, Point{Row: 0, Col: 0}, stats, 1)
	enemyCommandCenter := Point{Row: -5, Col: -5} // Target out of bounds

	nextPos := unit.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter)
	if nextPos.Row < 0 || nextPos.Col < 0 ||
		nextPos.Row >= boardRows || nextPos.Col >= boardCols {
		t.Errorf("Unit moved out of bounds: (%d,%d)", nextPos.Row, nextPos.Col)
	}

	// Test unit at bottom-right corner
	unit2 := NewUnit("corner_unit2", 1, Point{Row: 9, Col: 9}, stats, 1)
	enemyCommandCenter2 := Point{Row: 15, Col: 15} // Target out of bounds

	nextPos2 := unit2.GetNextPosition(boardRows, boardCols, occupiedTiles, enemyCommandCenter2)
	if nextPos2.Row < 0 || nextPos2.Col < 0 ||
		nextPos2.Row >= boardRows || nextPos2.Col >= boardCols {
		t.Errorf("Unit moved out of bounds: (%d,%d)", nextPos2.Row, nextPos2.Col)
	}
}
