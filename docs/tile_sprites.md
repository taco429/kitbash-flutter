## Tile Sprite Setup

This game supports rendering board tiles using sprites. If sprites are missing, it gracefully falls back to vector-drawn tiles.

### Where to put images

Place your PNGs under:

```
assets/images/tiles/
```

Recognized terrain keys (folder or basename): `grass`, `stone`, `water`, `desert`, `forest`, `mountain`.

### Supported naming patterns

- Single file per terrain:
  - `assets/images/tiles/grass.png`
- Numbered variants (auto-cycled by seed):
  - `assets/images/tiles/grass_1.png`, `grass_2.png`, ...
  - or `assets/images/tiles/grass/1.png`, `grass/2.png`, ...

Any subset is fine—missing terrains fall back to vector color tiles.

### Recommended sprite size

- Default tile size is `64x32` (isometric diamond). Sprites are rendered at `tileSize`, so any source size will be scaled, but you’ll get best results if the art is authored at 64x32 with transparent background and the diamond centered.
- If your art uses a different tile size, adjust in code where the grid is created:

```dart
// lib/game/kitbash_game.dart
tileSize: Vector2(64, 32), // change if your sprites differ
```

### Enabling the sprite grid

The game defaults to the sprite-based grid. You can toggle in `KitbashGame`:

```dart
// lib/game/kitbash_game.dart
bool useSpriteGrid = true;    // sprite tiles when available
bool useEnhancedGrid = true;  // fallback: enhanced or basic
```

### Asset registration

`pubspec.yaml` already includes `assets/images/`, so you don’t need to update it to add new tiles.

### File structure example

```
assets/
  images/
    tiles/
      grass.png
      stone.png
      water_1.png
      water_2.png
      forest/
        1.png
        2.png
      desert.png
      mountain.png
```

