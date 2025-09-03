# Hover Highlight and Tooltip Implementation

## Overview

This implementation adds a responsive hover highlight system with tooltips to the card game's isometric tile grid. The system provides visual feedback when users hover over tiles and displays detailed information about tile contents after a short delay.

## Features Implemented

### 1. Hover Highlight System
- **Mouse tracking**: Added `HasHoverCallbacks` mixin to `KitbashGame` for mouse hover detection
- **Tile highlighting**: Visual highlight overlay on hovered tiles with subtle white overlay
- **Responsive feedback**: Immediate visual response to mouse movement over tiles
- **Separation of concerns**: Hover state is separate from selection state (tap/click)

### 2. Terrain System
- **Varied terrain types**: Grass, Stone, Water, Desert, Forest, Mountain
- **Terrain-based colors**: Each terrain type has distinct colors for visual variety
- **Procedural generation**: Sample terrain distribution based on distance from center
- **Extensible design**: Easy to add new terrain types and customize colors

### 3. Tooltip Component
- **Delayed appearance**: 500ms delay before tooltip shows (configurable)
- **Rich information display**: Shows tile coordinates, terrain type, units, and buildings
- **Animated appearance**: Smooth fade and scale animations for professional feel
- **Smart positioning**: Tooltip appears above and to the right of cursor
- **Health bars**: Visual health indicators for units and buildings
- **Player identification**: Color-coded player indicators

### 4. Data Models
- **TileData**: Comprehensive tile information including terrain, units, buildings
- **Unit/Building models**: Detailed entity information with health, player ownership
- **Extensible enums**: Easy to add new unit types, building types, terrain types

## File Structure

```
lib/
├── models/
│   └── tile_data.dart          # Data models for tiles, units, buildings
├── widgets/
│   ├── game_tooltip.dart       # Tooltip component with animations
│   └── game_with_tooltip.dart  # Wrapper combining game and tooltip
├── game/
│   └── kitbash_game.dart       # Enhanced with hover functionality
└── screens/
    └── game_screen.dart        # Updated to use tooltip wrapper

test/
├── hover_highlight_test.dart   # Tests for hover functionality
├── tooltip_test.dart           # Tests for tooltip component
└── game_with_tooltip_test.dart # Integration tests
```

## Implementation Details

### Hover Detection Flow
1. Mouse movement detected by `KitbashGame.onHoverEvent()`
2. Coordinates converted from screen space to isometric grid coordinates
3. `IsometricGridComponent.handleHover()` called with local coordinates
4. Tile data retrieved and enhanced with command center information
5. Hover callback triggered with tile data and screen position
6. `GameWithTooltip` receives callback and manages tooltip state

### Tooltip Display Logic
1. Hover callback updates tile data and position
2. Timer started with 500ms delay
3. If hover continues, tooltip becomes visible with animation
4. If hover ends, tooltip hides immediately
5. Rapid hover changes cancel previous timers

### Terrain Color System
Each terrain type has a carefully chosen color:
- **Grass**: Dark green (`0xFF4A5D23`)
- **Stone**: Gray (`0xFF5A5A5A`)
- **Water**: Blue (`0xFF2E5984`)
- **Desert**: Sandy brown (`0xFF8B7355`)
- **Forest**: Dark forest green (`0xFF2D4A22`)
- **Mountain**: Brown (`0xFF4A3728`)

## Usage Examples

### Basic Tile Hover
```dart
// Hover over any tile shows terrain information
TileData(
  row: 2, col: 3,
  terrain: TerrainType.forest,
)
// Tooltip: "Tile (2, 3)\n🌲 Forest"
```

### Tile with Unit
```dart
TileData(
  row: 1, col: 1,
  terrain: TerrainType.grass,
  unit: Unit(
    name: 'Elite Archer',
    playerIndex: 0,
    health: 75,
    maxHealth: 100,
    type: UnitType.archer,
  ),
)
// Tooltip shows terrain + unit info + health bar
```

### Command Center Tile
```dart
// Command centers are automatically detected
// Tooltip shows building info with health bar
```

## Testing

Comprehensive test suite covers:

### Hover Highlight Tests (`hover_highlight_test.dart`)
- Tile coordinate conversion accuracy
- Hover state management
- Command center detection
- Terrain color consistency
- Edge case handling (outside grid bounds)

### Tooltip Tests (`tooltip_test.dart`)
- Visibility conditions
- Content rendering for different tile types
- Animation behavior
- Position calculations
- Health bar display

### Integration Tests (`game_with_tooltip_test.dart`)
- Game-tooltip interaction
- Timer management
- Rapid hover changes
- Widget lifecycle

## Performance Considerations

1. **Efficient coordinate conversion**: Optimized isometric-to-screen calculations
2. **Minimal redraws**: Only hovered tile state changes trigger redraws
3. **Timer management**: Proper cleanup prevents memory leaks
4. **Animation optimization**: Hardware-accelerated transforms

## Future Enhancements

### Planned Features
1. **Terrain-specific tooltips**: Different information based on terrain type
2. **Unit action previews**: Show available actions when hovering over units
3. **Battle predictions**: Preview combat outcomes
4. **Resource information**: Show terrain resource yields
5. **Movement range**: Highlight valid movement tiles
6. **Customizable delays**: User-configurable tooltip timing

### Technical Improvements
1. **Texture-based terrain**: Replace solid colors with terrain textures
2. **Layered rendering**: Separate terrain, entities, and effects
3. **Caching**: Cache frequently accessed tile data
4. **Accessibility**: Screen reader support and keyboard navigation

## Configuration Options

### Tooltip Timing
```dart
static const Duration _tooltipDelay = Duration(milliseconds: 500);
```

### Tooltip Positioning
```dart
left: position.dx + 10,  // 10px right of cursor
top: position.dy - 60,   // 60px above cursor
```

### Hover Highlight Color
```dart
final ui.Paint hoverPaint = ui.Paint()..color = const Color(0x66FFFFFF);
```

## Compatibility

- **Flutter Version**: 3.0+
- **Flame Version**: 1.13.0+
- **Platform Support**: Web (primary focus), with mobile/desktop compatibility
- **Browser Support**: All modern browsers with hardware acceleration

## Integration Notes

The implementation is designed to work alongside:
- Existing command center rendering
- Future unit/building sprites
- Card drag-and-drop functionality
- Multiplayer synchronization

The hover system operates independently of game state changes and won't interfere with network updates or game logic.