# Turn System Feature Documentation

## Overview
This document describes the implementation of the simultaneous turn system with player choice locking for the Kitbash card game.

## Features Implemented

### 1. Turn Number Indicator
- Displays the current turn number prominently in the game UI
- Located in the status bar at the top of the game screen
- Animates when the turn advances to draw player attention

### 2. Lock-In Button
- Each player has a "Lock In Choice" button to confirm their turn decisions
- Button changes appearance and text when locked ("Locked In")
- Color-coded to match player colors (green for Player 1, pink for Player 2)
- Disabled state after locking to prevent accidental re-clicks

### 3. Player Lock Status Indicators
- Visual indicators showing which players have locked their choices
- Lock/unlock icons for each player
- Real-time updates when any player locks their choice

### 4. Waiting Indicator
- Shows "Waiting for opponent to lock in..." message when current player is locked but opponent isn't
- Animated loading indicator for better UX

## Technical Implementation

### Frontend (Flutter)

#### New Widgets
1. **`TurnIndicator`** (`lib/widgets/turn_indicator.dart`)
   - Displays current turn number
   - Shows lock status for both players
   - Animates on turn change

2. **`LockInButton`** (`lib/widgets/lock_in_button.dart`)
   - Interactive button for locking choices
   - Visual feedback on press
   - Disabled state when locked

3. **`WaitingIndicator`** (`lib/widgets/lock_in_button.dart`)
   - Animated waiting message
   - Shows when waiting for opponent

#### GameService Updates (`lib/services/game_service.dart`)
- Added `playerChoicesLocked` map to `GameState`
- Added `lockPlayerChoice()` method for locking player choices
- Added WebSocket message handlers for:
  - `player_locked`: Updates when a player locks their choice
  - `turn_advanced`: Handles turn advancement
  - `player_joined`: Sets current player index

#### Game Screen Integration (`lib/screens/game_screen.dart`)
- Integrated `TurnIndicator` in the status bar
- Added `LockInButton` and `WaitingIndicator` above the player hand
- Connected to GameService for real-time updates

### Backend (Go)

#### Domain Model Updates (`backend/internal/domain/game.go`)
- Added `PlayerChoicesLocked` map to `GameState` struct
- Added methods:
  - `LockPlayerChoice(playerIndex int)`: Locks a player's choice
  - `AreAllPlayersLocked() bool`: Checks if all players are locked
  - `AdvanceTurn()`: Advances turn and resets locks

#### WebSocket Handler Updates (`backend/internal/ws/game_hub.go`)
- Added `handleLockChoice()` handler for processing lock requests
- Added broadcast functions:
  - `broadcastPlayerLocked()`: Notifies all clients of a lock
  - `broadcastTurnAdvanced()`: Notifies all clients of turn advancement
- Automatic turn advancement when all players are locked

## Game Flow

1. **Turn Start**: Both players see the current turn number and can make their choices
2. **Player Actions**: Players select cards, targets, etc. for their turn
3. **Lock Choice**: Each player clicks "Lock In Choice" when ready
4. **Waiting State**: First player to lock sees waiting indicator
5. **Turn Resolution**: When both players lock:
   - Server processes both choices simultaneously
   - Turn counter increments
   - Lock states reset for next turn
6. **Repeat**: Process continues for subsequent turns

## Benefits

1. **Simultaneous Play**: Reduces waiting time as both players act at the same time
2. **Strategic Depth**: Players must anticipate opponent moves without seeing them first
3. **Fair Play**: Neither player has an advantage from moving first/last
4. **Clear Communication**: Visual indicators keep players informed of game state

## Future Enhancements

1. **Turn Timer**: Add optional timer to force lock after time limit
2. **Action Preview**: Show planned actions before locking
3. **Undo Before Lock**: Allow players to change choices before locking
4. **Turn History**: Display log of previous turns and choices
5. **Sound Effects**: Audio feedback for locking and turn advancement