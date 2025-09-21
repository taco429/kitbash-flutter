package domain

import (
    "math/rand"
    "time"
)

// ExecuteUpkeepPhase performs the automatic upkeep operations in order.
// 1) Start-of-upkeep triggers (placeholder hooks)
// 2) Generate resources (Gold income added to bank; Mana refilled to ManaMax)
// 3) Draw up to hand limit
// 4) Update turn counters (placeholder hooks)
func ExecuteUpkeepPhase(gameState *GameState) *EventLog {
    if gameState == nil {
        return NewEventLog(0)
    }
    evtLog := NewEventLog(gameState.CurrentTurn)
    evtLog.AddSimple(EventTypeRoundStart, "upkeep", map[string]any{
        "turn": gameState.CurrentTurn,
    })

    // 1) Start-of-upkeep triggers (no-op placeholder)
    evtLog.AddSimple(EventTypeTrigger, "upkeep", map[string]any{
        "note": "start_of_upkeep_triggers_resolved",
    })

    // 2) Generate resources - this is now handled by ProcessResourceGeneration
    // which is called in AdvanceTurn at the start of each turn
    // Log the resource generation that already happened
    for i := range gameState.PlayerStates {
        ps := &gameState.PlayerStates[i]
        if ps.ResourceIncome.Gold > 0 || ps.ResourceIncome.Mana > 0 {
            evtLog.AddSimple(EventTypeResource, "upkeep", map[string]any{
                "playerIndex": ps.PlayerIndex,
                "goldIncome":  ps.ResourceIncome.Gold,
                "manaIncome":  ps.ResourceIncome.Mana,
                "gold":        ps.Resources.Gold,
                "mana":        ps.Resources.Mana,
            })
        }
    }

    // 3) Draw to hand limit
    for i := range gameState.PlayerStates {
        ps := &gameState.PlayerStates[i]
        handLimit := ps.HandLimit
        if handLimit <= 0 {
            handLimit = 7
            ps.HandLimit = handLimit
        }
        toDraw := handLimit - len(ps.Hand)
        if toDraw > 0 {
            drawn := drawCardsDeterministic(gameState, ps, toDraw, evtLog)
            if drawn > 0 {
                evtLog.AddSimple(EventTypeDraw, "upkeep", map[string]any{
                    "playerIndex": ps.PlayerIndex,
                    "count":       drawn,
                    "handCount":   len(ps.Hand),
                })
            }
        }
    }

    // 4) Update turn counters (placeholder)
    evtLog.AddSimple(EventTypeTrigger, "upkeep", map[string]any{
        "note": "turn_counters_updated",
    })

    gameState.UpdatedAt = time.Now()
    return evtLog
}

// ExecuteResolutionPhase resolves both players' action queues in strict order
// and applies end-of-round cleanup effects. Returns a detailed EventLog.
func ExecuteResolutionPhase(gameState *GameState, player1Actions ActionQueue, player2Actions ActionQueue, cardRepo CardRepository) *EventLog {
    evtLog := NewEventLog(gameState.CurrentTurn)

    // Phase 1: Move all units
    ExecuteUnitMovement(gameState, evtLog)
    
    // Phase 2: All units attack
    ExecuteUnitCombat(gameState, evtLog)
    
    // Phase 3: Spawn new units from planned plays
    // For now, only log the play and move the card from hand to discard.
    if gameState != nil && gameState.PlannedPlays != nil {
        for playerIndex, plays := range gameState.PlannedPlays {
            // Defensive bounds check
            if playerIndex < 0 || playerIndex >= len(gameState.PlayerStates) {
                continue
            }
            ps := &gameState.PlayerStates[playerIndex]
            for _, p := range plays {
                // Check if spawn position is still available
                positionBlocked := gameState.IsTileOccupied(p.Position.Row, p.Position.Col)
                
                if positionBlocked {
                    // Position is blocked, refund the card cost
                    if cardRepo != nil {
                        card, err := cardRepo.GetCard(nil, p.CardID)
                        if err == nil && card != nil {
                            refund := Resources{
                                Gold: card.GoldCost,
                                Mana: card.ManaCost,
                            }
                            gameState.AddPendingRefund(playerIndex, refund)
                            evtLog.AddSimple(EventTypeEffect, "refund", map[string]any{
                                "playerIndex":    playerIndex,
                                "cardId":         p.CardID,
                                "goldRefunded":   refund.Gold,
                                "manaRefunded":   refund.Mana,
                                "reason":         "spawn_blocked",
                            })
                        }
                    }
                } else {
                    // Spawn the unit
                    if cardRepo != nil {
                        card, err := cardRepo.GetCard(nil, p.CardID)
                        if err == nil && card != nil && card.IsUnit() && card.UnitStats != nil {
                            unit := gameState.SpawnUnit(p.CardID, playerIndex, p.Position, card.UnitStats)
                            evtLog.AddSimple(EventTypeEffect, "spawn_unit", map[string]any{
                                "playerIndex":    playerIndex,
                                "cardId":         p.CardID,
                                "unitId":         unit.ID,
                                "row":            p.Position.Row,
                                "col":            p.Position.Col,
                                "attack":         unit.Attack,
                                "health":         unit.Health,
                            })
                        }
                    }
                    
                    // Log reveal/play event with target tile
                    evtLog.AddSimple(EventTypeEffect, "reveal", map[string]any{
                        "playerIndex":    playerIndex,
                        "action":         string(ActionTypePlayCard),
                        "cardId":         p.CardID,
                        "cardInstanceId": p.CardInstance,
                        "row":            p.Position.Row,
                        "col":            p.Position.Col,
                    })
                }
                
                // Move card instance from hand to discard regardless
                for h := 0; h < len(ps.Hand); h++ {
                    if ps.Hand[h].InstanceID == p.CardInstance {
                        card := ps.Hand[h]
                        ps.Hand = append(ps.Hand[:h], ps.Hand[h+1:]...)
                        ps.DiscardPile = append(ps.DiscardPile, card)
                        h--
                        break
                    }
                }
            }
        }
        // Clear planned plays after processing
        gameState.ClearPlannedPlays()
    }
    
    // Process any pending refunds
    gameState.ProcessPendingRefunds()

    // Helper: combine two queues with player attribution already set in Action
    allActions := append(ActionQueue{}, player1Actions...)
    allActions = append(allActions, player2Actions...)

    // 1) "Fast" Speed Step
    fast := filterBySpeed(allActions, ActionSpeedFast)
    resolveUniversalStep(gameState, evtLog, "fast", fast)

    // 2) "Normal" Speed Step
    normal := filterBySpeed(allActions, ActionSpeedNormal)
    resolveUniversalStep(gameState, evtLog, "normal", normal)

    // 3) "Slow" Speed Step
    slow := filterBySpeed(allActions, ActionSpeedSlow)
    resolveUniversalStep(gameState, evtLog, "slow", slow)

    // 4) End of Round Cleanup Step
    // Remove dead units
    gameState.RemoveDeadUnits()
    
    // Reset unit turn states for next turn
    for _, unit := range gameState.Units {
        if unit.IsAlive {
            unit.ResetTurnState()
        }
    }
    // - Process queued discards
    for i := range gameState.PlayerStates {
        ps := &gameState.PlayerStates[i]
        if len(ps.PendingDiscards) > 0 {
            discardedCount := 0
            initialHandSize := len(ps.Hand)
            // Move from hand to discard if still present
            for _, instanceID := range ps.PendingDiscards {
                for h := 0; h < len(ps.Hand); h++ {
                    if ps.Hand[h].InstanceID == instanceID {
                        // Store the card before removing
                        card := ps.Hand[h]
                        ps.Hand = append(ps.Hand[:h], ps.Hand[h+1:]...)
                        ps.DiscardPile = append(ps.DiscardPile, card)
                        discardedCount++
                        h--
                    }
                }
            }
            evtLog.AddSimple(EventTypeDiscard, "end_of_round", map[string]any{
                "playerIndex": ps.PlayerIndex,
                "count":       discardedCount,
                "requested":   len(ps.PendingDiscards),
                "handBefore":  initialHandSize,
                "handAfter":   len(ps.Hand),
                "discardPile": len(ps.DiscardPile),
            })
            ps.PendingDiscards = nil
        }
        // Mana is already reset at the start of each turn by ProcessResourceGeneration
        // Just log it if needed
        if ps.Resources.Mana != 0 {
            evtLog.AddSimple(EventTypeResource, "end_of_round", map[string]any{
                "playerIndex": ps.PlayerIndex,
                "mana":        0,
                "note":        "mana_reset_end_of_round",
            })
        }
    }

    // - End of Round triggers (placeholder)
    evtLog.AddSimple(EventTypeTrigger, "end_of_round", map[string]any{
        "note": "end_of_round_triggers_resolved",
    })

    // - Win/Loss check
    if gameState.IsGameOver() {
        evtLog.AddSimple(EventTypeRoundEnd, "end_of_round", map[string]any{
            "winner": gameState.GetWinner(),
        })
    }

    gameState.UpdatedAt = time.Now()
    return evtLog
}

// --- Helpers ---

func filterBySpeed(actions ActionQueue, speed ActionSpeed) ActionQueue {
    out := make(ActionQueue, 0, len(actions))
    for _, a := range actions {
        if a.Speed == speed {
            out = append(out, a)
        }
    }
    return out
}

func filterByType(actions ActionQueue, t ActionType) ActionQueue {
    out := make(ActionQueue, 0, len(actions))
    for _, a := range actions {
        if a.Type == t {
            out = append(out, a)
        }
    }
    return out
}

// resolveUniversalStep applies the universal rule: Movement -> Damage -> Other Effects.
func resolveUniversalStep(gs *GameState, log *EventLog, step string, actions ActionQueue) {
    if len(actions) == 0 {
        return
    }
    // Other effects (resolve play_card/activate_ability payloads)
    for _, a := range actions {
        switch a.Type {
        case ActionTypePlayCard, ActionTypeActivateAbility:
            log.AddSimple(EventTypeEffect, step, map[string]any{
                "playerIndex": a.PlayerIndex,
                "sourceId":    a.SourceID,
                "cardInHandId": a.CardInHandID,
                "targetId":    a.TargetID,
            })
        }
    }
}

// resolveMovementCollisions processes movement and cancels collisions to the same destination.
// Movement and combat are automatic in this simplified server core; detailed
// unit systems will replace these placeholders in future iterations.

// resolveCombatSimultaneous applies attacks' damage simultaneously.
// resolveCombatSimultaneous removed; no player-submitted attack actions.

// extractTargetPlayerIndex/extractDamageAmount removed with debug actions.

// drawCardsDeterministic draws up to count cards, shuffling discard into draw if needed.
// Returns the number of cards actually drawn.
func drawCardsDeterministic(gs *GameState, ps *PlayerBattleState, count int, log *EventLog) int {
    if count <= 0 {
        return 0
    }
    drawn := 0
    for i := 0; i < count; i++ {
        if len(ps.DrawPile) == 0 {
            // If discard also empty, cannot draw
            if len(ps.DiscardPile) == 0 {
                break
            }
            // Reshuffle discard into draw pile and apply deck exhaustion penalty
            reshuffleDiscard(ps)
            // Apply penalty: -25 HP to own command center
            gs.DealDamageToCommandCenter(ps.PlayerIndex, 25)
            log.AddSimple(EventTypeEffect, "upkeep", map[string]any{
                "playerIndex": ps.PlayerIndex,
                "deckExhausted": true,
                "penaltyDamage": 25,
            })
        }
        // Draw top of draw pile
        n := len(ps.DrawPile)
        card := ps.DrawPile[n-1]
        ps.DrawPile = ps.DrawPile[:n-1]
        ps.Hand = append(ps.Hand, card)
        drawn++
    }
    ps.DeckCount = len(ps.DrawPile)
    return drawn
}

func reshuffleDiscard(ps *PlayerBattleState) {
    // Move all discard into draw and shuffle
    ps.DrawPile = append(ps.DrawPile, ps.DiscardPile...)
    ps.DiscardPile = nil
    // Deterministic enough per match seed would be better; use time seed fallback
    r := rand.New(rand.NewSource(time.Now().UnixNano()))
    // Fisher-Yates
    for i := len(ps.DrawPile) - 1; i > 0; i-- {
        j := r.Intn(i + 1)
        ps.DrawPile[i], ps.DrawPile[j] = ps.DrawPile[j], ps.DrawPile[i]
    }
    ps.DeckCount = len(ps.DrawPile)
}

// ExecuteUnitMovement handles all unit movement for the turn
func ExecuteUnitMovement(gs *GameState, log *EventLog) {
    if gs == nil || len(gs.Units) == 0 {
        return
    }
    
    // Build occupied tiles map
    occupiedTiles := make(map[Point]bool)
    
    // Mark command centers as occupied
    for _, cc := range gs.CommandCenters {
        for row := cc.TopLeftRow; row < cc.TopLeftRow+2; row++ {
            for col := cc.TopLeftCol; col < cc.TopLeftCol+2; col++ {
                occupiedTiles[Point{Row: row, Col: col}] = true
            }
        }
    }
    
    // Process movement for each unit that hasn't moved this turn
    // Units spawned this turn don't move
    for _, unit := range gs.Units {
        if !unit.IsAlive || unit.HasMoved || unit.TurnSpawned == gs.TurnCount {
            continue
        }
        
        // Get enemy command center position for pathfinding
        enemyCCPos := gs.GetEnemyCommandCenterPosition(unit.PlayerIndex)
        
        // Calculate next position
        nextPos := unit.GetNextPosition(gs.BoardRows, gs.BoardCols, occupiedTiles, enemyCCPos)
        
        // Check if the position is actually free (another unit might have moved there)
        if nextPos != unit.Position && !occupiedTiles[nextPos] {
            oldPos := unit.Position
            unit.Move(nextPos)
            occupiedTiles[nextPos] = true
            
            log.AddSimple(EventTypeMovement, "unit_move", map[string]any{
                "unitId":      unit.ID,
                "playerIndex": unit.PlayerIndex,
                "fromRow":     oldPos.Row,
                "fromCol":     oldPos.Col,
                "toRow":       nextPos.Row,
                "toCol":       nextPos.Col,
                "direction":   unit.Direction,
            })
        }
    }
}

// ExecuteUnitCombat handles all unit attacks for the turn
func ExecuteUnitCombat(gs *GameState, log *EventLog) {
    if gs == nil || len(gs.Units) == 0 {
        return
    }
    
    // Track damage to be applied (for simultaneous resolution)
    type DamageEvent struct {
        Target *Unit
        Damage int
        Source *Unit
    }
    var damageEvents []DamageEvent
    
    // Units spawned this turn don't attack
    for _, unit := range gs.Units {
        if !unit.IsAlive || unit.HasAttacked || unit.TurnSpawned == gs.TurnCount {
            continue
        }
        
        // Find closest enemy in range
        var target *Unit
        minDistance := 999
        
        for _, enemy := range gs.Units {
            if !enemy.IsAlive || enemy.PlayerIndex == unit.PlayerIndex {
                continue
            }
            
            // Check if in range
            distance := abs(enemy.Position.Row-unit.Position.Row) + abs(enemy.Position.Col-unit.Position.Col)
            if distance <= unit.Range && distance < minDistance {
                target = enemy
                minDistance = distance
            }
        }
        
        // If no unit target, check if command center is in range
        if target == nil {
            enemyCC := gs.GetCommandCenter(1 - unit.PlayerIndex)
            if enemyCC != nil {
                // Check all tiles of the command center
                for row := enemyCC.TopLeftRow; row < enemyCC.TopLeftRow+2; row++ {
                    for col := enemyCC.TopLeftCol; col < enemyCC.TopLeftCol+2; col++ {
                        distance := abs(row-unit.Position.Row) + abs(col-unit.Position.Col)
                        if distance <= unit.Range {
                            // Attack command center
                            gs.DealDamageToCommandCenter(1-unit.PlayerIndex, unit.Attack)
                            unit.PerformAttack()
                            
                            log.AddSimple(EventTypeDamage, "unit_attack_cc", map[string]any{
                                "unitId":      unit.ID,
                                "playerIndex": unit.PlayerIndex,
                                "targetCC":    1 - unit.PlayerIndex,
                                "damage":      unit.Attack,
                                "ccHealth":    enemyCC.Health,
                            })
                            break
                        }
                    }
                }
            }
        } else {
            // Queue damage to target unit
            damageEvents = append(damageEvents, DamageEvent{
                Target: target,
                Damage: unit.Attack,
                Source: unit,
            })
            unit.PerformAttack()
        }
    }
    
    // Apply all damage simultaneously
    for _, event := range damageEvents {
        event.Target.TakeDamage(event.Damage)
        
        log.AddSimple(EventTypeDamage, "unit_attack", map[string]any{
            "attackerId":   event.Source.ID,
            "attackerPlayer": event.Source.PlayerIndex,
            "targetId":     event.Target.ID,
            "targetPlayer": event.Target.PlayerIndex,
            "damage":       event.Damage,
            "targetHealth": event.Target.Health,
            "targetAlive":  event.Target.IsAlive,
        })
    }
}

