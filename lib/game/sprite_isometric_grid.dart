import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../models/tile_data.dart';
import 'sprites/tile_sprite_manager.dart';

/// Isometric grid that renders each tile using sprites when available,
/// with graceful fallback to vector drawing if sprites are missing.
class SpriteIsometricGrid extends PositionComponent with HasGameRef<FlameGame> {
  final int rows;
  final int cols;
  final Vector2 tileSize;
  final GameService gameService;
  List<CommandCenter> _commandCenters;

  int? highlightedRow;
  int? highlightedCol;
  int? hoveredRow;
  int? hoveredCol;

  late List<List<TileData>> _tileData;
  late List<List<int>> _variantSeeds;

  TileSpriteManager? _tileSprites;

  SpriteIsometricGrid({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.gameService,
    List<CommandCenter>? commandCenters,
  }) : _commandCenters = commandCenters ?? <CommandCenter>[] {
    // Bounding size of an isometric diamond grid
    size = Vector2(
      (cols + rows) * (tileSize.x / 2),
      (cols + rows) * (tileSize.y / 2),
    );
    _initializeTileData();
    _initializeVariantSeeds();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load sprites lazily; if none present, we still render via fallback.
    _tileSprites = await TileSpriteManager.load(images: gameRef.images);
  }

  void _initializeTileData() {
    _tileData = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        // Simple terrain distribution resembling earlier components
        TerrainType terrain;
        final distance = ((row - rows / 2).abs() + (col - cols / 2).abs()) / 2;
        if (distance < 2) {
          terrain = TerrainType.grass;
        } else if (distance < 4) {
          terrain = (row + col) % 3 == 0 ? TerrainType.forest : TerrainType.grass;
        } else if (distance < 6) {
          terrain = (row + col) % 4 == 0 ? TerrainType.stone : TerrainType.grass;
        } else if ((row + col) % 5 == 0) {
          terrain = TerrainType.desert;
        } else {
          terrain = TerrainType.mountain;
        }
        return TileData(row: row, col: col, terrain: terrain);
      });
    });
  }

  void _initializeVariantSeeds() {
    final random = math.Random(42);
    _variantSeeds = List.generate(rows, (_) {
      return List.generate(cols, (_) => random.nextInt(1 << 31));
    });
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Sync command centers from game service
    final gameState = gameService.gameState;
    if (gameState != null && gameState.commandCenters.isNotEmpty) {
      _commandCenters = gameState.commandCenters;
    }

    final double originX = size.x / 2;
    const double originY = 0;

    _renderTiles(canvas, originX, originY);
    _renderCommandCenters(canvas, originX, originY);
    _renderOverlays(canvas, originX, originY);
  }

  void _renderTiles(ui.Canvas canvas, double originX, double originY) {
    final TileSpriteManager? sprites = _tileSprites;
    final bool useSprites = sprites != null && sprites.totalLoadedCount > 0;

    final ui.Paint gridLinePaint = ui.Paint()
      ..color = const Color(0xFF565D6D)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final tileCenter = isoToScreen(r, c, originX, originY);
        final terrain = _tileData[r][c].terrain;

        if (useSprites) {
          final sprite = sprites.getSpriteForTerrain(terrain, _variantSeeds[r][c]);
          if (sprite != null) {
            // Render sprite centered on the tile center
            final topLeft = Vector2(
              tileCenter.x - tileSize.x / 2,
              tileCenter.y - tileSize.y / 2,
            );
            sprite.render(
              canvas,
              position: topLeft,
              size: tileSize,
            );
          } else {
            _renderFallbackDiamond(canvas, tileCenter, terrain);
          }
        } else {
          _renderFallbackDiamond(canvas, tileCenter, terrain);
        }

        // Outline for readability
        final diamond = _tileDiamond(tileCenter, 1.0);
        canvas.drawPath(diamond, gridLinePaint);
      }
    }
  }

  void _renderFallbackDiamond(ui.Canvas canvas, Vector2 center, TerrainType t) {
    final ui.Path diamond = _tileDiamond(center, 1.0);
    final ui.Paint fill = ui.Paint()..color = _terrainColor(t);
    canvas.drawPath(diamond, fill);
  }

  void _renderCommandCenters(ui.Canvas canvas, double originX, double originY) {
    final ui.Paint ccPaintP0 = ui.Paint()..color = const Color(0xCC8BC34A);
    final ui.Paint ccPaintP1 = ui.Paint()..color = const Color(0xCCE91E63);
    final ui.Paint gridLinePaint = ui.Paint()
      ..color = const Color(0xFF565D6D)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final CommandCenter cc in _commandCenters) {
      final int r0 = cc.topLeftRow.clamp(0, rows - 1);
      final int c0 = cc.topLeftCol.clamp(0, cols - 1);
      final List<Vector2> centers = <Vector2>[
        isoToScreen(r0, c0, originX, originY),
        if (c0 + 1 < cols) isoToScreen(r0, c0 + 1, originX, originY),
        if (r0 + 1 < rows) isoToScreen(r0 + 1, c0, originX, originY),
        if (r0 + 1 < rows && c0 + 1 < cols)
          isoToScreen(r0 + 1, c0 + 1, originX, originY),
      ];

      ui.Paint paint;
      if (cc.isDestroyed) {
        paint = ui.Paint()..color = const Color(0xCC666666);
      } else {
        paint = cc.playerIndex == 0 ? ccPaintP0 : ccPaintP1;
      }

      for (final Vector2 center in centers) {
        final ui.Path diamond = _tileDiamond(center, 1.0);
        canvas.drawPath(diamond, paint);
        canvas.drawPath(diamond, gridLinePaint);
      }
    }
  }

  void _renderOverlays(ui.Canvas canvas, double originX, double originY) {
    if (hoveredRow != null && hoveredCol != null) {
      final Vector2 center = isoToScreen(hoveredRow!, hoveredCol!, originX, originY);
      final hoverPath = _tileDiamond(center, 1.05);
      final hoverPaint = ui.Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = ui.PaintingStyle.fill;
      canvas.drawPath(hoverPath, hoverPaint);
    }

    if (highlightedRow != null && highlightedCol != null) {
      final Vector2 center = isoToScreen(highlightedRow!, highlightedCol!, originX, originY);
      final selectionPath = _tileDiamond(center, 1.1);
      final selectionPaint = ui.Paint()
        ..color = const Color(0xFF54C7EC).withValues(alpha: 0.3)
        ..style = ui.PaintingStyle.fill;
      final selectionBorder = ui.Paint()
        ..color = const Color(0xFF54C7EC)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(selectionPath, selectionPaint);
      canvas.drawPath(selectionPath, selectionBorder);
    }
  }

  // Interaction API compatible with other grid components
  void handleTap(Vector2 localPoint) {
    final Vector2? picked = _pickTileAt(localPoint);
    if (picked != null) {
      highlightedRow = picked.y.toInt();
      highlightedCol = picked.x.toInt();
    }
  }

  TileData? handleHover(Vector2 localPoint) {
    final Vector2? picked = _pickTileAt(localPoint);
    if (picked != null) {
      final int row = picked.y.toInt();
      final int col = picked.x.toInt();
      hoveredRow = row;
      hoveredCol = col;

      TileData tileData = _tileData[row][col];
      for (final CommandCenter cc in _commandCenters) {
        if (_isTileInCommandCenter(row, col, cc)) {
          tileData = tileData.copyWith(
            building: Building(
              name: 'Command Center',
              playerIndex: cc.playerIndex,
              health: cc.health,
              maxHealth: cc.maxHealth,
              type: BuildingType.commandCenter,
            ),
          );
          break;
        }
      }
      return tileData;
    }
    hoveredRow = null;
    hoveredCol = null;
    return null;
  }

  void clearHover() {
    hoveredRow = null;
    hoveredCol = null;
  }

  bool _isTileInCommandCenter(int row, int col, CommandCenter cc) {
    return row >= cc.topLeftRow &&
        row < cc.topLeftRow + 2 &&
        col >= cc.topLeftCol &&
        col < cc.topLeftCol + 2;
  }

  Vector2? _pickTileAt(Vector2 localPoint) {
    final double originX = size.x / 2;
    const double originY = 0;

    final double dx = localPoint.x - originX;
    final double dy = localPoint.y - originY;

    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    final double colF = (dy / halfH + dx / halfW) / 2.0;
    final double rowF = (dy / halfH - dx / halfW) / 2.0;

    final int rc = rowF.round();
    final int cc = colF.round();

    final List<math.Point<int>> candidates = <math.Point<int>>[
      math.Point<int>(cc, rc),
      math.Point<int>(cc, rc - 1),
      math.Point<int>(cc, rc + 1),
      math.Point<int>(cc - 1, rc),
      math.Point<int>(cc + 1, rc),
    ];

    for (final math.Point<int> cand in candidates) {
      final int col = cand.x;
      final int row = cand.y;
      if (row < 0 || col < 0 || row >= rows || col >= cols) continue;

      final Vector2 center = isoToScreen(row, col, originX, originY);
      final double ddx = (localPoint.x - center.x).abs();
      final double ddy = (localPoint.y - center.y).abs();
      if ((ddx / halfW) + (ddy / halfH) <= 1.02) {
        return Vector2(col.toDouble(), row.toDouble());
      }
    }
    return null;
  }

  Vector2 isoToScreen(int row, int col, double originX, double originY) {
    final double screenX = (col - row) * (tileSize.x / 2) + originX;
    final double screenY = (col + row) * (tileSize.y / 2) + originY;
    return Vector2(screenX, screenY);
  }

  ui.Path _tileDiamond(Vector2 center, double scale) {
    final double halfW = tileSize.x / 2 * scale;
    final double halfH = tileSize.y / 2 * scale;
    return ui.Path()
      ..moveTo(center.x, center.y - halfH)
      ..lineTo(center.x + halfW, center.y)
      ..lineTo(center.x, center.y + halfH)
      ..lineTo(center.x - halfW, center.y)
      ..close();
  }

  Color _terrainColor(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.grass:
        return const Color(0xFF4A5D23);
      case TerrainType.stone:
        return const Color(0xFF5A5A5A);
      case TerrainType.water:
        return const Color(0xFF2E5984);
      case TerrainType.desert:
        return const Color(0xFF8B7355);
      case TerrainType.forest:
        return const Color(0xFF2D4A22);
      case TerrainType.mountain:
        return const Color(0xFF4A3728);
    }
  }

  static List<CommandCenter> computeDefaultCommandCenters(int rows, int cols) {
    final int centerCol = cols ~/ 2;
    final int topLeftCol = (centerCol - 2).clamp(0, cols - 2);

    final int topPlayerRow = 1.clamp(0, rows - 2);
    final int bottomPlayerRow = (rows - 3).clamp(0, rows - 2);

    return <CommandCenter>[
      CommandCenter(
        playerIndex: 0,
        topLeftRow: topPlayerRow,
        topLeftCol: topLeftCol,
        health: 100,
        maxHealth: 100,
      ),
      CommandCenter(
        playerIndex: 1,
        topLeftRow: bottomPlayerRow,
        topLeftCol: topLeftCol,
        health: 100,
        maxHealth: 100,
      ),
    ];
  }
}

