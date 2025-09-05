# Discard Feature Implementation Summary

## Overview
The discard feature has been successfully implemented to allow players to mark cards for discard during the planning phase. When the planning phase ends and transitions to the reveal/resolve phase, the selected cards are moved from the player's hand to their discard pile.

## Frontend Implementation

### 1. GameService State Management (`lib/services/game_service.dart`)
- Added `_cardsToDiscard` Set to track cards marked for discard
- Added `isCardMarkedForDiscard()` method to check if a card is marked
- Added `toggleCardDiscard()` method to mark/unmark cards
- Added `clearDiscardSelection()` method to clear the selection
- Modified `lockPlayerChoice()` to send discard information with the lock message
- Added phase change handling to clear discard selection when entering reveal_resolve phase

### 2. UI Components (`lib/screens/game_screen.dart`)
- Modified `_CenteredHandDisplay` widget to show discard functionality
- Added a small X button overlay on each card during the planning phase
- The X button appears only when:
  - The game is in the planning phase
  - The player hasn't locked their choices yet
- Visual feedback includes:
  - Red circular X button in the top-right corner of each card
  - Cards marked for discard show with 60% opacity
  - Red border around cards marked for discard
  - X button changes color (red when marked, dark when not)

## Backend Implementation

### 1. Game Domain Logic (`backend/internal/domain/game.go`)
- Added `DiscardCards()` method to GameState
- This method:
  - Takes a player index and list of card IDs
  - Removes cards from the player's hand
  - Adds them to the player's discard pile
  - Updates the game timestamp

### 2. WebSocket Handler (`backend/internal/ws/game_hub.go`)
- Modified `handleLockChoice()` to process discard cards
- When a player locks their choice:
  - Extracts the `discardCards` array from the message
  - Calls `gameState.DiscardCards()` to move cards to discard pile
  - Logs the discard action for debugging

## How It Works

### During Planning Phase:
1. Players see a small X button on each card in their hand
2. Clicking the X toggles the card for discard (visual feedback with opacity and red border)
3. Players can select multiple cards to discard
4. The selection is stored locally in the GameService

### When Locking Choices:
1. When a player clicks "Lock In", the selected cards are sent to the backend
2. The backend processes the discard request along with the lock action
3. Cards are immediately moved from hand to discard pile in the game state

### Phase Transition:
1. When transitioning to reveal/resolve phase, the frontend clears its local discard selection
2. The backend has already moved the cards to the discard pile
3. The updated game state is broadcast to all players

## Testing the Feature

To test this feature when the application is running:
1. Start a game and wait for the planning phase
2. Click the X button on cards you want to discard
3. Observe the visual feedback (opacity and red border)
4. Click "Lock In" to confirm your choices
5. When both players lock in, the phase advances to reveal/resolve
6. The discarded cards will be removed from your hand and placed in the discard pile

## Visual Design
- **X Button**: Small circular button with white X icon
- **Position**: Top-right corner of each card (4px from edges)
- **Size**: 24x24 pixels
- **Colors**: 
  - Not selected: Dark background with white border
  - Selected: Red background with white border
- **Card Feedback**:
  - Selected cards show at 60% opacity
  - Red border (2px) around selected cards