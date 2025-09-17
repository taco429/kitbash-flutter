import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

import '../../models/tile_data.dart';

/// Loads and provides tile sprites for the isometric grid by terrain type.
///
/// Expected asset conventions (user can choose any one or mix):
/// - assets/images/tiles/grass.png
/// - assets/images/tiles/grass_1.png, grass_2.png, ...
/// - assets/images/tiles/grass/1.png, grass/2.png, ...
/// Same for: stone, water, desert, forest, mountain.
class TileSpriteManager {
  final Map<TerrainType, List<Sprite>> _terrainToSprites;
  final int totalLoadedCount;

  TileSpriteManager._(this._terrainToSprites, this.totalLoadedCount);

  /// Returns a sprite list for a terrain; empty if none loaded.
  List<Sprite> spritesForTerrain(TerrainType terrain) =>
      _terrainToSprites[terrain] ?? const [];

  /// Deterministically returns a sprite for the terrain based on a seed.
  Sprite? getSpriteForTerrain(TerrainType terrain, int variantSeed) {
    final sprites = spritesForTerrain(terrain);
    if (sprites.isEmpty) return null;
    final index = variantSeed.abs() % sprites.length;
    return sprites[index];
  }

  /// Attempts to load sprites from common naming patterns.
  static Future<TileSpriteManager> load({
    required Images images,
    String rootPath = 'tiles',
    int maxVariantsToProbe = 16,
  }) async {
    final Map<TerrainType, List<Sprite>> mapping = {
      for (final t in TerrainType.values) t: <Sprite>[]
    };

    final Map<TerrainType, String> name = {
      TerrainType.grass: 'grass',
      TerrainType.stone: 'stone',
      TerrainType.water: 'water',
      TerrainType.desert: 'desert',
      TerrainType.forest: 'forest',
      TerrainType.mountain: 'mountain',
    };

    int loaded = 0;

    Future<Sprite?> tryLoad(String asset) async {
      try {
        final image = await images.load(asset);
        return Sprite(image);
      } catch (_) {
        return null;
      }
    }

    for (final entry in name.entries) {
      final terrain = entry.key;
      final basename = entry.value;

      // Pattern A: single file
      final a = await tryLoad('$rootPath/$basename.png');
      if (a != null) {
        mapping[terrain]!.add(a);
        loaded++;
      }

      // Pattern B: numbered suffix files basename_1.png ... basename_N.png
      for (int i = 1; i <= maxVariantsToProbe; i++) {
        final b = await tryLoad('$rootPath/${basename}_$i.png');
        if (b == null) break; // stop at first gap
        mapping[terrain]!.add(b);
        loaded++;
      }

      // Pattern C: subfolder numbering basename/1.png ... basename/N.png
      for (int i = 1; i <= maxVariantsToProbe; i++) {
        final c = await tryLoad('$rootPath/$basename/$i.png');
        if (c == null) break; // stop at first gap
        mapping[terrain]!.add(c);
        loaded++;
      }
    }

    return TileSpriteManager._(mapping, loaded);
  }
}
