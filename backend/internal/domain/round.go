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

    // 2) Generate resources and refill mana
    for i := range gameState.PlayerStates {
        ps := &gameState.PlayerStates[i]
        // Bank Gold
        if ps.GoldIncome > 0 {
            ps.Gold += ps.GoldIncome
            evtLog.AddSimple(EventTypeResource, "upkeep", map[string]any{
                "playerIndex": ps.PlayerIndex,
                "goldDelta":   ps.GoldIncome,
                "gold":        ps.Gold,
            })
        }
        // Refill Mana to ManaMax
        if ps.ManaMax < 0 {
            ps.ManaMax = 0
        }
        oldMana := ps.Mana
        ps.Mana = ps.ManaMax
        evtLog.AddSimple(EventTypeResource, "upkeep", map[string]any{
            "playerIndex": ps.PlayerIndex,
            "manaDelta":   ps.Mana - oldMana,
            "mana":        ps.Mana,
        })
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
func ExecuteResolutionPhase(gameState *GameState, player1Actions ActionQueue, player2Actions ActionQueue) *EventLog {
    evtLog := NewEventLog(gameState.CurrentTurn)

    // Helper: combine two queues with player attribution already set in Action
    allActions := append(ActionQueue{}, player1Actions...)
    allActions = append(allActions, player2Actions...)

    // 1) "Fast" Speed Step
    fast := filterBySpeed(allActions, ActionSpeedFast)
    resolveUniversalStep(gameState, evtLog, "fast", fast)

    // 2) Movement Step — automatic movement (placeholder, no player-submitted movement)
    evtLog.AddSimple(EventTypeMovement, "movement", map[string]any{
        "note": "automatic_unit_movement_resolved",
    })

    // 3) "Normal" Speed Step
    normal := filterBySpeed(allActions, ActionSpeedNormal)
    resolveUniversalStep(gameState, evtLog, "normal", normal)

    // 4) Combat Step — automatic simultaneous combat (placeholder)
    evtLog.AddSimple(EventTypeDamage, "combat", map[string]any{
        "note": "automatic_simultaneous_combat_resolved",
    })

    // 5) "Slow" Speed Step
    slow := filterBySpeed(allActions, ActionSpeedSlow)
    resolveUniversalStep(gameState, evtLog, "slow", slow)

    // 6) End of Round Cleanup Step
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
        // Reset Mana to 0 (Gold persists)
        if ps.Mana != 0 {
            ps.Mana = 0
            evtLog.AddSimple(EventTypeResource, "end_of_round", map[string]any{
                "playerIndex": ps.PlayerIndex,
                "mana":        ps.Mana,
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

