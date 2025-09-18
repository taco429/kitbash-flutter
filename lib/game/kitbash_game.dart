import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../models/tile_data.dart';
import 'components/fps_counter.dart';
import 'sprite_isometric_grid.dart';

class KitbashGame extends FlameGame with TapCallbacks, HasGameReference {
  final String gameId;
  final GameService gameService;
  PositionComponent? _grid;
  FpsCounter? _fpsCounter;
  // Vertical offset for FPS counter to sit below the opponent overlay
  final double _fpsTopOffset = 200.0;
  bool useSpriteGrid = true; // Toggle: sprite-based tiles when available

  // Two-level zoom support
  static const double zoomedOutScale = 1.35;
  static const double zoomedInScale = 2.2;
  bool _isZoomedIn = false;
  double _currentScale = zoomedOutScale;

  KitbashGame({required this.gameId, required this.gameService});

  @override
  Color backgroundColor() =>
      const Color(0xFF1A1A1A); // Darker background for better contrast

  @override
  Future<void> onLoad() async {
    // Initialize game components

    // Add an enhanced isometric grid to the scene
    const int rows = 12;
    const int cols = 12;

    if (useSpriteGrid) {
      final SpriteIsometricGrid spriteGrid = SpriteIsometricGrid(
        rows: rows,
        cols: cols,
        tileSize: Vector2(64, 32),
        gameService: gameService,
        // Enable native-aspect rendering to test unskewed PNGs
        renderSpritesAtNativeAspect: true,
        // Force all tiles to grass for now
        fillTerrain: TerrainType.grass,
      );

      spriteGrid.anchor = Anchor.center;
      spriteGrid.position = size / 2;
      spriteGrid.scale = Vector2.all(_currentScale);

      _grid = spriteGrid;
      add(spriteGrid);
    } else {
      final IsometricGridComponent isoGrid = IsometricGridComponent(
        rows: rows,
        cols: cols,
        tileSize: Vector2(64, 32),
        gameService: gameService,
      );

      isoGrid.anchor = Anchor.center;
      isoGrid.position = size / 2;
      isoGrid.scale = Vector2.all(_currentScale);

      _grid = isoGrid;
      add(isoGrid);
    }

    // Add FPS counter to the top-right corner (pushed down below opponent overlay)
    _fpsCounter = FpsCounter(
      position: Vector2(size.x - 10, _fpsTopOffset),
      anchor: Anchor.topRight,
    );
    add(_fpsCounter!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Keep grid centered in viewport
    final PositionComponent? grid = _grid;
    if (grid != null) {
      grid.position = this.size / 2;
    }
    // Update FPS counter position to stay in top-right corner
    if (_fpsCounter != null) {
      _fpsCounter!.position = Vector2(size.x - 10, _fpsTopOffset);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Forward tap to grid if present
    final PositionComponent? grid = _grid;
    if (grid != null) {
      final Vector2 localPoint = grid.parentToLocal(event.localPosition);
      if (grid is SpriteIsometricGrid) {
        grid.handleTap(localPoint);
      } else if (grid is IsometricGridComponent) {
        grid.handleTap(localPoint);
      }
    }
  }

  // Hover updates are driven by the surrounding MouseRegion in the widget tree

  // Note: Hover handling is managed by the surrounding widget via MouseRegion

  /// Resolves the hovered tile given a position in the GameWidget's
  /// local coordinate space and updates hover highlight in the grid.
  /// Returns the [TileData] at that position or null if out of bounds.
  TileData? resolveHoverAt(Offset localOffset) {
    final PositionComponent? grid = _grid;
    if (grid == null) return null;

    final Vector2 parentLocal = Vector2(localOffset.dx, localOffset.dy);
    final Vector2 gridLocal = grid.parentToLocal(parentLocal);

    if (grid is SpriteIsometricGrid) {
      return grid.handleHover(gridLocal);
    } else if (grid is IsometricGridComponent) {
      return grid.handleHover(gridLocal);
    }
    return null;
  }

  /// Clears any active hover highlight in the grid
  void clearHover() {
    final PositionComponent? grid = _grid;
    if (grid is SpriteIsometricGrid) {
      grid.clearHover();
    } else if (grid is IsometricGridComponent) {
      grid.clearHover();
    }
  }

  /// Selects the tile at the given UI-local offset (relative to GameWidget)
  void selectAt(Offset localOffset) {
    final PositionComponent? grid = _grid;
    if (grid == null) return;

    final Vector2 parentLocal = Vector2(localOffset.dx, localOffset.dy);
    final Vector2 gridLocal = grid.parentToLocal(parentLocal);

    if (grid is SpriteIsometricGrid) {
      grid.handleTap(gridLocal);
    } else if (grid is IsometricGridComponent) {
      grid.handleTap(gridLocal);
    }
  }

  /// Sets the zoom level to either zoomed-in or zoomed-out.
  /// This scales the isometric grid while keeping it centered.
  void setZoomLevel(bool zoomedIn) {
    _isZoomedIn = zoomedIn;
    _currentScale = zoomedIn ? zoomedInScale : zoomedOutScale;
    final PositionComponent? grid = _grid;
    if (grid != null) {
      grid.scale = Vector2.all(_currentScale);
      grid.position = size / 2;
    }
  }

  /// Toggles between zoomed-in and zoomed-out levels.
  void toggleZoom() => setZoomLevel(!_isZoomedIn);

  bool get isZoomedIn => _isZoomedIn;
}

// Remove the old CommandCenter class since we now use the one from game_service.dart

class IsometricGridComponent extends PositionComponent {
  final int rows;
  final int cols;
  final Vector2 tileSize;
  final GameService gameService;
  List<CommandCenter> _commandCenters;

  int? highlightedRow;
  int? highlightedCol;

  // Hover state
  int? hoveredRow;
  int? hoveredCol;
  bool _hoverInvalid = false;

  // Debug overlay state
  bool debugHoverOverlay = false;
  Vector2? _debugLocalPoint;
  double? _debugRowF;
  double? _debugColF;
  int? _debugRc;
  int? _debugCc;
  List<math.Point<int>> _debugCandidates = <math.Point<int>>[];
  math.Point<int>? _debugPickedRC;
  Vector2? _debugPickedCenter;

  // Tile data storage - for now we'll generate sample terrain
  late List<List<TileData>> _tileData;

  IsometricGridComponent({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.gameService,
    List<CommandCenter>? commandCenters,
  }) : _commandCenters = commandCenters ?? <CommandCenter>[] {
    // Size is approximate bounding box
    size = Vector2(
      (cols + rows) * (tileSize.x / 2),
      (cols + rows) * (tileSize.y / 2),
    );

    // Initialize tile data with sample terrain
    _initializeTileData();
  }

  void _initializeTileData() {
    _tileData = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        // Generate varied terrain for demonstration
        TerrainType terrain;
        final distance = ((row - rows / 2).abs() + (col - cols / 2).abs()) / 2;

        if (distance < 2) {
          terrain = TerrainType.grass;
        } else if (distance < 4) {
          terrain =
              (row + col) % 3 == 0 ? TerrainType.forest : TerrainType.grass;
        } else if (distance < 6) {
          terrain =
              (row + col) % 4 == 0 ? TerrainType.stone : TerrainType.grass;
        } else {
          terrain = TerrainType.mountain;
        }

        return TileData(
          row: row,
          col: col,
          terrain: terrain,
        );
      });
    });
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Update command centers from game service
    final gameState = gameService.gameState;
    if (gameState != null && gameState.commandCenters.isNotEmpty) {
      _commandCenters = gameState.commandCenters;
    }

    // Removed unused basePaint variable
    final ui.Paint gridLinePaint = ui.Paint()
      ..color = const Color(0xFF565D6D)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    final ui.Paint highlightPaint = ui.Paint()..color = const Color(0x8854C7EC);
    final ui.Paint ccPaintP0 = ui.Paint()..color = const Color(0xCC8BC34A);
    final ui.Paint ccPaintP1 = ui.Paint()..color = const Color(0xCCE91E63);
    final ui.Paint healthBarBg = ui.Paint()..color = const Color(0xAA000000);
    final ui.Paint healthBarFill = ui.Paint()..color = const Color(0xAA4CAF50);
    final ui.Paint healthBarLow = ui.Paint()..color = const Color(0xAAF44336);

    // Origin at top center for a nice layout inside the component bounds
    final double originX = size.x / 2;
    const double originY = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final Vector2 center = isoToScreen(r, c, originX, originY);
        final ui.Path diamond = _tileDiamond(center);

        // Get terrain-based color
        final terrainColor = getTerrainColor(_tileData[r][c].terrain);
        final terrainPaint = ui.Paint()..color = terrainColor;

        // Fill with terrain color
        canvas.drawPath(diamond, terrainPaint);
        // Stroke
        canvas.drawPath(diamond, gridLinePaint);

        // Apply hover highlight
        if (hoveredRow == r && hoveredCol == c) {
          final ui.Paint hoverPaintDyn = ui.Paint()
            ..color = (_hoverInvalid
                ? const Color(0xFF8B0000)
                : const Color(0x66FFFFFF));
          canvas.drawPath(diamond, hoverPaintDyn);
        }

        // Apply selection highlight (higher priority than hover)
        if (highlightedRow == r && highlightedCol == c) {
          canvas.drawPath(diamond, highlightPaint);
        }
      }
    }

    // Render planned play indicators
    final gs = gameService.gameState;
    if (gs != null && gs.plannedPlays.isNotEmpty) {
      for (final entry in gs.plannedPlays.entries) {
        final playerIdx = entry.key;
        for (final p in entry.value) {
          if (p.row < 0 || p.col < 0 || p.row >= rows || p.col >= cols) {
            continue;
          }
          final Vector2 center = isoToScreen(p.row, p.col, originX, originY);
          final ui.Path indicator = _tileDiamond(center);
          final ui.Path inner = _tileDiamond(Vector2(center.x, center.y));
          final ui.Paint fill = ui.Paint()
            ..color = (playerIdx == 0
                    ? const Color(0xFF54C7EC)
                    : const Color(0xFFE91E63))
                .withValues(alpha: 0.25)
            ..style = ui.PaintingStyle.fill;
          final ui.Paint border = ui.Paint()
            ..color = playerIdx == 0
                ? const Color(0xFF54C7EC)
                : const Color(0xFFE91E63)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawPath(indicator, fill);
          canvas.drawPath(inner, border);
        }
      }
    }

    // Render command centers as 2x2 overlays with health bars
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

      // Choose color based on health
      ui.Paint paint;
      if (cc.isDestroyed) {
        paint = ui.Paint()
          ..color = const Color(0xCC666666); // Gray for destroyed
      } else {
        paint = cc.playerIndex == 0 ? ccPaintP0 : ccPaintP1;
      }

      // Draw command center tiles
      for (final Vector2 center in centers) {
        final ui.Path diamond = _tileDiamond(center);
        canvas.drawPath(diamond, paint);
        canvas.drawPath(diamond, gridLinePaint);
      }

      // Draw health bar above the command center
      if (centers.isNotEmpty && !cc.isDestroyed) {
        final Vector2 topCenter = centers[0]; // Use top-left tile as reference
        _drawHealthBar(
          canvas,
          topCenter,
          cc.healthPercentage,
          healthBarBg,
          cc.healthPercentage > 0.3 ? healthBarFill : healthBarLow,
        );
      }
    }

    // Debug overlay for hover picking visualization
    if (debugHoverOverlay && _debugLocalPoint != null) {
      final ui.Paint red = ui.Paint()
        ..color = const Color(0xFFFF3B30)
        ..style = ui.PaintingStyle.fill;
      final ui.Paint blue = ui.Paint()
        ..color = const Color(0xFF007AFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final ui.Paint yellow = ui.Paint()
        ..color = const Color(0xFFFFCC00)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final ui.Paint green = ui.Paint()
        ..color = const Color(0xFF34C759)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0;

      // Cursor local point
      canvas.drawCircle(
          ui.Offset(_debugLocalPoint!.x, _debugLocalPoint!.y), 3, red);

      // Draw candidate centers
      final double originX = size.x / 2;
      const double originY = 0;
      for (final math.Point<int> cand in _debugCandidates) {
        final Vector2 center = isoToScreen(cand.y, cand.x, originX, originY);
        canvas.drawCircle(ui.Offset(center.x, center.y), 4, blue);
      }

      // Rounded tile center highlight
      if (_debugRc != null && _debugCc != null) {
        final Vector2 roundedCenter =
            isoToScreen(_debugRc!, _debugCc!, originX, originY);
        canvas.drawCircle(
            ui.Offset(roundedCenter.x, roundedCenter.y), 6, yellow);
      }

      // Picked tile outline
      if (_debugPickedCenter != null) {
        final ui.Path pickedDiamond = _tileDiamond(_debugPickedCenter!);
        canvas.drawPath(pickedDiamond, green);
      }

      // Optional: textual debug (kept minimal)
      final textPaint = TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      );
      final String info =
          'rowF=${_debugRowF?.toStringAsFixed(2)} colF=${_debugColF?.toStringAsFixed(2)}\n'
          'rc=$_debugRc cc=$_debugCc hovered=($hoveredRow,$hoveredCol)\n'
          'picked=${_debugPickedRC != null ? '(${_debugPickedRC!.y},${_debugPickedRC!.x})' : 'none'}';
      textPaint.render(
        canvas,
        info,
        Vector2(6, 6),
      );
    }
  }

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

      // Get enhanced tile data with command center info if present
      TileData tileData = _tileData[row][col];

      // Check if this tile has a command center
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

    // Clear hover if outside grid
    hoveredRow = null;
    hoveredCol = null;
    _hoverInvalid = false;
    return null;
  }

  bool _isTileInCommandCenter(int row, int col, CommandCenter cc) {
    return row >= cc.topLeftRow &&
        row < cc.topLeftRow + 2 &&
        col >= cc.topLeftCol &&
        col < cc.topLeftCol + 2;
  }

  bool _computeHoverInvalid(int row, int col) {
    // Prefer backend validation
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
      return false;
    }
    // Command center check
    for (final CommandCenter cc in _commandCenters) {
      if (_isTileInCommandCenter(row, col, cc)) {
        return true;
      }
    }
    // Planned plays occupancy check
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

  Color getTerrainColor(TerrainType terrain) {
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

  Vector2 isoToScreen(int row, int col, double originX, double originY) {
    final double screenX = (col - row) * (tileSize.x / 2) + originX;
    final double screenY = (col + row) * (tileSize.y / 2) + originY;
    return Vector2(screenX, screenY);
  }

  ui.Path _tileDiamond(Vector2 center) {
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;
    return ui.Path()
      ..moveTo(center.x, center.y - halfH)
      ..lineTo(center.x + halfW, center.y)
      ..lineTo(center.x, center.y + halfH)
      ..lineTo(center.x - halfW, center.y)
      ..close();
  }

  void _drawHealthBar(
    ui.Canvas canvas,
    Vector2 center,
    double healthPercentage,
    ui.Paint bgPaint,
    ui.Paint fillPaint,
  ) {
    const double barWidth = 40.0;
    const double barHeight = 6.0;
    const double barOffsetY = -25.0; // Position above the command center

    final double barX = center.x - barWidth / 2;
    final double barY = center.y + barOffsetY;

    // Draw background
    final ui.Rect bgRect = ui.Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(3)),
      bgPaint,
    );

    // Draw health fill
    final double fillWidth = barWidth * healthPercentage;
    final ui.Rect fillRect = ui.Rect.fromLTWH(barX, barY, fillWidth, barHeight);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(3)),
      fillPaint,
    );

    // Draw border
    final ui.Paint borderPaint = ui.Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(3)),
      borderPaint,
    );
  }

  // Removed old _screenToIso; picking now uses precise diamond hit testing in _pickTileAt.

  /// Picks the tile under a local point using a simple inverse transform
  /// and a single diamond check with minimal neighbor fallback.
  Vector2? _pickTileAt(Vector2 localPoint) {
    final double originX = size.x / 2;
    const double originY = 0;

    final double dx = localPoint.x - originX;
    // Use direct Y to match render mapping precisely
    final double dy = localPoint.y - originY;

    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    // Invert isoToScreen mapping
    final double colF = (dy / halfH + dx / halfW) / 2.0;
    final double rowF = (dy / halfH - dx / halfW) / 2.0;

    final int rc = rowF.round();
    final int cc = colF.round();

    // Store debug info
    _debugLocalPoint = localPoint.clone();
    _debugRowF = rowF;
    _debugColF = colF;
    _debugRc = rc;
    _debugCc = cc;

    // Check rounded tile first, then direct neighbors
    final List<math.Point<int>> candidates = <math.Point<int>>[
      math.Point<int>(cc, rc),
      math.Point<int>(cc, rc - 1),
      math.Point<int>(cc, rc + 1),
      math.Point<int>(cc - 1, rc),
      math.Point<int>(cc + 1, rc),
    ];
    _debugCandidates = candidates;

    for (final math.Point<int> cand in candidates) {
      final int col = cand.x;
      final int row = cand.y;
      if (row < 0 || col < 0 || row >= rows || col >= cols) continue;

      final Vector2 center = isoToScreen(row, col, originX, originY);
      final double ddx = (localPoint.x - center.x).abs();
      final double ddy = (localPoint.y - center.y).abs();
      if ((ddx / halfW) + (ddy / halfH) <= 1.02) {
        _debugPickedRC = cand;
        _debugPickedCenter = center;
        return Vector2(col.toDouble(), row.toDouble());
      }
    }

    _debugPickedRC = null;
    _debugPickedCenter = null;
    return null;
  }

  // Client-side default CC calculator removed; backend is authoritative.
}

extension on IsometricGridComponent {
  /// Clears the current hover state on the grid.
  void clearHover() {
    hoveredRow = null;
    hoveredCol = null;
  }
}
