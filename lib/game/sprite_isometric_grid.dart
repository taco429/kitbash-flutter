import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;

import '../services/game_service.dart';
import '../models/tile_data.dart';
import '../models/resources.dart' as resources;
import '../models/unit.dart';
import 'sprites/tile_sprite_manager.dart';

/// Isometric grid that renders each tile using sprites when available,
/// with graceful fallback to vector drawing if sprites are missing.
class SpriteIsometricGrid extends PositionComponent
    with HasGameReference<FlameGame> {
  final int rows;
  final int cols;
  final Vector2 tileSize;
  final GameService gameService;
  List<CommandCenter> _commandCenters;
  List<GameUnit> _units = [];

  /// When true, render tile sprites keeping their native aspect ratio
  /// (no isometric vertical compression). Useful for testing assets
  /// that were authored already in isometric perspective.
  final bool renderSpritesAtNativeAspect;

  /// If provided, force all tiles to this terrain type.
  final TerrainType? fillTerrain;

  int? highlightedRow;
  int? highlightedCol;
  int? hoveredRow;
  int? hoveredCol;
  bool _hoverInvalid = false;

  late List<List<TileData>> _tileData;
  late List<List<int>> _variantSeeds;

  TileSpriteManager? _tileSprites;

  // Command center visuals
  final double commandCenterHeight = 40.0;
  final double commandCenterYOffset = 4.0;
  static const String redCcSpritePath = 'orc_command_center.png';
  ui.Image? _redCcImage;
  static const String purpleCcSpritePath = 'spirit_command_center.png';
  ui.Image? _purpleCcImage;

  SpriteIsometricGrid({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.gameService,
    List<CommandCenter>? commandCenters,
    this.renderSpritesAtNativeAspect = false,
    this.fillTerrain,
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
    _tileSprites = await TileSpriteManager.load(images: game.images);

    // Load command center sprites (graceful fallback if missing)
    try {
      _redCcImage = await Flame.images.load(redCcSpritePath);
    } catch (_) {
      _redCcImage = null;
    }
    try {
      _purpleCcImage = await Flame.images.load(purpleCcSpritePath);
    } catch (_) {
      _purpleCcImage = null;
    }
  }

  void _initializeTileData() {
    final TerrainType? forceTerrain = fillTerrain;
    _tileData = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        TerrainType terrain;
        if (forceTerrain != null) {
          terrain = forceTerrain;
        } else {
          // Simple terrain distribution resembling earlier components
          final distance =
              ((row - rows / 2).abs() + (col - cols / 2).abs()) / 2;
          if (distance < 2) {
            terrain = TerrainType.grass;
          } else if (distance < 4) {
            terrain =
                (row + col) % 3 == 0 ? TerrainType.forest : TerrainType.grass;
          } else if (distance < 6) {
            terrain =
                (row + col) % 4 == 0 ? TerrainType.stone : TerrainType.grass;
          } else if ((row + col) % 5 == 0) {
            terrain = TerrainType.desert;
          } else {
            terrain = TerrainType.mountain;
          }
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

    // Sync command centers and units from game service
    final gameState = gameService.gameState;
    if (gameState != null) {
      if (gameState.commandCenters.isNotEmpty) {
        _commandCenters = gameState.commandCenters;
      }
      _units = gameState.units;
    }

    final double originX = size.x / 2;
    const double originY = 0;

    _renderTiles(canvas, originX, originY);
    _renderCommandCenters(canvas, originX, originY);
    _renderUnits(canvas, originX, originY);
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
          final sprite =
              sprites.getSpriteForTerrain(terrain, _variantSeeds[r][c]);
          if (sprite != null) {
            if (renderSpritesAtNativeAspect) {
              // Keep native aspect ratio; use tile width as baseline
              final double imgW = sprite.image.width.toDouble();
              final double imgH = sprite.image.height.toDouble();
              final double aspect = imgW > 0 ? (imgH / imgW) : 1.0;
              final double destW = tileSize.x;
              final double destH = destW * aspect;
              final Vector2 destSize = Vector2(destW, destH);
              final Vector2 topLeft = Vector2(
                tileCenter.x - destW / 2,
                tileCenter.y - destH / 2,
              );
              sprite.render(
                canvas,
                position: topLeft,
                size: destSize,
              );
            } else {
              // Render sprite centered on the tile center with isometric compression
              final topLeft = Vector2(
                tileCenter.x - tileSize.x / 2,
                tileCenter.y - tileSize.y / 2,
              );
              sprite.render(
                canvas,
                position: topLeft,
                size: tileSize,
              );
            }
          } else {
            _renderFallbackDiamond(canvas, tileCenter, terrain);
          }
        } else {
          _renderFallbackDiamond(canvas, tileCenter, terrain);
        }

        // Outline for readability (skip if drawing at native aspect to reduce visual confusion)
        if (!useSprites || !renderSpritesAtNativeAspect) {
          final diamond = _tileDiamond(tileCenter, 1.0);
          canvas.drawPath(diamond, gridLinePaint);
        }
      }
    }
  }

  void _renderFallbackDiamond(ui.Canvas canvas, Vector2 center, TerrainType t) {
    final ui.Path diamond = _tileDiamond(center, 1.0);
    final ui.Paint fill = ui.Paint()..color = _terrainColor(t);
    canvas.drawPath(diamond, fill);
  }

  void _renderUnits(ui.Canvas canvas, double originX, double originY) {
    final currentPlayerIndex = gameService.currentPlayerIndex;

    for (final unit in _units) {
      if (!unit.isAlive) continue;

      final unitCenter =
          isoToScreen(unit.position.row, unit.position.col, originX, originY);

      // Draw unit as a colored circle with direction indicator
      final isCurrentPlayer = unit.playerIndex == currentPlayerIndex;
      final unitColor = isCurrentPlayer ? Colors.blue : Colors.red;

      // Unit body
      final unitPaint = ui.Paint()
        ..color = unitColor.withValues(alpha: 0.8)
        ..style = ui.PaintingStyle.fill;

      final unitBorderPaint = ui.Paint()
        ..color = unitColor
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        ui.Offset(unitCenter.x, unitCenter.y - 10),
        12,
        unitPaint,
      );

      canvas.drawCircle(
        ui.Offset(unitCenter.x, unitCenter.y - 10),
        12,
        unitBorderPaint,
      );

      // Draw unit type indicator
      final letter = unit.cardId.contains('goblin')
          ? 'G'
          : unit.cardId.contains('ghoul')
              ? 'Z'
              : 'U';

      final textPainter = painting.TextPainter(
        text: painting.TextSpan(
          text: letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: painting.TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        ui.Offset(
          unitCenter.x - textPainter.width / 2,
          unitCenter.y - 10 - textPainter.height / 2,
        ),
      );

      // Draw health bar
      _renderUnitHealthBar(canvas, unit, unitCenter);

      // Draw stats
      _renderUnitStats(canvas, unit, unitCenter);

      // Draw direction indicator
      _renderUnitDirection(canvas, unit, unitCenter);
    }
  }

  void _renderUnitHealthBar(ui.Canvas canvas, GameUnit unit, Vector2 center) {
    const barWidth = 20.0;
    const barHeight = 3.0;
    const barY = -25.0;

    final bgPaint = ui.Paint()
      ..color = Colors.black54
      ..style = ui.PaintingStyle.fill;

    final healthPaint = ui.Paint()
      ..color = unit.healthPercentage > 0.6
          ? Colors.green
          : unit.healthPercentage > 0.3
              ? Colors.orange
              : Colors.red
      ..style = ui.PaintingStyle.fill;

    // Background
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(
          center.x - barWidth / 2,
          center.y + barY,
          barWidth,
          barHeight,
        ),
        const ui.Radius.circular(1.5),
      ),
      bgPaint,
    );

    // Health fill
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(
          center.x - barWidth / 2,
          center.y + barY,
          barWidth * unit.healthPercentage,
          barHeight,
        ),
        const ui.Radius.circular(1.5),
      ),
      healthPaint,
    );
  }

  void _renderUnitStats(ui.Canvas canvas, GameUnit unit, Vector2 center) {
    final statsText = '${unit.attack}/${unit.health}';

    final textPainter = painting.TextPainter(
      text: painting.TextSpan(
        text: statsText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: painting.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      ui.Offset(
        center.x - textPainter.width / 2,
        center.y + 2,
      ),
    );
  }

  void _renderUnitDirection(ui.Canvas canvas, GameUnit unit, Vector2 center) {
    // Draw a small arrow indicating direction
    final directionPaint = ui.Paint()
      ..color = Colors.white70
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const arrowLength = 8.0;
    const arrowOffset = 18.0;

    double angle = 0;
    switch (unit.direction) {
      case UnitDirection.north:
        angle = -math.pi / 2;
        break;
      case UnitDirection.northEast:
        angle = -math.pi / 4;
        break;
      case UnitDirection.east:
        angle = 0;
        break;
      case UnitDirection.southEast:
        angle = math.pi / 4;
        break;
      case UnitDirection.south:
        angle = math.pi / 2;
        break;
      case UnitDirection.southWest:
        angle = 3 * math.pi / 4;
        break;
      case UnitDirection.west:
        angle = math.pi;
        break;
      case UnitDirection.northWest:
        angle = -3 * math.pi / 4;
        break;
    }

    final startX = center.x + math.cos(angle) * arrowOffset;
    final startY = center.y - 10 + math.sin(angle) * arrowOffset;
    final endX = startX + math.cos(angle) * arrowLength;
    final endY = startY + math.sin(angle) * arrowLength;

    canvas.drawLine(
      ui.Offset(startX, startY),
      ui.Offset(endX, endY),
      directionPaint,
    );

    // Draw arrowhead
    const headLength = 3.0;
    final headAngle1 = angle + 3 * math.pi / 4;
    final headAngle2 = angle - 3 * math.pi / 4;

    canvas.drawLine(
      ui.Offset(endX, endY),
      ui.Offset(endX + math.cos(headAngle1) * headLength,
          endY + math.sin(headAngle1) * headLength),
      directionPaint,
    );

    canvas.drawLine(
      ui.Offset(endX, endY),
      ui.Offset(endX + math.cos(headAngle2) * headLength,
          endY + math.sin(headAngle2) * headLength),
      directionPaint,
    );
  }

  void _renderCommandCenters(ui.Canvas canvas, double originX, double originY) {
    for (final CommandCenter cc in _commandCenters) {
      final int r0 = cc.topLeftRow.clamp(0, rows - 1);
      final int c0 = cc.topLeftCol.clamp(0, cols - 1);

      // Anchor at the bottom-middle of the 2x2 footprint (midpoint between the two bottom tiles)
      final double anchorRow = r0 + 1.75;
      final double anchorCol = c0 + 1.75;
      final Vector2 footprintBottomCenter =
          isoToScreen(anchorRow, anchorCol, originX, originY);
      final Vector2 structureBaseCenter = Vector2(
        footprintBottomCenter.x,
        footprintBottomCenter.y - commandCenterYOffset,
      );
      final Vector2 topCenter = Vector2(
        structureBaseCenter.x,
        structureBaseCenter.y - commandCenterHeight,
      );

      // Always draw platform under command center
      _drawCommandCenterBase(
          canvas,
          r0,
          c0,
          originX,
          originY,
          cc.playerIndex == 0
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828));

      // Determine deck/faction
      final String? deckId = _getDeckIdForPlayer(cc.playerIndex);
      final bool deckIsPurple =
          deckId != null && deckId.toLowerCase().contains('purple');
      final bool deckIsRed =
          deckId != null && deckId.toLowerCase().contains('red');

      bool drewSprite = false;
      if (!cc.isDestroyed && deckIsPurple && _purpleCcImage != null) {
        _drawPurpleCommandCenterSprite(canvas, structureBaseCenter);
        drewSprite = true;
      } else if (!cc.isDestroyed && deckIsRed && _redCcImage != null) {
        _drawRedCommandCenterSprite(canvas, structureBaseCenter);
        drewSprite = true;
      }

      // Fallback: if no sprite drawn, keep simple overlay diamonds (legacy)
      if (!drewSprite) {
        final ui.Paint paint = ui.Paint()
          ..color = cc.isDestroyed
              ? const Color(0xCC666666)
              : (cc.playerIndex == 0
                  ? const Color(0xCC8BC34A)
                  : const Color(0xCCE91E63));
        final ui.Paint gridLinePaint = ui.Paint()
          ..color = const Color(0xFF565D6D)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1;
        final List<Vector2> centers = <Vector2>[
          isoToScreen(r0, c0, originX, originY),
          if (c0 + 1 < cols) isoToScreen(r0, c0 + 1, originX, originY),
          if (r0 + 1 < rows) isoToScreen(r0 + 1, c0, originX, originY),
          if (r0 + 1 < rows && c0 + 1 < cols)
            isoToScreen(r0 + 1, c0 + 1, originX, originY),
        ];
        for (final Vector2 center in centers) {
          final ui.Path diamond = _tileDiamond(center, 1.0);
          canvas.drawPath(diamond, paint);
          canvas.drawPath(diamond, gridLinePaint);
        }
      }

      // Draw health bar if alive
      if (!cc.isDestroyed) {
        final Color glowColor = cc.playerIndex == 0
            ? const Color(0xFF4CAF50)
            : const Color(0xFFEF5350);
        _drawEnhancedHealthBar(
            canvas, topCenter, cc.healthPercentage, glowColor);

        // Draw building level indicator
        if (cc.building != null) {
          _drawBuildingLevel(canvas, topCenter, cc.building!);
        }
      }
    }
  }

  void _renderOverlays(ui.Canvas canvas, double originX, double originY) {
    if (hoveredRow != null && hoveredCol != null) {
      final Vector2 center =
          isoToScreen(hoveredRow!, hoveredCol!, originX, originY);
      final hoverPath = _tileDiamond(center, 1.05);
      final hoverPaint = ui.Paint()
        ..color = (_hoverInvalid
                ? const Color(0xFF8B0000) // dark red
                : Colors.white)
            .withValues(alpha: 0.25)
        ..style = ui.PaintingStyle.fill;
      canvas.drawPath(hoverPath, hoverPaint);
    }

    if (highlightedRow != null && highlightedCol != null) {
      final Vector2 center =
          isoToScreen(highlightedRow!, highlightedCol!, originX, originY);
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

    // Render planned plays indicators
    final gs = gameService.gameState;
    if (gs != null && gs.plannedPlays.isNotEmpty) {
      gs.plannedPlays.forEach((playerIdx, plays) {
        for (final p in plays) {
          final Vector2 center = isoToScreen(p.row, p.col, originX, originY);
          final ui.Path indicator = _tileDiamond(center, 0.5);
          final ui.Paint paint = ui.Paint()
            ..color = (playerIdx == 0
                    ? const Color(0xFF54C7EC)
                    : const Color(0xFFE91E63))
                .withValues(alpha: 0.35)
            ..style = ui.PaintingStyle.fill;
          final ui.Paint border = ui.Paint()
            ..color = playerIdx == 0
                ? const Color(0xFF54C7EC)
                : const Color(0xFFE91E63)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawPath(indicator, paint);
          canvas.drawPath(indicator, border);
        }
      });
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
      _hoverInvalid = _computeHoverInvalid(row, col);

      TileData tileData = _tileData[row][col];
      for (final CommandCenter cc in _commandCenters) {
        if (_isTileInCommandCenter(row, col, cc)) {
          // Create a Building for display purposes with health info
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
    _hoverInvalid = false;
    return null;
  }

  void clearHover() {
    hoveredRow = null;
    hoveredCol = null;
  }

  bool _computeHoverInvalid(int row, int col) {
    // Prefer backend validation result when available
    final validation = gameService.targetValidation.value;
    final preview =
        gameService.cardPreview.value ?? gameService.pendingPlacement;
    if (validation != null && preview?.instance != null) {
      if (validation.row == row &&
          validation.col == col &&
          validation.cardInstanceId == preview!.instance!.instanceId) {
        return !validation.valid;
      }
    }
    final isUnit = preview?.card.isUnit == true;
    if (!isUnit) {
      // If not placing a unit, assume valid unless server says otherwise
      return false;
    }
    // Use planned plays and command centers to determine occupancy only for dynamic feedback.
    // Backed by server validation; this is a fast client-side best-effort.
    // Occupied if on command center footprint
    for (final cc in _commandCenters) {
      if (_isTileInCommandCenter(row, col, cc)) {
        return true;
      }
    }
    // Occupied if any planned play already targets this tile
    final gs = gameService.gameState;
    if (gs != null) {
      for (final entry in gs.plannedPlays.entries) {
        for (final p in entry.value) {
          if (p.row == row && p.col == col) return true;
        }
      }
    }
    return false;
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

  Vector2 isoToScreen(num row, num col, double originX, double originY) {
    final double r = row.toDouble();
    final double c = col.toDouble();
    final double screenX = (c - r) * (tileSize.x / 2) + originX;
    final double screenY = (c + r) * (tileSize.y / 2) + originY;
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

  // Command center helpers (mirroring EnhancedIsometricGrid behavior)

  String? _getDeckIdForPlayer(int playerIndex) {
    final gs = gameService.gameState;
    if (gs == null) return null;
    for (final ps in gs.playerStates) {
      if (ps.playerIndex == playerIndex) {
        final id = ps.deckId;
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  void _drawRedCommandCenterSprite(ui.Canvas canvas, Vector2 baseCenter) {
    final ui.Image? img = _redCcImage;
    if (img == null) return;
    _drawCommandCenterSpriteScaled(canvas, img, baseCenter);
  }

  void _drawPurpleCommandCenterSprite(ui.Canvas canvas, Vector2 baseCenter) {
    final ui.Image? img = _purpleCcImage;
    if (img == null) return;
    _drawCommandCenterSpriteScaled(canvas, img, baseCenter);
  }

  // Draws a command center sprite scaled to a 2x2 tile footprint, anchored at bottom-center
  void _drawCommandCenterSpriteScaled(
      ui.Canvas canvas, ui.Image img, Vector2 baseCenter) {
    final double imgW = img.width.toDouble();
    final double imgH = img.height.toDouble();

    final double destWidth = tileSize.x * 2.0;
    final double destHeight = destWidth * (imgH / imgW);

    final double left = baseCenter.x - destWidth / 2.0;
    final double top = baseCenter.y - destHeight;

    final ui.Rect src = ui.Rect.fromLTWH(0, 0, imgW, imgH);
    final ui.Rect dst = ui.Rect.fromLTWH(left, top, destWidth, destHeight);
    canvas.drawImageRect(img, src, dst, ui.Paint());
  }

  void _drawCommandCenterBase(ui.Canvas canvas, int row, int col,
      double originX, double originY, Color color) {
    // Prefer rendering with grass tile sprites when available; fallback to vector platform
    final TileSpriteManager? sprites = _tileSprites;
    final bool useSprites = sprites != null && sprites.totalLoadedCount > 0;

    for (int dr = 0; dr < 2; dr++) {
      for (int dc = 0; dc < 2; dc++) {
        final r = row + dr;
        final c = col + dc;
        if (r < rows && c < cols) {
          final Vector2 center = isoToScreen(r, c, originX, originY);

          if (useSprites) {
            // Always use a grass tile under command centers for now
            final sprite = sprites.getSpriteForTerrain(
                TerrainType.grass, _variantSeeds[r][c]);
            if (sprite != null) {
              final Vector2 topLeft = Vector2(
                center.x - tileSize.x / 2,
                center.y - tileSize.y / 2,
              );
              sprite.render(
                canvas,
                position: topLeft,
                size: tileSize,
              );
              continue;
            }
          }

          // Fallback vector platform if no sprites available
          final platformPath = _tileDiamond(center, 1.0);
          final platformPaint = ui.Paint()
            ..color = color.withValues(alpha: 0.8)
            ..style = ui.PaintingStyle.fill;
          canvas.drawPath(platformPath, platformPaint);
          final edgePaint = ui.Paint()
            ..color = const Color(0xFF000000).withValues(alpha: 0.3)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawPath(platformPath, edgePaint);
        }
      }
    }
  }

  void _drawBuildingLevel(
      ui.Canvas canvas, Vector2 position, resources.Building building) {
    // Position the level indicator to the right of the health bar
    final levelPosition = Vector2(position.x + 30, position.y - 50);

    // Background circle for level
    final bgPaint = ui.Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = ui.PaintingStyle.fill;

    final borderPaint = ui.Paint()
      ..color = _getLevelColor(building.level)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw background circle
    canvas.drawCircle(
      ui.Offset(levelPosition.x, levelPosition.y),
      12,
      bgPaint,
    );

    // Draw border
    canvas.drawCircle(
      ui.Offset(levelPosition.x, levelPosition.y),
      12,
      borderPaint,
    );

    // Draw level text
    final textPainter = painting.TextPainter(
      text: painting.TextSpan(
        text: 'Lv${building.level.value}',
        style: painting.TextStyle(
          color: _getLevelColor(building.level),
          fontSize: 10,
          fontWeight: painting.FontWeight.bold,
        ),
      ),
      textDirection: painting.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      ui.Offset(
        levelPosition.x - textPainter.width / 2,
        levelPosition.y - textPainter.height / 2,
      ),
    );

    // Draw upgrade progress if not max level
    if (building.turnsUntilUpgrade > 0) {
      final progressText = '${3 - building.turnsUntilUpgrade}/3';
      final progressPainter = painting.TextPainter(
        text: painting.TextSpan(
          text: progressText,
          style: const painting.TextStyle(
            color: Colors.white70,
            fontSize: 8,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      progressPainter.layout();
      progressPainter.paint(
        canvas,
        ui.Offset(
          levelPosition.x - progressPainter.width / 2,
          levelPosition.y + 14,
        ),
      );
    }
  }

  Color _getLevelColor(resources.BuildingLevel level) {
    switch (level) {
      case resources.BuildingLevel.level1:
        return Colors.grey;
      case resources.BuildingLevel.level2:
        return Colors.blue;
      case resources.BuildingLevel.level3:
        return Colors.orange;
    }
  }

  void _drawEnhancedHealthBar(
      ui.Canvas canvas, Vector2 center, double healthPercent, Color glowColor) {
    const double barWidth = 50.0;
    const double barHeight = 8.0;
    const double barOffsetY = -50.0;

    final double barX = center.x - barWidth / 2;
    final double barY = center.y + barOffsetY;

    final bgRect =
        ui.Rect.fromLTWH(barX - 2, barY - 2, barWidth + 4, barHeight + 4);
    final bgPaint = ui.Paint()
      ..color = const Color(0x80000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(4)),
      bgPaint,
    );

    final fillWidth = barWidth * healthPercent;
    final fillRect = ui.Rect.fromLTWH(barX, barY, fillWidth, barHeight);

    Color healthColor;
    if (healthPercent > 0.6) {
      healthColor = const Color(0xFF4CAF50);
    } else if (healthPercent > 0.3) {
      healthColor = const Color(0xFFFFC107);
    } else {
      healthColor = const Color(0xFFF44336);
    }

    final fillPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(barX, barY),
        ui.Offset(barX + fillWidth, barY),
        [
          _brightenColor(healthColor, 0.3),
          healthColor,
          _darkenColor(healthColor, 0.2),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(3)),
      fillPaint,
    );

    if (healthPercent > 0 && healthPercent < 1) {
      final glowPaint = ui.Paint()
        ..color = glowColor.withValues(alpha: 0.15)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(3)),
        glowPaint,
      );
    }

    final borderPaint = ui.Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const ui.Radius.circular(3),
      ),
      borderPaint,
    );
  }

  Color _brightenColor(Color color, double factor) {
    return Color.fromARGB(
      (color.a * 255.0).round() & 0xff,
      ((color.r * 255.0).round() + ((255 - (color.r * 255.0).round()) * factor))
          .round()
          .clamp(0, 255),
      ((color.g * 255.0).round() + ((255 - (color.g * 255.0).round()) * factor))
          .round()
          .clamp(0, 255),
      ((color.b * 255.0).round() + ((255 - (color.b * 255.0).round()) * factor))
          .round()
          .clamp(0, 255),
    );
  }

  Color _darkenColor(Color color, double factor) {
    return Color.fromARGB(
      (color.a * 255.0).round() & 0xff,
      ((color.r * 255.0).round() * (1 - factor)).round().clamp(0, 255),
      ((color.g * 255.0).round() * (1 - factor)).round().clamp(0, 255),
      ((color.b * 255.0).round() * (1 - factor)).round().clamp(0, 255),
    );
  }

  // Client-side default CC calculator removed; backend is authoritative.
}
