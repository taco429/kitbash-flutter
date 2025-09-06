package domain

import (
	"context"
	"fmt"
	"time"
)

// RoundManager handles the execution of game rounds and phases
type RoundManager struct {
	cardRepo CardRepository
}

// NewRoundManager creates a new round manager
func NewRoundManager(cardRepo CardRepository) *RoundManager {
	return &RoundManager{
		cardRepo: cardRepo,
	}
}

// ExecuteRound processes a complete round (all three phases)
func (rm *RoundManager) ExecuteRound(ctx context.Context, gameState *GameState) (*EventLog, error) {
	eventLog := NewEventLog()
	
	// Phase 1: Upkeep
	if err := rm.ExecuteUpkeepPhase(ctx, gameState, eventLog); err != nil {
		return eventLog, fmt.Errorf("upkeep phase failed: %w", err)
	}
	
	// Phase 2: Decision (handled by game hub - wait for player actions)
	// This phase is managed externally by the WebSocket handler
	
	// Phase 3: Resolution (called after both players submit actions)
	// This will be called separately when actions are ready
	
	return eventLog, nil
}

// ExecuteUpkeepPhase handles the automatic upkeep phase
func (rm *RoundManager) ExecuteUpkeepPhase(ctx context.Context, gameState *GameState, eventLog *EventLog) error {
	eventLog.AddPhaseStartEvent(PhaseUpkeep)
	
	// 1. Resolve "Start of Upkeep" Triggers
	if err := rm.resolveUpkeepTriggers(ctx, gameState, eventLog); err != nil {
		return err
	}
	
	// 2. Generate Resources
	for i := range gameState.PlayerStates {
		playerState := &gameState.PlayerStates[i]
		
		// Add gold income
		oldGold := playerState.Gold
		playerState.Gold += playerState.GoldIncome
		if playerState.Gold > playerState.MaxGold {
			playerState.Gold = playerState.MaxGold
		}
		if playerState.Gold > oldGold {
			eventLog.AddResourceGainEvent(i, "gold", playerState.Gold-oldGold)
		}
		
		// Refill mana to maximum
		oldMana := playerState.Mana
		playerState.Mana = playerState.MaxMana
		if playerState.Mana > oldMana {
			eventLog.AddResourceGainEvent(i, "mana", playerState.Mana-oldMana)
		}
	}
	
	// 3. Draw Cards
	for i := range gameState.PlayerStates {
		playerState := &gameState.PlayerStates[i]
		
		// Draw cards for turn
		drawnCards := gameState.DrawCards(i, playerState.DrawPerTurn)
		for _, cardID := range drawnCards {
			eventLog.AddCardDrawnEvent(i, cardID)
		}
		
		// Refill hand to hand limit if below
		refilledCards := gameState.RefillHand(i)
		for _, cardID := range refilledCards {
			eventLog.AddCardDrawnEvent(i, cardID)
		}
	}
	
	// 4. Update Turn Counters
	if err := rm.updateTurnCounters(ctx, gameState, eventLog); err != nil {
		return err
	}
	
	// 5. Reset unit movement and attacks
	if gameState.BoardState != nil {
		for _, unit := range gameState.BoardState.Units {
			unit.ResetMovement()
		}
	}
	
	eventLog.AddPhaseEndEvent(PhaseUpkeep)
	gameState.SetPhase(PhaseDecision)
	
	return nil
}

// ExecuteDecisionPhase handles waiting for player actions
func (rm *RoundManager) ExecuteDecisionPhase(ctx context.Context, gameState *GameState, timeout time.Duration) (*EventLog, error) {
	eventLog := NewEventLog()
	eventLog.AddPhaseStartEvent(PhaseDecision)
	
	// This phase primarily waits for player input
	// The actual waiting logic is handled by the WebSocket handler
	// This method just sets up the phase
	
	gameState.SetPhase(PhaseDecision)
	
	// Clear any previous player actions
	gameState.ClearPlayerActions()
	
	eventLog.AddPhaseEndEvent(PhaseDecision)
	
	return eventLog, nil
}

// ExecuteResolutionPhase processes all player actions in the correct order
func (rm *RoundManager) ExecuteResolutionPhase(ctx context.Context, gameState *GameState) (*EventLog, error) {
	eventLog := NewEventLog()
	eventLog.AddPhaseStartEvent(PhaseResolution)
	
	// Get player actions
	player1Actions := gameState.GetPlayerActions(0)
	player2Actions := gameState.GetPlayerActions(1)
	
	// Combine all actions
	allActions := ActionQueue{}
	if player1Actions != nil {
		allActions = append(allActions, player1Actions.Actions...)
	}
	if player2Actions != nil {
		allActions = append(allActions, player2Actions.Actions...)
	}
	
	// Process actions in the strict sequence
	
	// 1. Fast Speed Step
	if err := rm.processSpeedStep(ctx, gameState, allActions, SpeedFast, eventLog); err != nil {
		return eventLog, err
	}
	
	// 2. Movement Step
	if err := rm.processMovementStep(ctx, gameState, allActions, eventLog); err != nil {
		return eventLog, err
	}
	
	// 3. Normal Speed Step
	if err := rm.processSpeedStep(ctx, gameState, allActions, SpeedNormal, eventLog); err != nil {
		return eventLog, err
	}
	
	// 4. Combat Step
	if err := rm.processCombatStep(ctx, gameState, allActions, eventLog); err != nil {
		return eventLog, err
	}
	
	// 5. Slow Speed Step
	if err := rm.processSpeedStep(ctx, gameState, allActions, SpeedSlow, eventLog); err != nil {
		return eventLog, err
	}
	
	// 6. End of Round Cleanup
	if err := rm.processCleanup(ctx, gameState, eventLog); err != nil {
		return eventLog, err
	}
	
	// Check win conditions
	if gameState.IsGameOver() {
		winner := gameState.GetWinner()
		if winner >= 0 {
			eventLog.AddEvent(GameEvent{
				Type:        EventGameWon,
				PlayerIndex: &winner,
				Message:     fmt.Sprintf("Player %d wins!", winner),
			})
		}
	}
	
	eventLog.AddPhaseEndEvent(PhaseResolution)
	
	// Store the event log in game state
	gameState.LastEventLog = eventLog
	
	// Clear player actions for next round
	gameState.ClearPlayerActions()
	
	// Advance turn counter
	gameState.AdvanceTurn()
	
	return eventLog, nil
}

// processSpeedStep processes all actions of a given speed
func (rm *RoundManager) processSpeedStep(ctx context.Context, gameState *GameState, actions ActionQueue, speed SpeedType, eventLog *EventLog) error {
	speedActions := actions.GetActionsBySpeed(speed)
	if len(speedActions) == 0 {
		return nil
	}
	
	// Universal Rule: Movement -> Damage -> Other Effects
	
	// 1. Movement components
	movements := []Action{}
	for _, action := range speedActions {
		if action.Type == ActionTypeMoveUnit {
			movements = append(movements, action)
		}
	}
	if err := rm.processMovements(ctx, gameState, movements, eventLog); err != nil {
		return err
	}
	
	// 2. Damage components (for spells/abilities with damage)
	damages := []Action{}
	for _, action := range speedActions {
		if action.Type == ActionTypeAbility || (action.Type == ActionTypePlayCard && rm.isDirectDamageCard(ctx, action.CardInHandID)) {
			damages = append(damages, action)
		}
	}
	if err := rm.processDamages(ctx, gameState, damages, eventLog); err != nil {
		return err
	}
	
	// 3. Other effects (card plays, non-damage abilities)
	others := []Action{}
	for _, action := range speedActions {
		if action.Type == ActionTypePlayCard && !rm.isDirectDamageCard(ctx, action.CardInHandID) {
			others = append(others, action)
		}
	}
	if err := rm.processOtherEffects(ctx, gameState, others, eventLog); err != nil {
		return err
	}
	
	return nil
}

// processMovementStep handles all movement actions with collision detection
func (rm *RoundManager) processMovementStep(ctx context.Context, gameState *GameState, actions ActionQueue, eventLog *EventLog) error {
	movements := actions.GetMovementActions()
	if len(movements) == 0 {
		return nil
	}
	
	// Group movements by destination
	destinationMap := make(map[string][]Action)
	for _, move := range movements {
		if move.Position != nil {
			key := fmt.Sprintf("%d,%d", move.Position.Row, move.Position.Col)
			destinationMap[key] = append(destinationMap[key], move)
		}
	}
	
	// Cancel movements with collisions
	cancelledMoves := make(map[string]bool)
	for dest, moves := range destinationMap {
		if len(moves) > 1 {
			// Multiple units trying to move to same position - cancel all
			unitIDs := []string{}
			for _, move := range moves {
				cancelledMoves[move.SourceID] = true
				unitIDs = append(unitIDs, move.SourceID)
			}
			
			// Parse position from key
			var row, col int
			fmt.Sscanf(dest, "%d,%d", &row, &col)
			eventLog.AddMovementCancelledEvent(unitIDs, Point{Row: row, Col: col})
		}
	}
	
	// Process non-cancelled movements
	for _, move := range movements {
		if !cancelledMoves[move.SourceID] {
			if err := rm.processSingleMovement(ctx, gameState, move, eventLog); err != nil {
				return err
			}
		}
	}
	
	return nil
}

// processCombatStep handles all combat with simultaneous damage
func (rm *RoundManager) processCombatStep(ctx context.Context, gameState *GameState, actions ActionQueue, eventLog *EventLog) error {
	attacks := actions.GetAttackActions()
	if len(attacks) == 0 {
		return nil
	}
	
	eventLog.AddEvent(GameEvent{
		Type:    EventCombatStart,
		Message: "Combat phase begins",
	})
	
	// Calculate all damage based on current state
	type combatDamage struct {
		attackerID string
		targetID   string
		damage     int
	}
	
	damages := []combatDamage{}
	
	for _, attack := range attacks {
		if gameState.BoardState == nil {
			continue
		}
		
		// Find attacker unit
		attackerUnit, exists := gameState.BoardState.Units[UnitID(attack.SourceID)]
		if !exists || !attackerUnit.CanAttack {
			continue
		}
		
		// Find target
		var targetArmor int
		
		if targetUnit, exists := gameState.BoardState.Units[UnitID(attack.TargetID)]; exists {
			if attackerUnit.CanAttackTarget(targetUnit.Position) {
				targetArmor = targetUnit.Armor
				damage := attackerUnit.Attack - targetArmor
				if damage > 0 {
					damages = append(damages, combatDamage{
						attackerID: attack.SourceID,
						targetID:   attack.TargetID,
						damage:     damage,
					})
				}
			}
		} else if targetBuilding, exists := gameState.BoardState.Buildings[attack.TargetID]; exists {
			if attackerUnit.CanAttackTarget(targetBuilding.Position) {
				targetArmor = targetBuilding.Armor
				damage := attackerUnit.Attack - targetArmor
				if damage > 0 {
					damages = append(damages, combatDamage{
						attackerID: attack.SourceID,
						targetID:   attack.TargetID,
						damage:     damage,
					})
				}
			}
		}
		
		// Mark unit as having attacked
		attackerUnit.CanAttack = false
	}
	
	// Apply all damage simultaneously
	for _, dmg := range damages {
		eventLog.AddCombatDamageEvent(dmg.attackerID, dmg.targetID, dmg.damage)
		
		// Apply damage to target
		if targetUnit, exists := gameState.BoardState.Units[UnitID(dmg.targetID)]; exists {
			if targetUnit.TakeDamage(dmg.damage) {
				// Unit destroyed
				gameState.BoardState.RemoveUnit(UnitID(dmg.targetID))
				eventLog.AddEvent(GameEvent{
					Type:     EventUnitDestroyed,
					SourceID: dmg.targetID,
					Message:  "Unit destroyed",
				})
			}
		} else if targetBuilding, exists := gameState.BoardState.Buildings[dmg.targetID]; exists {
			if targetBuilding.TakeDamage(dmg.damage) {
				// Building destroyed
				gameState.BoardState.RemoveBuilding(dmg.targetID)
				eventLog.AddEvent(GameEvent{
					Type:     EventBuildingDestroyed,
					SourceID: dmg.targetID,
					Message:  "Building destroyed",
				})
			}
		}
	}
	
	eventLog.AddEvent(GameEvent{
		Type:    EventCombatEnd,
		Message: "Combat phase ends",
	})
	
	return nil
}

// processCleanup handles end of round cleanup
func (rm *RoundManager) processCleanup(ctx context.Context, gameState *GameState, eventLog *EventLog) error {
	eventLog.AddEvent(GameEvent{
		Type:    EventRoundEnd,
		Message: "Round cleanup begins",
	})
	
	// Process any queued discards
	// (Discards were already handled when players locked their choices)
	
	// Reset mana to 0 for all players
	for i := range gameState.PlayerStates {
		playerState := &gameState.PlayerStates[i]
		if playerState.Mana > 0 {
			eventLog.AddEvent(GameEvent{
				Type:        EventManaReset,
				PlayerIndex: &i,
				Value:       playerState.Mana,
				Message:     fmt.Sprintf("Player %d's mana reset to 0", i),
			})
			playerState.Mana = 0
		}
	}
	
	// Trigger any "End of Round" effects
	if err := rm.resolveEndOfRoundTriggers(ctx, gameState, eventLog); err != nil {
		return err
	}
	
	// Check win/loss conditions
	for _, cc := range gameState.CommandCenters {
		if cc.IsDestroyed() {
			eventLog.AddEvent(GameEvent{
				Type:        EventCommandCenterDestroyed,
				PlayerIndex: &cc.PlayerIndex,
				Message:     fmt.Sprintf("Player %d's command center destroyed", cc.PlayerIndex),
			})
			gameState.Status = GameStatusFinished
		}
	}
	
	return nil
}

// Helper methods

func (rm *RoundManager) resolveUpkeepTriggers(ctx context.Context, gameState *GameState, eventLog *EventLog) error {
	// TODO: Implement upkeep triggers for units/buildings with "start of turn" abilities
	return nil
}

func (rm *RoundManager) updateTurnCounters(ctx context.Context, gameState *GameState, eventLog *EventLog) error {
	if gameState.BoardState == nil {
		return nil
	}
	
	// Update counters on units
	for _, unit := range gameState.BoardState.Units {
		for counter := range unit.Counters {
			unit.IncrementCounter(counter)
			eventLog.AddEvent(GameEvent{
				Type:     EventCounterUpdated,
				SourceID: string(unit.ID),
				Message:  fmt.Sprintf("Counter %s incremented", counter),
				Metadata: map[string]interface{}{
					"counter": counter,
					"value":   unit.GetCounter(counter),
				},
			})
		}
	}
	
	// Update counters on buildings
	for _, building := range gameState.BoardState.Buildings {
		for counter := range building.Counters {
			building.Counters[counter]++
			eventLog.AddEvent(GameEvent{
				Type:     EventCounterUpdated,
				SourceID: building.ID,
				Message:  fmt.Sprintf("Counter %s incremented", counter),
				Metadata: map[string]interface{}{
					"counter": counter,
					"value":   building.Counters[counter],
				},
			})
		}
	}
	
	return nil
}

func (rm *RoundManager) resolveEndOfRoundTriggers(ctx context.Context, gameState *GameState, eventLog *EventLog) error {
	// TODO: Implement end of round triggers
	return nil
}

func (rm *RoundManager) isDirectDamageCard(ctx context.Context, cardID CardID) bool {
	if rm.cardRepo == nil {
		return false
	}
	
	card, err := rm.cardRepo.GetCard(ctx, cardID)
	if err != nil || card == nil {
		return false
	}
	
	// Check if it's a direct damage spell
	if card.Type == CardTypeSpell && card.SpellEffect != nil {
		// Simple heuristic - check if effect contains "damage"
		// In a real implementation, you'd have more structured spell effects
		return card.SpellEffect.Effect == "damage" || card.SpellEffect.TargetType == "unit"
	}
	
	return false
}

func (rm *RoundManager) processMovements(ctx context.Context, gameState *GameState, movements []Action, eventLog *EventLog) error {
	for _, move := range movements {
		if err := rm.processSingleMovement(ctx, gameState, move, eventLog); err != nil {
			return err
		}
	}
	return nil
}

func (rm *RoundManager) processSingleMovement(ctx context.Context, gameState *GameState, move Action, eventLog *EventLog) error {
	if gameState.BoardState == nil || move.Position == nil {
		return nil
	}
	
	unit, exists := gameState.BoardState.Units[UnitID(move.SourceID)]
	if !exists {
		return nil
	}
	
	oldPos := unit.Position
	if unit.CanMoveTo(*move.Position) && !gameState.BoardState.IsPositionOccupied(*move.Position) {
		unit.MoveTo(*move.Position)
		eventLog.AddUnitMovedEvent(move.SourceID, oldPos, *move.Position)
	}
	
	return nil
}

func (rm *RoundManager) processDamages(ctx context.Context, gameState *GameState, damages []Action, eventLog *EventLog) error {
	// Process all damage-dealing actions simultaneously
	type pendingDamage struct {
		targetID string
		damage   int
		sourceID string
	}
	
	allDamages := []pendingDamage{}
	
	for _, action := range damages {
		// This would need to be expanded based on your card/ability system
		// For now, just a placeholder
		if action.Type == ActionTypeAbility {
			if value, ok := action.Metadata["damage"].(int); ok {
				allDamages = append(allDamages, pendingDamage{
					targetID: action.TargetID,
					damage:   value,
					sourceID: action.SourceID,
				})
			}
		}
	}
	
	// Apply all damages
	for _, dmg := range allDamages {
		// Apply to units or buildings
		if gameState.BoardState != nil {
			if unit, exists := gameState.BoardState.Units[UnitID(dmg.targetID)]; exists {
				if unit.TakeDamage(dmg.damage) {
					gameState.BoardState.RemoveUnit(UnitID(dmg.targetID))
					eventLog.AddEvent(GameEvent{
						Type:     EventUnitDestroyed,
						SourceID: dmg.targetID,
						Message:  "Unit destroyed by ability",
					})
				} else {
					eventLog.AddEvent(GameEvent{
						Type:     EventUnitDamaged,
						SourceID: dmg.sourceID,
						TargetID: dmg.targetID,
						Value:    dmg.damage,
						Message:  "Unit damaged by ability",
					})
				}
			}
		}
	}
	
	return nil
}

func (rm *RoundManager) processOtherEffects(ctx context.Context, gameState *GameState, actions []Action, eventLog *EventLog) error {
	for _, action := range actions {
		if action.Type == ActionTypePlayCard {
			if err := rm.processCardPlay(ctx, gameState, action, eventLog); err != nil {
				return err
			}
		}
	}
	return nil
}

func (rm *RoundManager) processCardPlay(ctx context.Context, gameState *GameState, action Action, eventLog *EventLog) error {
	if rm.cardRepo == nil {
		return nil
	}
	
	card, err := rm.cardRepo.GetCard(ctx, action.CardInHandID)
	if err != nil || card == nil {
		return nil
	}
	
	playerState := &gameState.PlayerStates[action.PlayerIndex]
	
	// Check if player can afford the card
	if playerState.Gold < card.GoldCost || playerState.Mana < card.ManaCost {
		return nil // Can't afford it
	}
	
	// Spend resources
	playerState.Gold -= card.GoldCost
	playerState.Mana -= card.ManaCost
	
	// Remove card from hand
	for i, handCard := range playerState.Hand {
		if handCard == action.CardInHandID {
			playerState.Hand = append(playerState.Hand[:i], playerState.Hand[i+1:]...)
			break
		}
	}
	
	// Add to discard pile (most cards go there after playing)
	playerState.DiscardPile = append(playerState.DiscardPile, action.CardInHandID)
	
	eventLog.AddCardPlayedEvent(action.PlayerIndex, action.CardInHandID, action.Position)
	
	// Process card effect based on type
	switch card.Type {
	case CardTypeUnit:
		if card.UnitStats != nil && action.Position != nil && gameState.BoardState != nil {
			unit := NewUnit(card.ID, action.PlayerIndex, *action.Position, card.UnitStats)
			unit.Abilities = card.Abilities
			gameState.BoardState.AddUnit(unit)
			eventLog.AddEvent(GameEvent{
				Type:        EventUnitSpawned,
				PlayerIndex: &action.PlayerIndex,
				SourceID:    string(unit.ID),
				Position:    action.Position,
				CardID:      card.ID,
				Message:     fmt.Sprintf("Unit %s spawned", card.Name),
			})
		}
		
	case CardTypeBuilding:
		if card.BuildingStats != nil && action.Position != nil && gameState.BoardState != nil {
			building := NewBuilding(card.ID, action.PlayerIndex, *action.Position, card.BuildingStats)
			building.Abilities = card.Abilities
			gameState.BoardState.AddBuilding(building)
			eventLog.AddEvent(GameEvent{
				Type:        EventBuildingPlaced,
				PlayerIndex: &action.PlayerIndex,
				SourceID:    building.ID,
				Position:    action.Position,
				CardID:      card.ID,
				Message:     fmt.Sprintf("Building %s placed", card.Name),
			})
		}
		
	case CardTypeSpell:
		// Spell effects would be handled based on the spell's specific effect
		// This is a simplified version
		if card.SpellEffect != nil {
			eventLog.AddEvent(GameEvent{
				Type:        EventTriggerActivated,
				PlayerIndex: &action.PlayerIndex,
				CardID:      card.ID,
				Message:     fmt.Sprintf("Spell %s cast", card.Name),
				Metadata: map[string]interface{}{
					"effect": card.SpellEffect.Effect,
					"target": card.SpellEffect.TargetType,
				},
			})
		}
	}
	
	return nil
}