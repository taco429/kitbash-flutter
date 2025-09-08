# Card Instance Implementation

## Overview
This document describes the implementation of unique card instances in the Kitbash card game to properly handle duplicate cards in a player's deck.

## Problem Statement
Previously, cards were tracked by their card name/type ID (e.g., "lightning-bolt") throughout the game state. This caused issues when players had duplicate cards:
- Selecting one card for discard would select all duplicates
- The game couldn't distinguish between individual copies of the same card
- Shuffling and dealing couldn't properly track specific card instances

## Solution
Implemented a `CardInstance` system that gives each physical card in a deck a unique instance ID, while maintaining the card type ID for game rules and display.

### Backend Changes

#### 1. New CardInstance Type (`backend/internal/domain/card_instance.go`)
```go
type CardInstance struct {
    InstanceID CardInstanceID `json:"instanceId"`
    CardID     CardID         `json:"cardId"`
}
```
- `InstanceID`: Unique UUID for each physical card
- `CardID`: Reference to the card type/definition

#### 2. Updated PlayerBattleState (`backend/internal/domain/game.go`)
- Changed `Hand`, `DrawPile`, and `DiscardPile` from `[]CardID` to `[]CardInstance`
- Changed `PendingDiscards` from `[]CardID` to `[]CardInstanceID`
- Cards are now tracked by their unique instance IDs throughout the game

#### 3. Deck Initialization (`backend/internal/ws/game_hub.go`)
- When building a player's deck, each card entry is expanded into unique CardInstances
- Each duplicate card gets its own unique instance ID
- Shuffling preserves instance identity

### Frontend Changes

#### 1. New CardInstance Model (`lib/models/card_instance.dart`)
```dart
class CardInstance {
  final String instanceId;
  final String cardId;
}
```

#### 2. Updated PlayerBattleState (`lib/services/game_service.dart`)
- Hand is now `List<CardInstance>` instead of `List<String>`
- Backwards compatibility maintained for legacy messages

#### 3. Card Selection (`lib/services/game_service.dart`)
- `toggleCardDiscard()` now uses instance IDs instead of card IDs
- Discard tracking uses instance IDs to identify specific cards

#### 4. UI Updates (`lib/widgets/animated_hand_display.dart`)
- AnimatedHandDisplay now receives both cards and card instances
- Selection/discard UI uses instance IDs for tracking
- Visual feedback properly highlights only selected instances

## Benefits
1. **Accurate Card Tracking**: Each physical card is uniquely identifiable
2. **Proper Duplicate Handling**: Players can select specific duplicates for actions
3. **Consistent Game State**: Cards maintain identity through shuffling, drawing, and discarding
4. **Backwards Compatibility**: Frontend handles both old and new message formats

## Testing
- Backend tests verify unique instance creation and duplicate handling
- Frontend tests ensure proper selection of individual duplicates
- End-to-end testing confirms cards maintain identity through game phases

## Migration Notes
- Existing games will need to be restarted to use the new card instance system
- The frontend maintains backwards compatibility for old message formats
- All new games automatically use the card instance system

## Future Enhancements
- Add card history tracking using instance IDs
- Implement card-specific state (e.g., damage counters) tied to instances
- Enable replay functionality with accurate card tracking