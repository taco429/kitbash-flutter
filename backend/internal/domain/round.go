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

    // 2) Movement Step — resolve declared movement and handle collisions
    movementActions := filterByType(allActions, ActionTypeMoveUnit)
    resolveMovementCollisions(gameState, evtLog, movementActions)

    // 3) "Normal" Speed Step
    normal := filterBySpeed(allActions, ActionSpeedNormal)
    resolveUniversalStep(gameState, evtLog, "normal", normal)

    // 4) Combat Step — simultaneous damage from attack declarations
    attacks := filterByType(allActions, ActionTypeAttack)
    resolveCombatSimultaneous(gameState, evtLog, attacks)

    // 5) "Slow" Speed Step
    slow := filterBySpeed(allActions, ActionSpeedSlow)
    resolveUniversalStep(gameState, evtLog, "slow", slow)

    // 6) End of Round Cleanup Step
    // - Process queued discards
    for i := range gameState.PlayerStates {
        ps := &gameState.PlayerStates[i]
        if len(ps.PendingDiscards) > 0 {
            // Move from hand to discard if still present
            for _, cid := range ps.PendingDiscards {
                for h := 0; h < len(ps.Hand); h++ {
                    if ps.Hand[h] == cid {
                        ps.Hand = append(ps.Hand[:h], ps.Hand[h+1:]...)
                        ps.DiscardPile = append(ps.DiscardPile, cid)
                        h--
                    }
                }
            }
            evtLog.AddSimple(EventTypeDiscard, "end_of_round", map[string]any{
                "playerIndex": ps.PlayerIndex,
                "count":       len(ps.PendingDiscards),
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
    // Movement components first (no collision cancellation here)
    moves := filterByType(actions, ActionTypeMoveUnit)
    for _, a := range moves {
        log.AddSimple(EventTypeMovement, step, map[string]any{
            "playerIndex": a.PlayerIndex,
            "sourceId":    a.SourceID,
            "to":          a.Position,
            "cancelled":   false,
        })
    }
    // Simultaneous damage
    damages := make(map[int]int)
    for _, a := range actions {
        switch a.Type {
        case ActionTypeDealDamage:
            // Expect params: targetPlayerIndex or targetId like "cc:0"
            targetIdx := extractTargetPlayerIndex(a)
            if targetIdx >= 0 {
                damages[targetIdx] += extractDamageAmount(a)
            }
        }
    }
    if len(damages) > 0 {
        // Apply simultaneously
        for playerIdx, dmg := range damages {
            if dmg <= 0 {
                continue
            }
            // Log calculation before applying
            log.AddSimple(EventTypeDamage, step, map[string]any{
                "targetPlayerIndex": playerIdx,
                "amount":            dmg,
                "simultaneous":      true,
            })
        }
        for playerIdx, dmg := range damages {
            if dmg > 0 {
                gs.DealDamageToCommandCenter(playerIdx, dmg)
            }
        }
    }
    // Other effects
    for _, a := range actions {
        switch a.Type {
        case ActionTypeCastSpell, ActionTypePlayCard:
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
func resolveMovementCollisions(gs *GameState, log *EventLog, moves ActionQueue) {
    if len(moves) == 0 {
        return
    }
    // Collect intents by destination tile
    destToActions := make(map[Point][]Action)
    for _, m := range moves {
        destToActions[m.Position] = append(destToActions[m.Position], m)
    }
    for dest, list := range destToActions {
        if len(list) > 1 {
            // Collision: cancel all moves to this tile
            log.AddSimple(EventTypeMovement, "movement", map[string]any{
                "destination": dest,
                "cancelled":   true,
                "count":       len(list),
            })
            continue
        }
        // Single mover proceeds
        a := list[0]
        log.AddSimple(EventTypeMovement, "movement", map[string]any{
            "playerIndex": a.PlayerIndex,
            "sourceId":    a.SourceID,
            "to":          a.Position,
            "cancelled":   false,
        })
        // NOTE: Actual unit position state is not yet modeled; this logs intent.
    }
}

// resolveCombatSimultaneous applies attacks' damage simultaneously.
func resolveCombatSimultaneous(gs *GameState, log *EventLog, attacks ActionQueue) {
    if len(attacks) == 0 {
        return
    }
    // Compute damage snapshot
    damages := make(map[int]int)
    for _, a := range attacks {
        targetIdx := extractTargetPlayerIndex(a)
        if targetIdx >= 0 {
            damages[targetIdx] += extractDamageAmount(a)
        }
    }
    // Log all
    for idx, amt := range damages {
        if amt <= 0 {
            continue
        }
        log.AddSimple(EventTypeDamage, "combat", map[string]any{
            "targetPlayerIndex": idx,
            "amount":            amt,
            "simultaneous":      true,
        })
    }
    // Apply simultaneously
    for idx, amt := range damages {
        if amt > 0 {
            gs.DealDamageToCommandCenter(idx, amt)
        }
    }
}

func extractTargetPlayerIndex(a Action) int {
    // From params
    if a.Params != nil {
        if v, ok := a.Params["targetPlayerIndex"]; ok {
            switch t := v.(type) {
            case int:
                return t
            case float64:
                return int(t)
            }
        }
    }
    // From target ID like "cc:0" or "cc0"
    if len(a.TargetID) > 0 {
        if a.TargetID == "cc:0" || a.TargetID == "cc0" {
            return 0
        }
        if a.TargetID == "cc:1" || a.TargetID == "cc1" {
            return 1
        }
    }
    return -1
}

func extractDamageAmount(a Action) int {
    if a.Params != nil {
        if v, ok := a.Params["damage"]; ok {
            switch t := v.(type) {
            case int:
                return t
            case float64:
                return int(t)
            }
        }
    }
    // Default damage for attack or deal_damage_cc if unspecified
    if a.Type == ActionTypeAttack || a.Type == ActionTypeDealDamage {
        return 10
    }
    return 0
}

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

