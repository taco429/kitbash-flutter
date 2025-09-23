# Unit Implementation Summary

## Overview
Successfully implemented comprehensive unit mechanics for the Kitbash CCG game, including unit spawning, movement, combat, and rendering systems.

## Backend Implementation

### 1. Unit Domain Model (`backend/internal/domain/unit.go`)
- Created `Unit` struct with position, health, attack, and movement properties
- Implemented 8-directional movement system
- Added turn-based state management (HasMoved, HasAttacked, TurnSpawned)
- Pathfinding logic to move units towards enemy command center
- Damage calculation with armor reduction

### 2. GameState Integration
- Added `Units` array to GameState for tracking all units on the board
- Implemented unit spawning from card plays
- Added collision detection for occupied tiles
- Gold refund system when spawn position is blocked
- Unit management methods (GetUnitAt, GetUnitsForPlayer, RemoveDeadUnits)

### 3. Resolution Phase Updates (`backend/internal/domain/round.go`)
- Three-phase resolution system:
  1. **Movement Phase**: All units move simultaneously
  2. **Combat Phase**: All units attack simultaneously
  3. **Spawn Phase**: New units are spawned from played cards
- Units spawned on the same turn don't move or attack (as per requirements)
- Automatic targeting of closest enemy units or command center

### 4. Resource Management
- Automatic gold refund when unit spawn is blocked
- Pending refunds processed at end of resolution phase
- Resources properly deducted when units are successfully spawned

## Frontend Implementation

### 1. Unit Model (`lib/models/unit.dart`)
- Created `GameUnit` class with all unit properties
- `BoardPosition` class for grid positioning
- `UnitDirection` enum for 8-directional facing
- Health percentage calculation for health bar display
- Sprite asset path generation based on unit type and direction

### 2. Unit Rendering (`lib/game/sprite_isometric_grid.dart`)
- Integrated unit rendering into the isometric grid system
- Visual components for each unit:
  - Colored circle (blue for player, red for enemy)
  - Unit type indicator (G for Goblin, Z for Ghoul)
  - Health bar with color coding (green/yellow/red)
  - Attack/Health stats display
  - Directional arrow indicator
- Units render above tiles but below UI overlays

### 3. GameService Integration
- Updated GameState to include units array
- Automatic syncing of unit state from WebSocket updates
- Units parsed from JSON and converted to GameUnit objects

## Key Features Implemented

### Movement System
- Units move towards enemy command center automatically
- Speed stat determines tiles moved per turn
- Collision detection prevents overlapping units
- Units stop when encountering allied units
- Command centers block movement

### Combat System
- Range-based attacks (melee = 1, ranged > 1)
- Automatic target selection (closest enemy)
- Simultaneous damage resolution
- Command center attacks when no units in range
- Armor reduces incoming damage

### Spawn System
- Units spawn at the tile where card is played
- Spawn blocked if tile is occupied
- Gold automatically refunded for blocked spawns
- Units don't move/attack on spawn turn

## Unit Cards Implemented
- **Goblin** (Red): 2/2 unit, 1 gold cost
- **Ghoul** (Purple): 1/2 unit, 1 gold cost
- Both units have standard melee range and speed

## Testing
- Created test script (`test_units.sh`) for easy testing
- Backend server successfully compiles and runs
- API endpoints return unit card data
- Game creation works with unit support

## Performance Considerations
- Efficient collision detection using maps
- Simultaneous resolution prevents turn order advantages
- Unit state properly cleaned up when units die
- Minimal network traffic with delta updates

## Extensibility
- Easy to add new unit types by defining cards
- Direction system supports complex movement patterns
- Stats system allows for buffs/debuffs
- Modular combat resolution for special abilities

## Next Steps (Future Enhancements)
- Add unit ability system (keywords like Flying, Taunt, etc.)
- Implement unit animations for movement and attacks
- Add sound effects for unit actions
- Create unit sprites for each direction
- Implement area-of-effect abilities
- Add unit buff/debuff visual indicators
- Create unit selection and detailed info display
- Add combat log for unit actions