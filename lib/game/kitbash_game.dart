import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../models/tile_data.dart';

class KitbashGame extends FlameGame with TapCallbacks {
  final String gameId;
  final GameService gameService;
  IsometricGridComponent? _grid;

  KitbashGame({required this.gameId, required this.gameService});

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

  @override
  Future<void> onLoad() async {
    // Initialize game components

    // Add an isometric grid to the scene
    const int rows = 12;
    const int cols = 12;
    final IsometricGridComponent isoGrid = IsometricGridComponent(
      rows: rows,
      cols: cols,
      tileSize: Vector2(64, 32),
      commandCenters:
          IsometricGridComponent.computeDefaultCommandCenters(rows, cols),
      gameService: gameService,
    );

    // Center the grid in the current viewport
    isoGrid.anchor = Anchor.center;
    isoGrid.position = size / 2;

    _grid = isoGrid;
    add(isoGrid);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Keep grid centered in viewport
    final IsometricGridComponent? grid = _grid;
    if (grid != null) {
      grid.position = this.size / 2;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Forward tap to grid if present
    final IsometricGridComponent? grid = _grid;
    if (grid != null) {
      final Vector2 localPoint = grid.parentToLocal(event.localPosition);
      grid.handleTap(localPoint);
    }
  }

  // Hover updates are driven by the surrounding MouseRegion in the widget tree

  // Note: Hover handling is managed by the surrounding widget via MouseRegion

  /// Resolves the hovered tile given a position in the GameWidget's
  /// local coordinate space and updates hover highlight in the grid.
  /// Returns the [TileData] at that position or null if out of bounds.
  TileData? resolveHoverAt(Offset localOffset) {
    final IsometricGridComponent? grid = _grid;
    if (grid == null) return null;

    final Vector2 parentLocal = Vector2(localOffset.dx, localOffset.dy);
    final Vector2 gridLocal = grid.parentToLocal(parentLocal);
    return grid.handleHover(gridLocal);
  }

  /// Clears any active hover highlight in the grid
  void clearHover() {
    _grid?.clearHover();
  }
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
    final ui.Paint hoverPaint = ui.Paint()..color = const Color(0x66FFFFFF);
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
        _render3DTile(canvas, r, c, originX, originY,
            gridLinePaint: gridLinePaint, hoverPaint: hoverPaint, highlightPaint: highlightPaint);
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

      // Draw command center tiles with beveled plates
      for (final Vector2 center in centers) {
        _drawBeveledPlate(canvas, center, paint.color, gridLinePaint.color);
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
    return null;
  }

  bool _isTileInCommandCenter(int row, int col, CommandCenter cc) {
    return row >= cc.topLeftRow &&
        row < cc.topLeftRow + 2 &&
        col >= cc.topLeftCol &&
        col < cc.topLeftCol + 2;
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

  void _render3DTile(
    ui.Canvas canvas,
    int row,
    int col,
    double originX,
    double originY, {
    required ui.Paint gridLinePaint,
    required ui.Paint hoverPaint,
    required ui.Paint highlightPaint,
  }) {
    final Vector2 center = isoToScreen(row, col, originX, originY);
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    final ui.Offset top = ui.Offset(center.x, center.y - halfH);
    final ui.Offset right = ui.Offset(center.x + halfW, center.y);
    final ui.Offset bottom = ui.Offset(center.x, center.y + halfH);
    final ui.Offset left = ui.Offset(center.x - halfW, center.y);

    final TerrainType terrain = _tileData[row][col].terrain;
    final ui.Color baseColor = getTerrainColor(terrain);

    final double extrude = _extrusionHeightForTerrain(terrain);
    final ui.Offset e = ui.Offset(0, extrude);

    // Side faces (draw first so they appear behind the top)
    final ui.Paint leftSidePaint = ui.Paint()
      ..color = _shadeColor(baseColor, 0.7)
      ..style = ui.PaintingStyle.fill;
    final ui.Paint rightSidePaint = ui.Paint()
      ..color = _shadeColor(baseColor, 0.8)
      ..style = ui.PaintingStyle.fill;

    // Left side face: quad (left -> bottom -> bottom+e -> left+e)
    final ui.Path leftSide = ui.Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo((bottom + e).dx, (bottom + e).dy)
      ..lineTo((left + e).dx, (left + e).dy)
      ..close();
    canvas.drawPath(leftSide, leftSidePaint);

    // Right side face: quad (right -> bottom -> bottom+e -> right+e)
    final ui.Path rightSide = ui.Path()
      ..moveTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo((bottom + e).dx, (bottom + e).dy)
      ..lineTo((right + e).dx, (right + e).dy)
      ..close();
    canvas.drawPath(rightSide, rightSidePaint);

    // Soft shadow beneath tile (simple darkened trapezoid under bottom edge)
    final ui.Paint shadowPaint = ui.Paint()
      ..color = const ui.Color(0x22000000)
      ..style = ui.PaintingStyle.fill;
    final double shadowDepth = extrude * 0.6;
    final ui.Path shadow = ui.Path()
      ..moveTo(left.dx, left.dy + extrude)
      ..lineTo(right.dx, right.dy + extrude)
      ..lineTo(right.dx, right.dy + extrude + shadowDepth)
      ..lineTo(left.dx, left.dy + extrude + shadowDepth)
      ..close();
    canvas.drawPath(shadow, shadowPaint);

    // Top face with gradient
    final ui.Path topDiamond = _tileDiamond(center);
    final ui.Paint topPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x - halfW * 0.5, center.y - halfH * 0.7),
        ui.Offset(center.x + halfW * 0.5, center.y + halfH * 0.7),
        <ui.Color>[
          _shadeColor(baseColor, 1.12),
          _shadeColor(baseColor, 0.90),
        ],
      );
    canvas.drawPath(topDiamond, topPaint);

    // Ambient occlusion on bottom edges
    final ui.Paint aoPaint = ui.Paint()
      ..color = const ui.Color(0x55000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(left, bottom, aoPaint);
    canvas.drawLine(bottom, right, aoPaint);

    // Terrain-specific details
    if (terrain == TerrainType.water) {
      _drawWaterGloss(canvas, top: top, left: left, center: center, halfW: halfW, halfH: halfH);
    } else if (terrain == TerrainType.stone || terrain == TerrainType.mountain) {
      _drawRockNoise(canvas, topDiamond, baseColor, intensity: 0.08);
    } else if (terrain == TerrainType.forest) {
      _drawLeafSpeckles(canvas, topDiamond, baseColor, intensity: 0.06);
    } else if (terrain == TerrainType.grass) {
      _drawGrassTexture(canvas, topDiamond, baseColor, density: 1.0);
    }

    // Grid stroke on top face
    canvas.drawPath(topDiamond, gridLinePaint);

    // Hover/Selection effects
    final bool isHovered = hoveredRow == row && hoveredCol == col;
    final bool isSelected = highlightedRow == row && highlightedCol == col;
    if (isHovered) {
      // Soft outer glow
      final ui.Paint glow = ui.Paint()
        ..color = const ui.Color(0x66FFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.0);
      canvas.drawPath(topDiamond, glow);
      canvas.drawPath(topDiamond, hoverPaint);
    }
    if (isSelected) {
      final ui.Paint rim = ui.Paint()
        ..color = const ui.Color(0xFF54C7EC)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(topDiamond, rim);
      canvas.drawPath(topDiamond, highlightPaint);
    }
  }

  void _drawBeveledPlate(
    ui.Canvas canvas,
    Vector2 center,
    ui.Color fillColor,
    ui.Color outlineColor,
  ) {
    final double halfW = tileSize.x / 2 * 0.9;
    final double halfH = tileSize.y / 2 * 0.9;

    final ui.Offset top = ui.Offset(center.x, center.y - halfH);
    final ui.Offset right = ui.Offset(center.x + halfW, center.y);
    final ui.Offset bottom = ui.Offset(center.x, center.y + halfH);
    final ui.Offset left = ui.Offset(center.x - halfW, center.y);

    final ui.Path plate = ui.Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    final ui.Paint platePaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x - halfW * 0.4, center.y - halfH * 0.6),
        ui.Offset(center.x + halfW * 0.4, center.y + halfH * 0.6),
        <ui.Color>[
          _shadeColor(fillColor, 1.10),
          _shadeColor(fillColor, 0.92),
        ],
      );
    canvas.drawPath(plate, platePaint);

    // Bevel highlights: light on top-left, dark on bottom-right
    final ui.Paint bevelLight = ui.Paint()
      ..color = const ui.Color(0x66FFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final ui.Paint bevelDark = ui.Paint()
      ..color = const ui.Color(0x55000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(left, top, bevelLight);
    canvas.drawLine(top, right, bevelLight);
    canvas.drawLine(right, bottom, bevelDark);
    canvas.drawLine(bottom, left, bevelDark);

    // Outer rim
    final ui.Paint rim = ui.Paint()
      ..color = outlineColor
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(plate, rim);
  }

  void _drawWaterGloss(
    ui.Canvas canvas, {
    required ui.Offset top,
    required ui.Offset left,
    required Vector2 center,
    required double halfW,
    required double halfH,
  }) {
    final double glossW = halfW * 0.9;
    final double glossH = halfH * 0.6;
    final ui.Rect glossRect = ui.Rect.fromCenter(
      center: ui.Offset(center.x - halfW * 0.15, center.y - halfH * 0.35),
      width: glossW,
      height: glossH,
    );
    final ui.Paint glossPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        glossRect.center,
        glossW * 0.6,
        <ui.Color>[
          const ui.Color(0x33FFFFFF),
          const ui.Color(0x00FFFFFF),
        ],
      )
      ..blendMode = ui.BlendMode.screen;
    canvas.drawOval(glossRect, glossPaint);
  }

  void _drawRockNoise(
    ui.Canvas canvas,
    ui.Path topDiamond,
    ui.Color baseColor, {
    required double intensity,
  }) {
    // Simple stipple using two overlaid strokes for texture
    final ui.Paint noise = ui.Paint()
      ..color = _shadeColor(baseColor, 1.2).withOpacity(intensity)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final ui.Rect bounds = topDiamond.getBounds();
    for (double y = bounds.top + 2; y < bounds.bottom - 2; y += 4) {
      canvas.drawLine(
        ui.Offset(bounds.left + 3, y),
        ui.Offset(bounds.right - 3, y + 0.5),
        noise,
      );
    }
  }

  void _drawLeafSpeckles(
    ui.Canvas canvas,
    ui.Path topDiamond,
    ui.Color baseColor, {
    required double intensity,
  }) {
    final ui.Paint speck = ui.Paint()
      ..color = _shadeColor(baseColor, 1.25).withOpacity(intensity)
      ..style = ui.PaintingStyle.fill;
    final ui.Rect b = topDiamond.getBounds();
    for (double x = b.left + 3; x < b.right - 3; x += 6) {
      for (double y = b.top + 2; y < b.bottom - 2; y += 6) {
        canvas.drawCircle(ui.Offset(x, y), 0.6, speck);
      }
    }
  }

  void _drawGrassTexture(
    ui.Canvas canvas,
    ui.Path topDiamond,
    ui.Color baseColor, {
    required double density,
  }) {
    final ui.Rect bounds = topDiamond.getBounds();
    canvas.save();
    canvas.clipPath(topDiamond);

    // Two tones of blades for richness
    final ui.Paint bladeDark = ui.Paint()
      ..color = _shadeColor(baseColor, 0.85).withOpacity(0.45)
      ..strokeWidth = 1.0
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round;
    final ui.Paint bladeLight = ui.Paint()
      ..color = _shadeColor(baseColor, 1.20).withOpacity(0.38)
      ..strokeWidth = 0.8
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round;

    // Deterministic pseudo-random pattern based on tile bounds
    int seed = bounds.left.toInt() * 73856093 ^ bounds.top.toInt() * 19349663;
    double rand() {
      seed = 1103515245 * seed + 12345;
      return ((seed >> 16) & 0x7FFF) / 0x7FFF;
    }

    // Blade count scales with area and density
    final int blades = (density * (bounds.width * bounds.height) / 140).clamp(18, 60).toInt();
    for (int i = 0; i < blades; i++) {
      final double px = bounds.left + rand() * bounds.width;
      final double py = bounds.top + rand() * bounds.height;
      final double len = 3.0 + rand() * 6.0; // blade length
      final double lean = (rand() - 0.5) * 0.8; // left/right lean

      final ui.Offset base = ui.Offset(px, py);
      final ui.Offset tip = ui.Offset(px + lean * 4.0, py - len);

      // Choose paint
      final ui.Paint p = (i % 2 == 0) ? bladeDark : bladeLight;
      canvas.drawLine(base, tip, p);

      // Occasional split tip
      if (rand() > 0.7) {
        final ui.Offset tip2 = ui.Offset(px + (lean + 0.25) * 3.0, py - len * 0.8);
        canvas.drawLine(ui.Offset(px + 0.2, py - len * 0.4), tip2, p);
      }
    }

    // Subtle cross-hatching to suggest turf direction
    final ui.Paint hatch = ui.Paint()
      ..color = _shadeColor(baseColor, 0.75).withOpacity(0.12)
      ..strokeWidth = 0.6
      ..style = ui.PaintingStyle.stroke;
    for (double y = bounds.top; y < bounds.bottom; y += 5) {
      canvas.drawLine(
        ui.Offset(bounds.left - 6, y + 1.5),
        ui.Offset(bounds.right + 6, y + 3.5),
        hatch,
      );
    }

    canvas.restore();
  }

  double _extrusionHeightForTerrain(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.mountain:
        return 12;
      case TerrainType.stone:
        return 9;
      case TerrainType.forest:
        return 8;
      case TerrainType.desert:
        return 7;
      case TerrainType.grass:
        return 6;
      case TerrainType.water:
        return 4;
    }
  }

  ui.Color _shadeColor(ui.Color color, double factor) {
    int clamp(int v) => v.clamp(0, 255).toInt();
    final double r = (color.red * factor);
    final double g = (color.green * factor);
    final double b = (color.blue * factor);
    return ui.Color.fromARGB(color.alpha, clamp(r.round()), clamp(g.round()), clamp(b.round()));
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

extension on IsometricGridComponent {
  /// Clears the current hover state on the grid.
  void clearHover() {
    hoveredRow = null;
    hoveredCol = null;
  }
}
