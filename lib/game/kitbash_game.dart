import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../models/tile_data.dart';

/// Helper class for 3D vector operations
class Vector3 {
  final double x;
  final double y;
  final double z;

  const Vector3(this.x, this.y, this.z);

  Vector3 normalized() {
    final double length = math.sqrt(x * x + y * y + z * z);
    if (length == 0) return const Vector3(0, 0, 1);
    return Vector3(x / length, y / length, z / length);
  }

  double dot(Vector3 other) {
    return x * other.x + y * other.y + z * other.z;
  }
}

/// Visual properties for terrain rendering
class TerrainVisuals {
  final Color baseColor;
  final Color highlightColor;
  final Color shadowColor;
  final double roughness;

  const TerrainVisuals({
    required this.baseColor,
    required this.highlightColor,
    required this.shadowColor,
    required this.roughness,
  });
}

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

  // Paint for grid/overlay outlines
  final ui.Paint gridLinePaint = ui.Paint()
    ..color = const Color(0xAAFFFFFF)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.0;

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

    final ui.Paint ccPaintP0 = ui.Paint()..color = const Color(0xCC8BC34A);
    final ui.Paint ccPaintP1 = ui.Paint()..color = const Color(0xCCE91E63);
    final ui.Paint healthBarBg = ui.Paint()..color = const Color(0xAA000000);
    final ui.Paint healthBarFill = ui.Paint()..color = const Color(0xAA4CAF50);
    final ui.Paint healthBarLow = ui.Paint()..color = const Color(0xAAF44336);

    // Origin at top center for a nice layout inside the component bounds
    final double originX = size.x / 2;
    const double originY = 0;

    // First pass: render ground shadows for elevated tiles
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double elevation = _getTerrainElevation(_tileData[r][c].terrain);
        if (elevation > 0) {
          _renderGroundShadow(canvas, r, c, originX, originY, elevation);
        }
      }
    }

    // Second pass: render tiles with enhanced 2.5D effects
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _renderEnhancedTile(canvas, r, c, originX, originY);
      }
    }

    // Render command centers as detailed 3D buildings
    for (final CommandCenter cc in _commandCenters) {
      final int r0 = cc.topLeftRow.clamp(0, rows - 1);
      final int c0 = cc.topLeftCol.clamp(0, cols - 1);
      final Vector2 buildingCenter =
          isoToScreen(r0 + 0.5, c0 + 0.5, originX, originY);

      // Render 3D building based on player
      _render3DCommandCenter(canvas, buildingCenter, cc, originX, originY);
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

  /// Renders ground shadows for elevated tiles to enhance depth perception
  void _renderGroundShadow(ui.Canvas canvas, int r, int c, double originX,
      double originY, double elevation) {
    final Vector2 center = isoToScreen(r, c, originX, originY);
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    // Shadow offset based on light direction and elevation
    final double shadowOffsetX = elevation * 0.3;
    final double shadowOffsetY = elevation * 0.2;
    final Vector2 shadowCenter =
        Vector2(center.x + shadowOffsetX, center.y + shadowOffsetY);

    // Create shadow diamond (slightly larger and offset)
    final ui.Path shadowPath = ui.Path()
      ..moveTo(shadowCenter.x, shadowCenter.y - halfH * 0.9)
      ..lineTo(shadowCenter.x + halfW * 0.9, shadowCenter.y)
      ..lineTo(shadowCenter.x, shadowCenter.y + halfH * 0.9)
      ..lineTo(shadowCenter.x - halfW * 0.9, shadowCenter.y)
      ..close();

    // Shadow paint with gradient based on elevation
    final double shadowOpacity = (elevation / 20.0).clamp(0.1, 0.4);
    final ui.Paint shadowPaint = ui.Paint()
      ..color = Colors.black.withOpacity(shadowOpacity)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.0);

    canvas.drawPath(shadowPath, shadowPaint);
  }

  /// Renders an enhanced tile with 2.5D effects, lighting, and detailed terrain
  void _renderEnhancedTile(
      ui.Canvas canvas, int r, int c, double originX, double originY) {
    final Vector2 center = isoToScreen(r, c, originX, originY);
    final TileData tileData = _tileData[r][c];
    final TerrainType terrain = tileData.terrain;

    // Get terrain elevation and visual properties
    final double elevation = _getTerrainElevation(terrain);
    final TerrainVisuals visuals = _getTerrainVisuals(terrain);

    // Calculate lighting based on position and terrain
    final Vector3 lightDirection = Vector3(-0.5, -0.8, 0.3).normalized();
    final double lightIntensity =
        _calculateLighting(r, c, terrain, lightDirection);

    // Render base tile with depth
    _renderTileBase(canvas, center, elevation, visuals, lightIntensity);

    // Add terrain-specific details
    _renderTerrainDetails(canvas, center, terrain, elevation, lightIntensity);

    // Add edge highlights and shadows for 3D effect
    _renderTileEdges(canvas, center, elevation, lightIntensity);

    // Apply hover and selection effects
    _applyTileEffects(canvas, center, r, c);
  }

  double _getTerrainElevation(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.water:
        return -8.0; // Below ground level
      case TerrainType.grass:
        return 0.0; // Ground level
      case TerrainType.desert:
        return 2.0; // Slightly elevated
      case TerrainType.stone:
        return 4.0; // Elevated platform
      case TerrainType.forest:
        return 6.0; // Tree canopy height
      case TerrainType.mountain:
        return 12.0; // High elevation
    }
  }

  TerrainVisuals _getTerrainVisuals(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.grass:
        return TerrainVisuals(
          baseColor: const Color(0xFF4A5D23),
          highlightColor: const Color(0xFF6B8432),
          shadowColor: const Color(0xFF2D3A15),
          roughness: 0.7,
        );
      case TerrainType.stone:
        return TerrainVisuals(
          baseColor: const Color(0xFF5A5A5A),
          highlightColor: const Color(0xFF8A8A8A),
          shadowColor: const Color(0xFF3A3A3A),
          roughness: 0.3,
        );
      case TerrainType.water:
        return TerrainVisuals(
          baseColor: const Color(0xFF2E5984),
          highlightColor: const Color(0xFF4A7BA7),
          shadowColor: const Color(0xFF1E3A5A),
          roughness: 0.1,
        );
      case TerrainType.desert:
        return TerrainVisuals(
          baseColor: const Color(0xFF8B7355),
          highlightColor: const Color(0xFFB8956F),
          shadowColor: const Color(0xFF6B5A42),
          roughness: 0.8,
        );
      case TerrainType.forest:
        return TerrainVisuals(
          baseColor: const Color(0xFF2D4A22),
          highlightColor: const Color(0xFF4A6B37),
          shadowColor: const Color(0xFF1A2D15),
          roughness: 0.9,
        );
      case TerrainType.mountain:
        return TerrainVisuals(
          baseColor: const Color(0xFF4A3728),
          highlightColor: const Color(0xFF6B5240),
          shadowColor: const Color(0xFF2A1F18),
          roughness: 0.4,
        );
    }
  }

  double _calculateLighting(
      int r, int c, TerrainType terrain, Vector3 lightDir) {
    // Calculate surface normal based on terrain and neighbors
    Vector3 normal = Vector3(0, 0, 1); // Default upward normal

    // Modify normal based on terrain type
    switch (terrain) {
      case TerrainType.mountain:
        // Rocky, uneven surface
        normal = Vector3((math.sin(r * 0.7 + c * 0.5) * 0.3),
                (math.cos(r * 0.5 + c * 0.7) * 0.3), 0.9)
            .normalized();
        break;
      case TerrainType.water:
        // Gentle waves
        final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        normal = Vector3(math.sin(time + r * 0.3 + c * 0.2) * 0.1,
                math.cos(time + r * 0.2 + c * 0.3) * 0.1, 0.99)
            .normalized();
        break;
      case TerrainType.forest:
        // Slightly bumpy from vegetation
        normal = Vector3((r + c) % 3 == 0 ? 0.1 : -0.1,
                (r - c) % 2 == 0 ? 0.1 : -0.1, 0.98)
            .normalized();
        break;
      default:
        // Slight variation for other terrains
        normal =
            Vector3(math.sin(r * 1.3) * 0.05, math.cos(c * 1.1) * 0.05, 0.995)
                .normalized();
    }

    // Calculate base lighting from dot product
    final double dot = normal.dot(lightDir);
    double lighting = (dot * 0.5 + 0.5).clamp(0.3, 1.0); // Ambient + diffuse

    // Add ambient occlusion from neighboring tiles
    final double ambientOcclusion = _calculateAmbientOcclusion(r, c);
    lighting *= ambientOcclusion;

    return lighting;
  }

  double _calculateAmbientOcclusion(int r, int c) {
    double occlusion = 1.0;
    final double currentElevation =
        _getTerrainElevation(_tileData[r][c].terrain);

    // Check neighboring tiles for occlusion
    final List<List<int>> neighbors = [
      [-1, -1],
      [-1, 0],
      [-1, 1],
      [0, -1],
      [0, 1],
      [1, -1],
      [1, 0],
      [1, 1]
    ];

    for (final List<int> offset in neighbors) {
      final int nr = r + offset[0];
      final int nc = c + offset[1];

      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        final double neighborElevation =
            _getTerrainElevation(_tileData[nr][nc].terrain);
        final double elevationDiff = neighborElevation - currentElevation;

        if (elevationDiff > 0) {
          // Higher neighbor casts shadow
          final double shadowStrength = (elevationDiff / 20.0).clamp(0.0, 0.15);
          occlusion -= shadowStrength * 0.5; // Reduce impact for subtlety
        }
      }
    }

    return occlusion.clamp(0.6, 1.0); // Ensure minimum lighting
  }

  void _renderTileBase(ui.Canvas canvas, Vector2 center, double elevation,
      TerrainVisuals visuals, double lightIntensity) {
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;
    final Vector2 elevatedCenter = Vector2(center.x, center.y - elevation);

    // Create the main tile diamond
    final ui.Path tilePath = ui.Path()
      ..moveTo(elevatedCenter.x, elevatedCenter.y - halfH)
      ..lineTo(elevatedCenter.x + halfW, elevatedCenter.y)
      ..lineTo(elevatedCenter.x, elevatedCenter.y + halfH)
      ..lineTo(elevatedCenter.x - halfW, elevatedCenter.y)
      ..close();

    // Apply lighting to base color
    final Color litColor = Color.lerp(
        visuals.shadowColor, visuals.highlightColor, lightIntensity)!;

    // Create gradient for 3D effect
    final ui.Paint gradientPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(elevatedCenter.x - halfW, elevatedCenter.y - halfH),
        ui.Offset(elevatedCenter.x + halfW, elevatedCenter.y + halfH),
        [
          Color.lerp(litColor, Colors.white, 0.2)!,
          litColor,
          Color.lerp(litColor, Colors.black, 0.3)!,
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawPath(tilePath, gradientPaint);

    // Draw depth/side faces for elevated tiles
    if (elevation > 0) {
      _renderTileDepth(
          canvas, center, elevatedCenter, elevation, visuals, lightIntensity);
    }

    // Add subtle border
    final ui.Paint borderPaint = ui.Paint()
      ..color = Color.lerp(litColor, Colors.black, 0.4)!
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(tilePath, borderPaint);
  }

  void _renderTileDepth(
      ui.Canvas canvas,
      Vector2 baseCenter,
      Vector2 elevatedCenter,
      double elevation,
      TerrainVisuals visuals,
      double lightIntensity) {
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    // Right face
    final ui.Path rightFace = ui.Path()
      ..moveTo(elevatedCenter.x + halfW, elevatedCenter.y)
      ..lineTo(baseCenter.x + halfW, baseCenter.y)
      ..lineTo(baseCenter.x, baseCenter.y + halfH)
      ..lineTo(elevatedCenter.x, elevatedCenter.y + halfH)
      ..close();

    // Left face
    final ui.Path leftFace = ui.Path()
      ..moveTo(elevatedCenter.x, elevatedCenter.y + halfH)
      ..lineTo(baseCenter.x, baseCenter.y + halfH)
      ..lineTo(baseCenter.x - halfW, baseCenter.y)
      ..lineTo(elevatedCenter.x - halfW, elevatedCenter.y)
      ..close();

    // Calculate face lighting (darker for side faces)
    final Color rightFaceColor = Color.lerp(
        visuals.shadowColor, visuals.baseColor, lightIntensity * 0.6)!;

    final Color leftFaceColor = Color.lerp(
        visuals.shadowColor, visuals.baseColor, lightIntensity * 0.4)!;

    // Draw faces
    canvas.drawPath(rightFace, ui.Paint()..color = rightFaceColor);
    canvas.drawPath(leftFace, ui.Paint()..color = leftFaceColor);

    // Add edge highlights
    final ui.Paint edgePaint = ui.Paint()
      ..color = Color.lerp(rightFaceColor, Colors.white, 0.3)!
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawPath(rightFace, edgePaint);
    canvas.drawPath(leftFace, edgePaint);
  }

  void _renderTerrainDetails(ui.Canvas canvas, Vector2 center,
      TerrainType terrain, double elevation, double lightIntensity) {
    final Vector2 elevatedCenter = Vector2(center.x, center.y - elevation);

    switch (terrain) {
      case TerrainType.water:
        _renderWaterEffects(canvas, elevatedCenter, lightIntensity);
        break;
      case TerrainType.forest:
        _renderForestDetails(canvas, elevatedCenter, lightIntensity);
        break;
      case TerrainType.mountain:
        _renderMountainDetails(canvas, elevatedCenter, lightIntensity);
        break;
      case TerrainType.desert:
        _renderDesertDetails(canvas, elevatedCenter, lightIntensity);
        break;
      case TerrainType.stone:
        _renderStoneDetails(canvas, elevatedCenter, lightIntensity);
        break;
      case TerrainType.grass:
        _renderGrassDetails(canvas, elevatedCenter, lightIntensity);
        break;
    }
  }

  void _renderWaterEffects(
      ui.Canvas canvas, Vector2 center, double lightIntensity) {
    final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    // Animated water surface with reflection
    final ui.Paint waterPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(center.x, center.y),
        20.0,
        [
          Color.lerp(const Color(0xFF4A9FD1), const Color(0xFF87CEEB),
              (math.sin(time * 2) * 0.3 + 0.7) * lightIntensity)!,
          Color.lerp(const Color(0xFF2E5984), const Color(0xFF4A7BA7),
              lightIntensity)!,
        ],
        [0.0, 1.0],
      );

    // Draw water base with subtle movement
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;
    final ui.Path waterPath = ui.Path()
      ..moveTo(center.x, center.y - halfH + math.sin(time * 3) * 0.5)
      ..lineTo(center.x + halfW + math.cos(time * 2.5) * 0.5, center.y)
      ..lineTo(center.x, center.y + halfH + math.sin(time * 3.5) * 0.5)
      ..lineTo(center.x - halfW + math.cos(time * 2) * 0.5, center.y)
      ..close();

    canvas.drawPath(waterPath, waterPaint);

    // Draw animated water ripples
    for (int i = 0; i < 3; i++) {
      final double radius = 8 + i * 6 + math.sin(time * 3 + i) * 2;
      final double alpha = (0.3 - i * 0.1) * lightIntensity;

      final ui.Paint ripplePaint = ui.Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(ui.Offset(center.x, center.y), radius, ripplePaint);
    }

    // Add sparkles for light reflection
    for (int i = 0; i < 4; i++) {
      final double sparkleX =
          center.x + (i % 2 - 0.5) * 20 + math.sin(time * 4 + i) * 3;
      final double sparkleY =
          center.y + (i ~/ 2 - 0.5) * 12 + math.cos(time * 3 + i) * 2;
      final double sparkleAlpha =
          (math.sin(time * 6 + i * 2) * 0.5 + 0.5) * lightIntensity;

      if (sparkleAlpha > 0.3) {
        final ui.Paint sparklePaint = ui.Paint()
          ..color = Colors.white.withOpacity(sparkleAlpha * 0.8)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.0);

        canvas.drawCircle(ui.Offset(sparkleX, sparkleY), 1.5, sparklePaint);
      }
    }
  }

  void _renderForestDetails(
      ui.Canvas canvas, Vector2 center, double lightIntensity) {
    final ui.Paint treePaint = ui.Paint()
      ..color = Color.lerp(
          const Color(0xFF1A2D15), const Color(0xFF2D4A22), lightIntensity)!;

    // Draw simplified tree shapes
    for (int i = 0; i < 4; i++) {
      final double offsetX = (i % 2 - 0.5) * 12;
      final double offsetY = (i ~/ 2 - 0.5) * 8;
      final Vector2 treePos = Vector2(center.x + offsetX, center.y + offsetY);

      canvas.drawCircle(ui.Offset(treePos.x, treePos.y), 4, treePaint);
    }
  }

  void _renderMountainDetails(
      ui.Canvas canvas, Vector2 center, double lightIntensity) {
    final ui.Paint rockPaint = ui.Paint()
      ..color = Color.lerp(
          const Color(0xFF2A1F18), const Color(0xFF6B5240), lightIntensity)!;

    // Draw rocky outcroppings
    final ui.Path rockPath = ui.Path()
      ..moveTo(center.x - 8, center.y + 4)
      ..lineTo(center.x - 4, center.y - 6)
      ..lineTo(center.x + 2, center.y - 4)
      ..lineTo(center.x + 8, center.y - 8)
      ..lineTo(center.x + 6, center.y + 2)
      ..lineTo(center.x, center.y + 6)
      ..close();

    canvas.drawPath(rockPath, rockPaint);

    // Add snow cap for high peaks
    final ui.Paint snowPaint = ui.Paint()
      ..color = Colors.white.withOpacity(0.8 * lightIntensity);

    final ui.Path snowPath = ui.Path()
      ..moveTo(center.x - 4, center.y - 6)
      ..lineTo(center.x + 2, center.y - 4)
      ..lineTo(center.x + 8, center.y - 8)
      ..lineTo(center.x - 2, center.y - 8)
      ..close();

    canvas.drawPath(snowPath, snowPaint);
  }

  void _renderDesertDetails(
      ui.Canvas canvas, Vector2 center, double lightIntensity) {
    final ui.Paint sandPaint = ui.Paint()
      ..color = Color.lerp(
          const Color(0xFF6B5A42), const Color(0xFFD4B896), lightIntensity)!
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw sand dune lines
    for (int i = 0; i < 3; i++) {
      final double y = center.y - 8 + i * 6;
      final ui.Path dunePath = ui.Path()
        ..moveTo(center.x - 12, y)
        ..quadraticBezierTo(center.x, y - 2, center.x + 12, y);

      canvas.drawPath(dunePath, sandPaint);
    }
  }

  void _renderStoneDetails(
      ui.Canvas canvas, Vector2 center, double lightIntensity) {
    final ui.Paint stonePaint = ui.Paint()
      ..color = Color.lerp(
          const Color(0xFF3A3A3A), const Color(0xFF8A8A8A), lightIntensity)!
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw stone tile patterns
    final double halfW = tileSize.x / 4;
    final double halfH = tileSize.y / 4;

    // Cross pattern
    canvas.drawLine(ui.Offset(center.x - halfW, center.y),
        ui.Offset(center.x + halfW, center.y), stonePaint);
    canvas.drawLine(ui.Offset(center.x, center.y - halfH),
        ui.Offset(center.x, center.y + halfH), stonePaint);
  }

  void _renderGrassDetails(
      ui.Canvas canvas, Vector2 center, double lightIntensity) {
    final ui.Paint grassPaint = ui.Paint()
      ..color = Color.lerp(
          const Color(0xFF2D3A15), const Color(0xFF6B8432), lightIntensity)!
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw grass blades
    for (int i = 0; i < 6; i++) {
      final double angle = (i / 6.0) * math.pi * 2;
      final double length = 6 + math.sin(angle * 3) * 2;
      final Vector2 end = Vector2(center.x + math.cos(angle) * length,
          center.y + math.sin(angle) * length * 0.5);

      canvas.drawLine(
          ui.Offset(center.x, center.y), ui.Offset(end.x, end.y), grassPaint);
    }
  }

  void _renderTileEdges(ui.Canvas canvas, Vector2 center, double elevation,
      double lightIntensity) {
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;
    final Vector2 elevatedCenter = Vector2(center.x, center.y - elevation);

    // Highlight top-left edges
    final ui.Paint highlightPaint = ui.Paint()
      ..color = Colors.white.withOpacity(0.3 * lightIntensity)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(ui.Offset(elevatedCenter.x, elevatedCenter.y - halfH),
        ui.Offset(elevatedCenter.x - halfW, elevatedCenter.y), highlightPaint);

    canvas.drawLine(ui.Offset(elevatedCenter.x, elevatedCenter.y - halfH),
        ui.Offset(elevatedCenter.x + halfW, elevatedCenter.y), highlightPaint);
  }

  void _applyTileEffects(ui.Canvas canvas, Vector2 center, int r, int c) {
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    final ui.Path diamond = ui.Path()
      ..moveTo(center.x, center.y - halfH)
      ..lineTo(center.x + halfW, center.y)
      ..lineTo(center.x, center.y + halfH)
      ..lineTo(center.x - halfW, center.y)
      ..close();

    // Apply hover highlight with glow effect
    if (hoveredRow == r && hoveredCol == c) {
      final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final double pulse = (math.sin(time * 4) * 0.2 + 0.8);

      final ui.Paint hoverPaint = ui.Paint()
        ..color = Color.fromRGBO(255, 255, 255, (0.4 * pulse).clamp(0.0, 1.0))
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

      canvas.drawPath(diamond, hoverPaint);
    }

    // Apply selection highlight with animated border
    if (highlightedRow == r && highlightedCol == c) {
      final double time = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final double pulse = math.sin(time * 3) * 0.5 + 0.5;

      final ui.Paint selectionPaint = ui.Paint()
        ..color =
            Color.lerp(const Color(0xFF54C7EC), const Color(0xFF00A8E8), pulse)!
                .withOpacity(0.7)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1);

      canvas.drawPath(diamond, selectionPaint);
    }
  }

  Color getTerrainColor(TerrainType terrain) {
    // This method is now mainly used for backward compatibility
    // The enhanced rendering uses TerrainVisuals instead
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

  Vector2 isoToScreen(num row, num col, double originX, double originY) {
    final double rowD = row.toDouble();
    final double colD = col.toDouble();
    final double screenX = (colD - rowD) * (tileSize.x / 2) + originX;
    final double screenY = (colD + rowD) * (tileSize.y / 2) + originY;
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

  /// Renders a 3D command center building based on player index
  void _render3DCommandCenter(ui.Canvas canvas, Vector2 center,
      CommandCenter cc, double originX, double originY) {
    if (cc.playerIndex == 0) {
      _renderPlayer0Fortress(canvas, center, cc);
    } else {
      _renderPlayer1Citadel(canvas, center, cc);
    }

    // Draw health bar above the building
    if (!cc.isDestroyed) {
      _drawBuildingHealthBar(canvas, center, cc);
    }
  }

  /// Renders Player 0's fortress - a sturdy castle-like structure
  void _renderPlayer0Fortress(
      ui.Canvas canvas, Vector2 center, CommandCenter cc) {
    final double healthFactor = cc.isDestroyed ? 0.3 : cc.healthPercentage;

    // Base colors for Player 0 (Green theme)
    final Color baseColor = Color.lerp(
        const Color(0xFF4A5A2A), // Dark green
        const Color(0xFF8BC34A), // Bright green
        healthFactor)!;
    final Color highlightColor = Color.lerp(baseColor, Colors.white, 0.3)!;
    final Color shadowColor = Color.lerp(baseColor, Colors.black, 0.4)!;

    // Main building base (foundation)
    _renderBuildingBase(canvas, center, 80.0, 60.0, 40.0, baseColor,
        highlightColor, shadowColor);

    // Central keep (main tower)
    final Vector2 keepCenter = Vector2(center.x, center.y - 35);
    _renderCylindricalTower(
        canvas, keepCenter, 25.0, 45.0, baseColor, highlightColor, shadowColor);

    // Corner towers
    final List<Vector2> towerPositions = [
      Vector2(center.x - 25, center.y - 10), // Left tower
      Vector2(center.x + 25, center.y - 10), // Right tower
      Vector2(center.x - 15, center.y + 15), // Back left
      Vector2(center.x + 15, center.y + 15), // Back right
    ];

    for (final Vector2 towerPos in towerPositions) {
      _renderCylindricalTower(
          canvas, towerPos, 12.0, 30.0, baseColor, highlightColor, shadowColor);
    }

    // Fortress walls connecting towers
    _renderFortressWalls(
        canvas, center, baseColor, highlightColor, shadowColor);

    // Add fortress details
    _renderFortressDetails(canvas, center, baseColor, healthFactor);

    // Damage effects if health is low
    if (healthFactor < 0.5 && !cc.isDestroyed) {
      _renderBuildingDamage(canvas, center, 1.0 - healthFactor);
    }
  }

  /// Renders a basic 3D building foundation
  void _renderBuildingBase(
      ui.Canvas canvas,
      Vector2 center,
      double width,
      double height,
      double depth,
      Color baseColor,
      Color highlightColor,
      Color shadowColor) {
    final double halfW = width / 2;
    final double halfH = height / 2;
    final double halfD = depth / 2;

    // Top face
    final ui.Path topFace = ui.Path()
      ..moveTo(center.x - halfW, center.y - halfH)
      ..lineTo(center.x, center.y - halfH - halfD)
      ..lineTo(center.x + halfW, center.y - halfH)
      ..lineTo(center.x, center.y - halfH + halfD)
      ..close();

    // Left face
    final ui.Path leftFace = ui.Path()
      ..moveTo(center.x - halfW, center.y - halfH)
      ..lineTo(center.x, center.y - halfH - halfD)
      ..lineTo(center.x, center.y + halfH - halfD)
      ..lineTo(center.x - halfW, center.y + halfH)
      ..close();

    // Right face
    final ui.Path rightFace = ui.Path()
      ..moveTo(center.x + halfW, center.y - halfH)
      ..lineTo(center.x, center.y - halfH + halfD)
      ..lineTo(center.x, center.y + halfH + halfD)
      ..lineTo(center.x + halfW, center.y + halfH)
      ..close();

    // Draw faces with different lighting
    canvas.drawPath(topFace, ui.Paint()..color = highlightColor);
    canvas.drawPath(leftFace, ui.Paint()..color = baseColor);
    canvas.drawPath(rightFace, ui.Paint()..color = shadowColor);

    // Add edges
    final ui.Paint edgePaint = ui.Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(topFace, edgePaint);
    canvas.drawPath(leftFace, edgePaint);
    canvas.drawPath(rightFace, edgePaint);
  }

  /// Renders a cylindrical tower for the fortress
  void _renderCylindricalTower(ui.Canvas canvas, Vector2 center, double radius,
      double height, Color baseColor, Color highlightColor, Color shadowColor) {
    // Tower body (cylinder approximation with ellipse)
    final ui.Rect towerRect = ui.Rect.fromCenter(
      center: ui.Offset(center.x, center.y - height / 2),
      width: radius * 2,
      height: height,
    );

    // Create gradient for cylindrical appearance
    final ui.Paint towerPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x - radius, center.y - height / 2),
        ui.Offset(center.x + radius, center.y - height / 2),
        [highlightColor, baseColor, shadowColor],
        [0.0, 0.5, 1.0],
      );

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(towerRect, ui.Radius.circular(radius)),
      towerPaint,
    );

    // Tower top (ellipse for 3D effect)
    final ui.Rect topRect = ui.Rect.fromCenter(
      center: ui.Offset(center.x, center.y - height),
      width: radius * 2,
      height: radius * 0.6, // Flattened for isometric view
    );

    final ui.Paint topPaint = ui.Paint()..color = highlightColor;
    canvas.drawOval(topRect, topPaint);

    // Tower edge
    final ui.Paint edgePaint = ui.Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(towerRect, ui.Radius.circular(radius)),
      edgePaint,
    );
    canvas.drawOval(topRect, edgePaint);
  }

  /// Renders fortress walls connecting towers
  void _renderFortressWalls(ui.Canvas canvas, Vector2 center, Color baseColor,
      Color highlightColor, Color shadowColor) {
    const double wallHeight = 25.0;
    const double wallThickness = 8.0;

    // Front wall segments
    final List<ui.Rect> wallSegments = [
      ui.Rect.fromLTWH(
          center.x - 35, center.y - 15, 20, wallHeight), // Left wall
      ui.Rect.fromLTWH(
          center.x + 15, center.y - 15, 20, wallHeight), // Right wall
    ];

    for (final ui.Rect wall in wallSegments) {
      // Wall face
      final ui.Paint wallPaint = ui.Paint()..color = baseColor;
      canvas.drawRect(wall, wallPaint);

      // Wall top
      final ui.Path wallTop = ui.Path()
        ..moveTo(wall.left, wall.top)
        ..lineTo(
            wall.left - wallThickness * 0.5, wall.top - wallThickness * 0.3)
        ..lineTo(
            wall.right - wallThickness * 0.5, wall.top - wallThickness * 0.3)
        ..lineTo(wall.right, wall.top)
        ..close();

      canvas.drawPath(wallTop, ui.Paint()..color = highlightColor);

      // Wall edge
      final ui.Paint edgePaint = ui.Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawRect(wall, edgePaint);
      canvas.drawPath(wallTop, edgePaint);
    }
  }

  /// Renders fortress-specific details
  void _renderFortressDetails(
      ui.Canvas canvas, Vector2 center, Color baseColor, double healthFactor) {
    // Fortress flag on main tower
    if (healthFactor > 0.3) {
      final Vector2 flagPos = Vector2(center.x + 5, center.y - 75);
      final ui.Paint flagPaint = ui.Paint()..color = const Color(0xFF8BC34A);

      final ui.Path flagPath = ui.Path()
        ..moveTo(flagPos.x, flagPos.y)
        ..lineTo(flagPos.x + 15, flagPos.y + 3)
        ..lineTo(flagPos.x + 12, flagPos.y + 8)
        ..lineTo(flagPos.x, flagPos.y + 5)
        ..close();

      canvas.drawPath(flagPath, flagPaint);

      // Flag pole
      canvas.drawLine(
        ui.Offset(flagPos.x, flagPos.y),
        ui.Offset(flagPos.x, flagPos.y + 15),
        ui.Paint()
          ..color = Colors.brown
          ..strokeWidth = 2.0,
      );
    }

    // Windows on towers
    final List<Vector2> windowPositions = [
      Vector2(center.x - 25, center.y - 20), // Left tower
      Vector2(center.x + 25, center.y - 20), // Right tower
    ];

    for (final Vector2 windowPos in windowPositions) {
      final ui.Rect windowRect = ui.Rect.fromCenter(
        center: ui.Offset(windowPos.x, windowPos.y),
        width: 4,
        height: 6,
      );

      final ui.Paint windowPaint = ui.Paint()
        ..color = healthFactor > 0.5 ? const Color(0xFFFFE082) : Colors.black;

      canvas.drawRect(windowRect, windowPaint);
    }
  }

  /// Renders damage effects on buildings
  void _renderBuildingDamage(
      ui.Canvas canvas, Vector2 center, double damageLevel) {
    final ui.Paint damagePaint = ui.Paint()
      ..color = Colors.red.withOpacity(0.3 * damageLevel)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.0);

    // Damage particles/smoke
    for (int i = 0; i < (damageLevel * 8).round(); i++) {
      final double offsetX = (i % 3 - 1) * 20 + math.sin(i * 2.5) * 10;
      final double offsetY = (i ~/ 3 - 1) * 15 + math.cos(i * 1.8) * 8;
      final Vector2 damagePos =
          Vector2(center.x + offsetX, center.y + offsetY - 30);

      canvas.drawCircle(
        ui.Offset(damagePos.x, damagePos.y),
        2 + math.sin(i * 3) * 1,
        damagePaint,
      );
    }
  }

  /// Renders Player 1's citadel - an elegant spire-like structure
  void _renderPlayer1Citadel(
      ui.Canvas canvas, Vector2 center, CommandCenter cc) {
    final double healthFactor = cc.isDestroyed ? 0.3 : cc.healthPercentage;

    // Base colors for Player 1 (Pink/Purple theme)
    final Color baseColor = Color.lerp(
        const Color(0xFF5A2A4A), // Dark pink
        const Color(0xFFE91E63), // Bright pink
        healthFactor)!;
    final Color highlightColor = Color.lerp(baseColor, Colors.white, 0.3)!;
    final Color shadowColor = Color.lerp(baseColor, Colors.black, 0.4)!;

    // Main building base
    _renderBuildingBase(canvas, center, 70.0, 50.0, 35.0, baseColor,
        highlightColor, shadowColor);

    // Central spire (main tower) - taller and more elegant
    final Vector2 spireCenter = Vector2(center.x, center.y - 40);
    _renderElegantSpire(canvas, spireCenter, 20.0, 65.0, baseColor,
        highlightColor, shadowColor);

    // Smaller decorative spires
    final List<Vector2> spirePositions = [
      Vector2(center.x - 20, center.y - 15), // Left spire
      Vector2(center.x + 20, center.y - 15), // Right spire
      Vector2(center.x, center.y + 10), // Back spire
    ];

    for (final Vector2 spirePos in spirePositions) {
      _renderElegantSpire(
          canvas, spirePos, 10.0, 35.0, baseColor, highlightColor, shadowColor);
    }

    // Connecting archways
    _renderCitadelArchways(
        canvas, center, baseColor, highlightColor, shadowColor);

    // Add citadel details
    _renderCitadelDetails(canvas, center, baseColor, healthFactor);

    // Damage effects if health is low
    if (healthFactor < 0.5 && !cc.isDestroyed) {
      _renderBuildingDamage(canvas, center, 1.0 - healthFactor);
    }
  }

  /// Renders an elegant spire for the citadel
  void _renderElegantSpire(ui.Canvas canvas, Vector2 center, double baseRadius,
      double height, Color baseColor, Color highlightColor, Color shadowColor) {
    // Spire body (tapered)
    final ui.Path spirePath = ui.Path()
      ..moveTo(center.x - baseRadius, center.y)
      ..lineTo(center.x - baseRadius * 0.3, center.y - height * 0.7)
      ..lineTo(center.x, center.y - height)
      ..lineTo(center.x + baseRadius * 0.3, center.y - height * 0.7)
      ..lineTo(center.x + baseRadius, center.y)
      ..close();

    // Create gradient for spire
    final ui.Paint spirePaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x - baseRadius, center.y),
        ui.Offset(center.x + baseRadius, center.y),
        [highlightColor, baseColor, shadowColor],
        [0.0, 0.5, 1.0],
      );

    canvas.drawPath(spirePath, spirePaint);

    // Spire base (cylindrical)
    final ui.Rect baseRect = ui.Rect.fromCenter(
      center: ui.Offset(center.x, center.y - baseRadius * 0.3),
      width: baseRadius * 2,
      height: baseRadius * 0.8,
    );

    canvas.drawOval(baseRect, ui.Paint()..color = baseColor);

    // Add edges
    final ui.Paint edgePaint = ui.Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(spirePath, edgePaint);
    canvas.drawOval(baseRect, edgePaint);
  }

  /// Renders citadel archways
  void _renderCitadelArchways(ui.Canvas canvas, Vector2 center, Color baseColor,
      Color highlightColor, Color shadowColor) {
    final List<Vector2> archPositions = [
      Vector2(center.x - 15, center.y), // Left arch
      Vector2(center.x + 15, center.y), // Right arch
    ];

    for (final Vector2 archPos in archPositions) {
      // Arch structure
      final ui.Rect archRect = ui.Rect.fromCenter(
        center: ui.Offset(archPos.x, archPos.y - 10),
        width: 12,
        height: 20,
      );

      final ui.Paint archPaint = ui.Paint()..color = baseColor;
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(archRect, const ui.Radius.circular(6)),
        archPaint,
      );

      // Arch opening
      final ui.Rect openingRect = ui.Rect.fromCenter(
        center: ui.Offset(archPos.x, archPos.y - 8),
        width: 6,
        height: 12,
      );

      final ui.Paint openingPaint = ui.Paint()..color = shadowColor;
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(openingRect, const ui.Radius.circular(3)),
        openingPaint,
      );
    }
  }

  /// Renders citadel-specific details
  void _renderCitadelDetails(
      ui.Canvas canvas, Vector2 center, Color baseColor, double healthFactor) {
    // Magical orb on main spire
    if (healthFactor > 0.3) {
      final Vector2 orbPos = Vector2(center.x, center.y - 100);
      final ui.Paint orbPaint = ui.Paint()
        ..shader = ui.Gradient.radial(
          ui.Offset(orbPos.x, orbPos.y),
          8.0,
          [
            const Color(0xFFE91E63).withOpacity(0.8),
            const Color(0xFF8E24AA).withOpacity(0.6),
            Colors.transparent,
          ],
          [0.0, 0.7, 1.0],
        );

      canvas.drawCircle(ui.Offset(orbPos.x, orbPos.y), 8, orbPaint);

      // Orb core
      canvas.drawCircle(
        ui.Offset(orbPos.x, orbPos.y),
        3,
        ui.Paint()..color = Colors.white.withOpacity(0.9),
      );
    }

    // Elegant windows with arched tops
    final List<Vector2> windowPositions = [
      Vector2(center.x - 20, center.y - 25), // Left spire
      Vector2(center.x + 20, center.y - 25), // Right spire
      Vector2(center.x, center.y - 15), // Main building
    ];

    for (final Vector2 windowPos in windowPositions) {
      // Window frame
      final ui.Path windowPath = ui.Path()
        ..moveTo(windowPos.x - 3, windowPos.y + 4)
        ..lineTo(windowPos.x - 3, windowPos.y - 2)
        ..quadraticBezierTo(
            windowPos.x, windowPos.y - 5, windowPos.x + 3, windowPos.y - 2)
        ..lineTo(windowPos.x + 3, windowPos.y + 4)
        ..close();

      final ui.Paint windowPaint = ui.Paint()
        ..color = healthFactor > 0.5 ? const Color(0xFFE1BEE7) : Colors.black;

      canvas.drawPath(windowPath, windowPaint);
    }
  }

  void _drawBuildingHealthBar(
      ui.Canvas canvas, Vector2 center, CommandCenter cc) {
    const double barWidth = 50.0;
    const double barHeight = 8.0;
    const double barOffsetY = -120.0; // Position above the building

    final double barX = center.x - barWidth / 2;
    final double barY = center.y + barOffsetY;

    // Health bar background
    final ui.Paint bgPaint = ui.Paint()..color = const Color(0xAA000000);
    final ui.Rect bgRect = ui.Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(4)),
      bgPaint,
    );

    // Health bar fill
    final ui.Paint fillPaint = ui.Paint()
      ..color = cc.healthPercentage > 0.3
          ? const Color(0xAA4CAF50)
          : const Color(0xAAF44336);

    final double fillWidth = barWidth * cc.healthPercentage;
    final ui.Rect fillRect = ui.Rect.fromLTWH(barX, barY, fillWidth, barHeight);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(4)),
      fillPaint,
    );

    // Health bar border
    final ui.Paint borderPaint = ui.Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(4)),
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
