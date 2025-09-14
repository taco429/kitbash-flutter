import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../models/tile_data.dart';

/// Enhanced isometric grid component with flat tiles and 3D objects
class EnhancedIsometricGrid extends PositionComponent {
  final int rows;
  final int cols;
  final Vector2 tileSize;
  final GameService gameService;
  List<CommandCenter> _commandCenters;

  int? highlightedRow;
  int? highlightedCol;
  int? hoveredRow;
  int? hoveredCol;

  // Visual enhancement properties
  final double commandCenterHeight = 40.0;

  // Animation properties
  double _time = 0.0;
  double _pulseAnimation = 0.0;
  double _floatAnimation = 0.0;

  // Tile data and variation maps
  late List<List<TileData>> _tileData;
  late List<List<double>> _moistureMap;
  late List<List<int>> _rockSeeds; // For consistent rock placement

  // Particle system for ambient effects
  final List<Particle> _particles = [];

  EnhancedIsometricGrid({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.gameService,
    List<CommandCenter>? commandCenters,
  }) : _commandCenters = commandCenters ?? <CommandCenter>[] {
    size = Vector2(
      (cols + rows) * (tileSize.x / 2) + 100,
      (cols + rows) * (tileSize.y / 2) + 100,
    );
    _initializeTileData();
    _initializeVariationMaps();
  }

  void _initializeTileData() {
    final random = math.Random(42); // Seed for consistent generation
    _tileData = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        // Generate varied terrain with more interesting patterns
        final centerDist = math
            .sqrt(math.pow(row - rows / 2, 2) + math.pow(col - cols / 2, 2));
        final noise = (math.sin(row * 0.3) * math.cos(col * 0.3) + 1) / 2;

        TerrainType terrain;
        if (centerDist < rows * 0.15) {
          terrain = TerrainType.grass;
        } else if (centerDist < rows * 0.25 && noise > 0.6) {
          terrain = TerrainType.forest;
        } else if (centerDist < rows * 0.35) {
          terrain = noise > 0.5 ? TerrainType.grass : TerrainType.stone;
        } else if (centerDist < rows * 0.45 && noise < 0.3) {
          terrain = TerrainType.desert;
        } else {
          terrain = noise > 0.7 ? TerrainType.mountain : TerrainType.stone;
        }

        return TileData(
          row: row,
          col: col,
          terrain: terrain,
        );
      });
    });
  }

  void _initializeVariationMaps() {
    final random = math.Random(42);

    // Initialize moisture map for visual variety
    _moistureMap = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        return random.nextDouble();
      });
    });

    // Initialize rock seeds for consistent placement
    _rockSeeds = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        return random.nextInt(10000);
      });
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pulseAnimation = (math.sin(_time * 2) + 1) / 2;
    _floatAnimation = math.sin(_time * 1.5) * 2;

    // Update particles
    _updateParticles(dt);

    // Occasionally spawn new particles
    if (_particles.length < 20 && math.Random().nextDouble() < 0.1) {
      _spawnParticle();
    }
  }

  void _updateParticles(double dt) {
    _particles.removeWhere((particle) => particle.life <= 0);
    for (final particle in _particles) {
      particle.update(dt);
    }
  }

  void _spawnParticle() {
    final random = math.Random();
    _particles.add(Particle(
      position: Vector2(
        random.nextDouble() * size.x,
        random.nextDouble() * size.y,
      ),
      velocity: Vector2(
        (random.nextDouble() - 0.5) * 20,
        -random.nextDouble() * 30 - 10,
      ),
      life: 3.0 + random.nextDouble() * 2.0,
      color: Color.lerp(
        const Color(0xFFFFE082),
        const Color(0xFFFFF59D),
        random.nextDouble(),
      )!
          .withOpacity(0.6),
    ));
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Update command centers from game service
    final gameState = gameService.gameState;
    if (gameState != null && gameState.commandCenters.isNotEmpty) {
      _commandCenters = gameState.commandCenters;
    }

    final double originX = size.x / 2;
    const double originY = 50;

    // First pass: render flat tiles
    _renderFlatTiles(canvas, originX, originY);

    // Second pass: render 3D objects (rocks, trees, etc)
    _render3DObjects(canvas, originX, originY);

    // Third pass: render command centers with unique 3D structures
    _renderCommandCenters(canvas, originX, originY);

    // Fourth pass: render particles and effects
    _renderParticles(canvas);

    // Fifth pass: render overlays (hover, selection)
    _renderOverlays(canvas, originX, originY);
  }

  void _renderFlatTiles(ui.Canvas canvas, double originX, double originY) {
    // Render all tiles as flat surfaces
    for (int r = rows - 1; r >= 0; r--) {
      for (int c = cols - 1; c >= 0; c--) {
        _renderFlatTile(canvas, r, c, originX, originY);
      }
    }
  }

  void _renderFlatTile(
      ui.Canvas canvas, int row, int col, double originX, double originY) {
    final terrain = _tileData[row][col].terrain;
    final moisture = _moistureMap[row][col];

    // All tiles are flat at elevation 0
    final Vector2 center = isoToScreen(row, col, originX, originY);

    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    // Get terrain color with moisture variation
    Color baseColor = _getEnhancedTerrainColor(terrain, moisture);

    // Draw flat tile with subtle gradient
    final ui.Path tilePath = _tileDiamond(center, 1.0);

    // Create subtle gradient paint for flat tile
    final tilePaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x - halfW, center.y - halfH),
        ui.Offset(center.x + halfW, center.y + halfH),
        [
          _brightenColor(baseColor, 0.08),
          baseColor,
          _darkenColor(baseColor, 0.03),
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawPath(tilePath, tilePaint);

    // Add subtle texture details for some terrain types
    _drawFlatTerrainDetails(canvas, center, terrain, halfW, halfH);

    // Draw tile outline
    final outlinePaint = ui.Paint()
      ..color = _darkenColor(baseColor, 0.15).withOpacity(0.25)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(tilePath, outlinePaint);
  }

  void _drawFlatTerrainDetails(ui.Canvas canvas, Vector2 center,
      TerrainType terrain, double halfW, double halfH) {
    final detailPaint = ui.Paint()..style = ui.PaintingStyle.fill;

    switch (terrain) {
      case TerrainType.water:
        // Draw water ripples
        detailPaint
          ..color = const Color(0xFF64B5F6).withOpacity(0.2)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawCircle(
            ui.Offset(center.x, center.y), halfW * 0.3, detailPaint);
        canvas.drawCircle(
            ui.Offset(center.x, center.y), halfW * 0.5, detailPaint);
        break;

      case TerrainType.grass:
        // Add subtle grass texture
        detailPaint.color = const Color(0xFF5D7A2B).withOpacity(0.15);
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2;
          final dist = halfW * 0.3;
          canvas.drawCircle(
            ui.Offset(
              center.x + math.cos(angle) * dist,
              center.y + math.sin(angle) * dist * 0.5,
            ),
            1,
            detailPaint,
          );
        }
        break;

      case TerrainType.desert:
        // Add sand dune pattern
        detailPaint
          ..color = const Color(0xFF9B8365).withOpacity(0.1)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1;
        final path = ui.Path()
          ..moveTo(center.x - halfW * 0.5, center.y)
          ..quadraticBezierTo(
            center.x,
            center.y - halfH * 0.2,
            center.x + halfW * 0.5,
            center.y,
          );
        canvas.drawPath(path, detailPaint);
        break;

      default:
        // Stone, mountain, and forest will have 3D objects
        break;
    }
  }

  void _render3DObjects(ui.Canvas canvas, double originX, double originY) {
    // Render 3D objects from back to front
    for (int r = rows - 1; r >= 0; r--) {
      for (int c = cols - 1; c >= 0; c--) {
        final terrain = _tileData[r][c].terrain;
        final Vector2 center = isoToScreen(r, c, originX, originY);
        final seed = _rockSeeds[r][c];

        switch (terrain) {
          case TerrainType.stone:
            _draw3DRocks(canvas, center, seed, 2, 0.8);
            break;
          case TerrainType.mountain:
            _draw3DRocks(canvas, center, seed, 4, 1.2);
            break;
          case TerrainType.forest:
            _draw3DTrees(canvas, center, seed);
            break;
          default:
            break;
        }
      }
    }
  }

  void _draw3DRocks(ui.Canvas canvas, Vector2 tileCenter, int seed,
      int rockCount, double sizeMultiplier) {
    final random = math.Random(seed);

    for (int i = 0; i < rockCount; i++) {
      // Position rocks randomly on the tile
      final offsetX = (random.nextDouble() - 0.5) * tileSize.x * 0.5;
      final offsetY = (random.nextDouble() - 0.5) * tileSize.y * 0.3;
      final rockCenter = Vector2(
        tileCenter.x + offsetX,
        tileCenter.y + offsetY,
      );

      final rockSize = (6 + random.nextDouble() * 8) * sizeMultiplier;
      final rockHeight = rockSize * (1.0 + random.nextDouble() * 0.5);

      // Draw rock shadow
      final shadowPaint = ui.Paint()
        ..color = const Color(0x30000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

      final shadowPath = ui.Path()
        ..addOval(ui.Rect.fromCenter(
          center: ui.Offset(rockCenter.x + 4, rockCenter.y + 3),
          width: rockSize * 1.3,
          height: rockSize * 0.7,
        ));
      canvas.drawPath(shadowPath, shadowPaint);

      // Draw rock body with multiple faces for 3D effect
      _drawRock3D(canvas, rockCenter, rockSize, rockHeight, random);
    }
  }

  void _drawRock3D(ui.Canvas canvas, Vector2 center, double size, double height,
      math.Random random) {
    // Generate random rock shape with multiple faces
    final faces = 5 + random.nextInt(3);
    final angleStep = (math.pi * 2) / faces;
    final angleOffset = random.nextDouble() * angleStep;

    // Create rock vertices
    final topVertices = <ui.Offset>[];
    final baseVertices = <ui.Offset>[];

    for (int i = 0; i < faces; i++) {
      final angle = angleOffset + i * angleStep;
      final radiusVariation = 0.7 + random.nextDouble() * 0.3;

      // Top vertex (smaller radius)
      topVertices.add(ui.Offset(
        center.x + math.cos(angle) * size * 0.6 * radiusVariation,
        center.y - height + math.sin(angle) * size * 0.3 * radiusVariation,
      ));

      // Base vertex
      baseVertices.add(ui.Offset(
        center.x + math.cos(angle) * size * radiusVariation,
        center.y + math.sin(angle) * size * 0.5 * radiusVariation,
      ));
    }

    // Draw each face with different shading
    for (int i = 0; i < faces; i++) {
      final nextI = (i + 1) % faces;

      // Calculate face normal for lighting
      final faceAngle = angleOffset + i * angleStep + angleStep / 2;
      final lightFactor = (math.cos(faceAngle - math.pi / 4) + 1) / 2;

      // Create face path
      final facePath = ui.Path()
        ..moveTo(baseVertices[i].dx, baseVertices[i].dy)
        ..lineTo(topVertices[i].dx, topVertices[i].dy)
        ..lineTo(topVertices[nextI].dx, topVertices[nextI].dy)
        ..lineTo(baseVertices[nextI].dx, baseVertices[nextI].dy)
        ..close();

      // Face color based on lighting
      final baseGray = 0x50 + (lightFactor * 0x30).round();
      final faceColor = Color.fromARGB(255, baseGray, baseGray, baseGray);

      final facePaint = ui.Paint()
        ..color = faceColor
        ..style = ui.PaintingStyle.fill;

      canvas.drawPath(facePath, facePaint);

      // Draw face edge
      final edgePaint = ui.Paint()
        ..color = const Color(0xFF2A2A2A).withOpacity(0.3)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawPath(facePath, edgePaint);
    }

    // Draw top face
    final topPath = ui.Path()..moveTo(topVertices[0].dx, topVertices[0].dy);
    for (int i = 1; i < faces; i++) {
      topPath.lineTo(topVertices[i].dx, topVertices[i].dy);
    }
    topPath.close();

    final topPaint = ui.Paint()
      ..color = const Color(0xFF8A8A8A)
      ..style = ui.PaintingStyle.fill;
    canvas.drawPath(topPath, topPaint);

    // Add highlight
    final highlightPaint = ui.Paint()
      ..color = const Color(0xFFAAAAAA).withOpacity(0.5)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);

    canvas.drawCircle(
      ui.Offset(center.x + size * 0.1, center.y - height * 0.7),
      size * 0.2,
      highlightPaint,
    );
  }

  void _draw3DTrees(ui.Canvas canvas, Vector2 tileCenter, int seed) {
    final random = math.Random(seed);
    final treeCount = 1 + random.nextInt(2);

    for (int i = 0; i < treeCount; i++) {
      final offsetX = (random.nextDouble() - 0.5) * tileSize.x * 0.4;
      final offsetY = (random.nextDouble() - 0.5) * tileSize.y * 0.25;
      final treeCenter = Vector2(
        tileCenter.x + offsetX,
        tileCenter.y + offsetY,
      );

      final treeHeight = 18 + random.nextDouble() * 12;
      final trunkWidth = 2.5 + random.nextDouble() * 1.5;

      // Draw tree shadow
      final shadowPaint = ui.Paint()
        ..color = const Color(0x30000000)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

      final shadowPath = ui.Path()
        ..addOval(ui.Rect.fromCenter(
          center: ui.Offset(treeCenter.x + 5, treeCenter.y + 4),
          width: 15,
          height: 8,
        ));
      canvas.drawPath(shadowPath, shadowPaint);

      // Draw trunk with 3D effect
      final trunkPath = ui.Path()
        ..moveTo(treeCenter.x - trunkWidth, treeCenter.y)
        ..lineTo(
            treeCenter.x - trunkWidth * 0.7, treeCenter.y - treeHeight * 0.4)
        ..lineTo(
            treeCenter.x + trunkWidth * 0.7, treeCenter.y - treeHeight * 0.4)
        ..lineTo(treeCenter.x + trunkWidth, treeCenter.y)
        ..close();

      final trunkPaint = ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(treeCenter.x - trunkWidth, treeCenter.y),
          ui.Offset(treeCenter.x + trunkWidth, treeCenter.y),
          [
            const Color(0xFF3A2818),
            const Color(0xFF5A3828),
            const Color(0xFF2A1808),
          ],
          [0.0, 0.5, 1.0],
        );

      canvas.drawPath(trunkPath, trunkPaint);

      // Draw foliage with layered 3D effect
      final foliageY = treeCenter.y - treeHeight * 0.35;
      for (int layer = 0; layer < 4; layer++) {
        final layerY = foliageY - (layer * treeHeight * 0.15);
        final layerRadius = (10 - layer * 2) * (1 + random.nextDouble() * 0.3);

        // Create foliage cluster
        final clusterPaint = ui.Paint()
          ..shader = ui.Gradient.radial(
            ui.Offset(treeCenter.x, layerY),
            layerRadius,
            [
              const Color(0xFF4D7A2A),
              const Color(0xFF3D5A1A),
              const Color(0xFF2D4A0A),
            ],
            [0.0, 0.5, 1.0],
          );

        // Draw multiple overlapping circles for foliage
        for (int j = 0; j < 3; j++) {
          final offsetAngle = j * 2 * math.pi / 3;
          final offsetDist = layerRadius * 0.3;
          canvas.drawCircle(
            ui.Offset(
              treeCenter.x + math.cos(offsetAngle) * offsetDist,
              layerY + math.sin(offsetAngle) * offsetDist * 0.5,
            ),
            layerRadius * 0.8,
            clusterPaint,
          );
        }
      }

      // Add foliage highlights
      final highlightPaint = ui.Paint()
        ..color = const Color(0xFF6D9A3A).withOpacity(0.3);

      canvas.drawCircle(
        ui.Offset(treeCenter.x + 3, foliageY - treeHeight * 0.3),
        4,
        highlightPaint,
      );
    }
  }

  void _renderCommandCenters(ui.Canvas canvas, double originX, double originY) {
    for (final CommandCenter cc in _commandCenters) {
      _render3DCommandCenter(canvas, cc, originX, originY);
    }
  }

  void _render3DCommandCenter(
      ui.Canvas canvas, CommandCenter cc, double originX, double originY) {
    final int r0 = cc.topLeftRow.clamp(0, rows - 1);
    final int c0 = cc.topLeftCol.clamp(0, cols - 1);

    // Calculate center position for the 2x2 command center
    final centerRow = r0 + 0.5;
    final centerCol = c0 + 0.5;

    final Vector2 baseCenter =
        isoToScreen(centerRow, centerCol, originX, originY);
    final Vector2 topCenter = Vector2(
      baseCenter.x,
      baseCenter.y - commandCenterHeight - _floatAnimation,
    );

    // Determine colors based on player and health
    Color primaryColor;
    Color secondaryColor;
    Color glowColor;

    if (cc.isDestroyed) {
      primaryColor = const Color(0xFF424242);
      secondaryColor = const Color(0xFF212121);
      glowColor = Colors.transparent;
    } else {
      if (cc.playerIndex == 0) {
        primaryColor = const Color(0xFF2E7D32);
        secondaryColor = const Color(0xFF1B5E20);
        glowColor = const Color(0xFF4CAF50);
      } else {
        primaryColor = const Color(0xFFC62828);
        secondaryColor = const Color(0xFF8E0000);
        glowColor = const Color(0xFFEF5350);
      }
    }

    // Draw base platform (2x2 tiles)
    _drawCommandCenterBase(canvas, r0, c0, originX, originY, primaryColor);

    // Draw main structure - futuristic pyramid/tower design
    _drawCommandCenterStructure(canvas, topCenter, baseCenter, primaryColor,
        secondaryColor, glowColor, cc);

    // Draw energy shield effect if not destroyed
    if (!cc.isDestroyed) {
      _drawEnergyShield(canvas, topCenter, cc.healthPercentage, glowColor);
    }

    // Draw health bar
    if (!cc.isDestroyed) {
      _drawEnhancedHealthBar(canvas, topCenter, cc.healthPercentage, glowColor);
    }
  }

  void _drawCommandCenterBase(ui.Canvas canvas, int row, int col,
      double originX, double originY, Color color) {
    // Draw elevated platform for command center
    for (int dr = 0; dr < 2; dr++) {
      for (int dc = 0; dc < 2; dc++) {
        final r = row + dr;
        final c = col + dc;
        if (r < rows && c < cols) {
          final Vector2 center = isoToScreen(r, c, originX, originY);

          // Draw platform tile
          final platformPath = _tileDiamond(center, 1.0);
          final platformPaint = ui.Paint()
            ..color = color.withOpacity(0.8)
            ..style = ui.PaintingStyle.fill;
          canvas.drawPath(platformPath, platformPaint);

          // Draw platform edges
          final edgePaint = ui.Paint()
            ..color = _darkenColor(color, 0.3)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawPath(platformPath, edgePaint);
        }
      }
    }
  }

  void _drawCommandCenterStructure(
      ui.Canvas canvas,
      Vector2 topCenter,
      Vector2 baseCenter,
      Color primaryColor,
      Color secondaryColor,
      Color glowColor,
      CommandCenter cc) {
    // Draw a medieval castle structure
    final castleHeight = commandCenterHeight;
    final baseWidth = tileSize.x * 0.9;
    
    // Castle colors - stone-like appearance
    final stoneColor = cc.isDestroyed 
      ? const Color(0xFF424242)
      : Color.lerp(primaryColor, const Color(0xFF8D8D8D), 0.3)!;
    final darkStoneColor = _darkenColor(stoneColor, 0.3);
    
    // Draw castle walls (main body)
    _drawCastleWalls(canvas, baseCenter, baseWidth, castleHeight * 0.6, 
                     stoneColor, darkStoneColor);
    
    // Draw corner towers
    _drawCastleTowers(canvas, baseCenter, baseWidth, castleHeight, 
                      stoneColor, darkStoneColor, cc.isDestroyed);
    
    // Draw central keep
    _drawCastleKeep(canvas, baseCenter, castleHeight * 0.8, 
                    stoneColor, darkStoneColor, primaryColor, glowColor, cc);
    
    // Draw battlements
    _drawBattlements(canvas, baseCenter, baseWidth, castleHeight * 0.6, darkStoneColor);
    
    // Draw castle gate
    if (!cc.isDestroyed) {
      _drawCastleGate(canvas, baseCenter, primaryColor, glowColor);
    }
    
    // Draw flag on top
    if (!cc.isDestroyed) {
      _drawCastleFlag(canvas, baseCenter, castleHeight, primaryColor, cc.playerIndex);
    }
  }

  void _drawCastleWalls(ui.Canvas canvas, Vector2 center, double width, 
                        double height, Color stoneColor, Color darkStoneColor) {
    // Main wall structure
    final wallPath = ui.Path()
      ..moveTo(center.x - width * 0.8, center.y)
      ..lineTo(center.x - width * 0.8, center.y - height)
      ..lineTo(center.x + width * 0.8, center.y - height)
      ..lineTo(center.x + width * 0.8, center.y)
      ..close();
    
    // Stone gradient
    final wallPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x, center.y - height),
        ui.Offset(center.x, center.y),
        [
          _brightenColor(stoneColor, 0.2),
          stoneColor,
          darkStoneColor,
        ],
        [0.0, 0.3, 1.0],
      );
    
    canvas.drawPath(wallPath, wallPaint);
    
    // Draw stone texture lines
    final linePaint = ui.Paint()
      ..color = darkStoneColor.withOpacity(0.3)
      ..strokeWidth = 0.5;
    
    // Horizontal stone lines
    for (double y = center.y - height * 0.2; y > center.y - height; y -= 8) {
      canvas.drawLine(
        ui.Offset(center.x - width * 0.8, y),
        ui.Offset(center.x + width * 0.8, y),
        linePaint,
      );
    }
    
    // Vertical stone lines (staggered)
    for (double x = center.x - width * 0.7; x < center.x + width * 0.8; x += 12) {
      final yOffset = ((x - center.x) % 24 == 0) ? 0 : -4;
      canvas.drawLine(
        ui.Offset(x, center.y + yOffset),
        ui.Offset(x, center.y - height * 0.3 + yOffset),
        linePaint,
      );
    }
  }
  
  void _drawCastleTowers(ui.Canvas canvas, Vector2 center, double width, 
                         double height, Color stoneColor, Color darkStoneColor, bool isDestroyed) {
    // Draw four corner towers
    final towerPositions = [
      Vector2(center.x - width * 0.75, center.y), // Left tower
      Vector2(center.x + width * 0.75, center.y), // Right tower
      Vector2(center.x - width * 0.4, center.y - 5), // Back left
      Vector2(center.x + width * 0.4, center.y - 5), // Back right
    ];
    
    for (int i = 0; i < towerPositions.length; i++) {
      final towerPos = towerPositions[i];
      final towerHeight = height * (i < 2 ? 1.0 : 0.85); // Front towers are taller
      final towerWidth = 12.0;
      
      // Tower cylinder
      final towerPath = ui.Path()
        ..moveTo(towerPos.x - towerWidth/2, towerPos.y)
        ..lineTo(towerPos.x - towerWidth/2 * 0.8, towerPos.y - towerHeight)
        ..lineTo(towerPos.x + towerWidth/2 * 0.8, towerPos.y - towerHeight)
        ..lineTo(towerPos.x + towerWidth/2, towerPos.y)
        ..close();
      
      final towerPaint = ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(towerPos.x - towerWidth/2, towerPos.y),
          ui.Offset(towerPos.x + towerWidth/2, towerPos.y),
          [
            darkStoneColor,
            stoneColor,
            _brightenColor(stoneColor, 0.2),
            stoneColor,
            darkStoneColor,
          ],
          [0.0, 0.2, 0.5, 0.8, 1.0],
        );
      
      canvas.drawPath(towerPath, towerPaint);
      
      // Tower top (conical roof)
      if (!isDestroyed) {
        final roofPath = ui.Path()
          ..moveTo(towerPos.x - towerWidth/2 * 0.8, towerPos.y - towerHeight)
          ..lineTo(towerPos.x, towerPos.y - towerHeight - 8)
          ..lineTo(towerPos.x + towerWidth/2 * 0.8, towerPos.y - towerHeight)
          ..close();
        
        final roofPaint = ui.Paint()
          ..color = const Color(0xFF8B4513); // Brown roof
        
        canvas.drawPath(roofPath, roofPaint);
      }
      
      // Tower windows (arrow slits)
      if (!isDestroyed && i < 2) { // Only on front towers
        final windowPaint = ui.Paint()
          ..color = const Color(0xFF000000).withOpacity(0.5);
        
        for (double y = towerPos.y - towerHeight * 0.3; 
             y > towerPos.y - towerHeight * 0.8; 
             y -= towerHeight * 0.2) {
          final windowRect = ui.Rect.fromCenter(
            center: ui.Offset(towerPos.x, y),
            width: 2,
            height: 6,
          );
          canvas.drawRect(windowRect, windowPaint);
        }
      }
    }
  }
  
  void _drawCastleKeep(ui.Canvas canvas, Vector2 center, double height,
                       Color stoneColor, Color darkStoneColor, 
                       Color primaryColor, Color glowColor, CommandCenter cc) {
    // Central keep (main tower)
    final keepWidth = 20.0;
    final keepBase = Vector2(center.x, center.y - 15);
    final keepTop = Vector2(center.x, center.y - height);
    
    // Keep body
    final keepPath = ui.Path()
      ..moveTo(keepBase.x - keepWidth/2, keepBase.y)
      ..lineTo(keepTop.x - keepWidth/2 * 0.9, keepTop.y)
      ..lineTo(keepTop.x + keepWidth/2 * 0.9, keepTop.y)
      ..lineTo(keepBase.x + keepWidth/2, keepBase.y)
      ..close();
    
    final keepPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(keepTop.x, keepTop.y),
        ui.Offset(keepBase.x, keepBase.y),
        [
          _brightenColor(stoneColor, 0.3),
          stoneColor,
          darkStoneColor,
        ],
        [0.0, 0.5, 1.0],
      );
    
    canvas.drawPath(keepPath, keepPaint);
    
    // Keep window (glowing if not destroyed)
    if (!cc.isDestroyed) {
      final windowY = keepBase.y - height * 0.5;
      
      // Window frame
      final windowFrame = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset(center.x, windowY),
          width: 8,
          height: 10,
        ),
        const ui.Radius.circular(4),
      );
      
      final framePaint = ui.Paint()
        ..color = darkStoneColor;
      canvas.drawRRect(windowFrame, framePaint);
      
      // Glowing window interior
      final windowRect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromCenter(
          center: ui.Offset(center.x, windowY),
          width: 6,
          height: 8,
        ),
        const ui.Radius.circular(3),
      );
      
      // Window glow
      final glowPaint = ui.Paint()
        ..color = glowColor.withOpacity(0.4 + _pulseAnimation * 0.3)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 4 + _pulseAnimation * 2);
      canvas.drawRRect(windowRect, glowPaint);
      
      // Window fill
      final windowPaint = ui.Paint()
        ..color = Color.lerp(glowColor, const Color(0xFFFFE082), 0.5)!
                  .withOpacity(0.8 + _pulseAnimation * 0.2);
      canvas.drawRRect(windowRect, windowPaint);
    }
  }
  
  void _drawBattlements(ui.Canvas canvas, Vector2 center, double width, 
                        double height, Color darkStoneColor) {
    // Draw crenellations along the walls
    final merlonWidth = 6.0;
    final merlonHeight = 5.0;
    final merlonSpacing = 10.0;
    
    final merlonPaint = ui.Paint()
      ..color = darkStoneColor;
    
    // Front wall battlements
    for (double x = center.x - width * 0.7; x < center.x + width * 0.7; x += merlonSpacing) {
      final merlonRect = ui.Rect.fromLTWH(
        x - merlonWidth/2,
        center.y - height - merlonHeight,
        merlonWidth,
        merlonHeight,
      );
      canvas.drawRect(merlonRect, merlonPaint);
    }
  }
  
  void _drawCastleGate(ui.Canvas canvas, Vector2 center, Color primaryColor, Color glowColor) {
    // Draw the main gate
    final gateWidth = 12.0;
    final gateHeight = 15.0;
    final gateY = center.y - 2;
    
    // Gate arch
    final gatePath = ui.Path()
      ..moveTo(center.x - gateWidth/2, gateY)
      ..lineTo(center.x - gateWidth/2, gateY - gateHeight * 0.7)
      ..quadraticBezierTo(
        center.x, gateY - gateHeight,
        center.x + gateWidth/2, gateY - gateHeight * 0.7,
      )
      ..lineTo(center.x + gateWidth/2, gateY)
      ..close();
    
    // Gate gradient (darker at bottom)
    final gatePaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x, gateY - gateHeight),
        ui.Offset(center.x, gateY),
        [
          const Color(0xFF2A2A2A),
          const Color(0xFF1A1A1A),
        ],
        [0.0, 1.0],
      );
    
    canvas.drawPath(gatePath, gatePaint);
    
    // Gate portcullis bars
    final barPaint = ui.Paint()
      ..color = const Color(0xFF0A0A0A)
      ..strokeWidth = 1;
    
    for (double x = center.x - gateWidth/2 + 2; x < center.x + gateWidth/2; x += 3) {
      canvas.drawLine(
        ui.Offset(x, gateY),
        ui.Offset(x, gateY - gateHeight * 0.7),
        barPaint,
      );
    }
    
    // Gate glow (magical protection)
    final glowPaint = ui.Paint()
      ..color = glowColor.withOpacity(0.2 + _pulseAnimation * 0.1)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawPath(gatePath, glowPaint);
  }
  
  void _drawCastleFlag(ui.Canvas canvas, Vector2 center, double height, 
                       Color primaryColor, int playerIndex) {
    // Draw flag on the highest point
    final flagPoleBase = Vector2(center.x, center.y - height);
    final flagPoleTop = Vector2(center.x, center.y - height - 20);
    
    // Flag pole
    final polePaint = ui.Paint()
      ..color = const Color(0xFF4A4A4A)
      ..strokeWidth = 2;
    
    canvas.drawLine(
      ui.Offset(flagPoleBase.x, flagPoleBase.y),
      ui.Offset(flagPoleTop.x, flagPoleTop.y),
      polePaint,
    );
    
    // Flag (waving animation)
    final flagWidth = 15.0;
    final flagHeight = 10.0;
    final waveOffset = math.sin(_time * 3) * 2;
    
    final flagPath = ui.Path()
      ..moveTo(flagPoleTop.x, flagPoleTop.y)
      ..quadraticBezierTo(
        flagPoleTop.x + flagWidth/2 + waveOffset,
        flagPoleTop.y + 2,
        flagPoleTop.x + flagWidth + waveOffset * 1.5,
        flagPoleTop.y + 3,
      )
      ..quadraticBezierTo(
        flagPoleTop.x + flagWidth/2 + waveOffset,
        flagPoleTop.y + flagHeight - 2,
        flagPoleTop.x,
        flagPoleTop.y + flagHeight,
      )
      ..close();
    
    // Flag color based on player
    final flagColor = playerIndex == 0 
      ? const Color(0xFF2E7D32)  // Green for player 0
      : const Color(0xFFC62828); // Red for player 1
    
    final flagPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(flagPoleTop.x, flagPoleTop.y),
        ui.Offset(flagPoleTop.x + flagWidth, flagPoleTop.y),
        [
          flagColor,
          _brightenColor(flagColor, 0.3),
          flagColor,
        ],
        [0.0, 0.5, 1.0],
      );
    
    canvas.drawPath(flagPath, flagPaint);
    
    // Flag emblem (simple design)
    final emblemPaint = ui.Paint()
      ..color = Colors.white.withOpacity(0.8);
    
    if (playerIndex == 0) {
      // Draw a shield for player 0
      canvas.drawCircle(
        ui.Offset(flagPoleTop.x + flagWidth/2 + waveOffset * 0.7, flagPoleTop.y + flagHeight/2),
        3,
        emblemPaint,
      );
    } else {
      // Draw a cross for player 1  
      final crossCenter = ui.Offset(
        flagPoleTop.x + flagWidth/2 + waveOffset * 0.7, 
        flagPoleTop.y + flagHeight/2
      );
      canvas.drawLine(
        ui.Offset(crossCenter.dx - 3, crossCenter.dy),
        ui.Offset(crossCenter.dx + 3, crossCenter.dy),
        emblemPaint..strokeWidth = 2,
      );
      canvas.drawLine(
        ui.Offset(crossCenter.dx, crossCenter.dy - 3),
        ui.Offset(crossCenter.dx, crossCenter.dy + 3),
        emblemPaint,
      );
    }
  }

  void _drawEnergyShield(
      ui.Canvas canvas, Vector2 center, double healthPercent, Color color) {
    if (healthPercent <= 0) return;

    // Draw hexagonal energy shield
    final shieldRadius = 35.0 + _pulseAnimation * 3;
    final shieldPaint = ui.Paint()
      ..color = color.withOpacity(0.1 + _pulseAnimation * 0.1)
      ..style = ui.PaintingStyle.fill;

    final shieldPath = _createHexagon(center, shieldRadius);
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield border
    final borderPaint = ui.Paint()
      ..color = color.withOpacity(0.3 + _pulseAnimation * 0.2)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(shieldPath, borderPaint);

    // Energy particles around shield
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + _time;
      final particleX = center.x + math.cos(angle) * shieldRadius;
      final particleY = center.y + math.sin(angle) * shieldRadius * 0.5;

      final particlePaint = ui.Paint()
        ..color = color.withOpacity(0.6 + _pulseAnimation * 0.4)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

      canvas.drawCircle(
        ui.Offset(particleX, particleY),
        2,
        particlePaint,
      );
    }
  }

  ui.Path _createHexagon(Vector2 center, double radius) {
    final path = ui.Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 6;
      final x = center.x + math.cos(angle) * radius;
      final y = center.y + math.sin(angle) * radius * 0.5;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawEnhancedHealthBar(
      ui.Canvas canvas, Vector2 center, double healthPercent, Color glowColor) {
    const double barWidth = 50.0;
    const double barHeight = 8.0;
    const double barOffsetY = -50.0;

    final double barX = center.x - barWidth / 2;
    final double barY = center.y + barOffsetY;

    // Background with glow
    final bgRect =
        ui.Rect.fromLTWH(barX - 2, barY - 2, barWidth + 4, barHeight + 4);
    final bgPaint = ui.Paint()
      ..color = const Color(0xFF000000).withOpacity(0.5)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(4)),
      bgPaint,
    );

    // Health fill with gradient
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

    // Animated glow on health bar
    if (healthPercent > 0 && healthPercent < 1) {
      final glowPaint = ui.Paint()
        ..color = glowColor.withOpacity(0.3 * _pulseAnimation)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(3)),
        glowPaint,
      );
    }

    // Border
    final borderPaint = ui.Paint()
      ..color = Colors.white.withOpacity(0.8)
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

  void _renderParticles(ui.Canvas canvas) {
    for (final particle in _particles) {
      particle.render(canvas);
    }
  }

  void _renderOverlays(ui.Canvas canvas, double originX, double originY) {
    // Render hover effect
    if (hoveredRow != null && hoveredCol != null) {
      final Vector2 center =
          isoToScreen(hoveredRow!, hoveredCol!, originX, originY);

      final hoverPath = _tileDiamond(center, 1.05);
      final hoverPaint = ui.Paint()
        ..color = Colors.white.withOpacity(0.2 + _pulseAnimation * 0.1)
        ..style = ui.PaintingStyle.fill;
      canvas.drawPath(hoverPath, hoverPaint);

      final hoverBorderPaint = ui.Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(hoverPath, hoverBorderPaint);
    }

    // Render selection effect
    if (highlightedRow != null && highlightedCol != null) {
      final Vector2 center =
          isoToScreen(highlightedRow!, highlightedCol!, originX, originY);

      // Animated selection ring
      final selectionPath = _tileDiamond(center, 1.1 + _pulseAnimation * 0.05);
      final selectionPaint = ui.Paint()
        ..color =
            const Color(0xFF54C7EC).withOpacity(0.3 + _pulseAnimation * 0.2)
        ..style = ui.PaintingStyle.fill;
      canvas.drawPath(selectionPath, selectionPaint);

      final selectionBorderPaint = ui.Paint()
        ..color = const Color(0xFF54C7EC)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2 + _pulseAnimation;
      canvas.drawPath(selectionPath, selectionBorderPaint);

      // Corner markers
      _drawSelectionCorners(canvas, center);
    }
  }

  void _drawSelectionCorners(ui.Canvas canvas, Vector2 center) {
    final cornerPaint = ui.Paint()
      ..color = const Color(0xFF54C7EC)
      ..strokeWidth = 3
      ..style = ui.PaintingStyle.stroke;

    final halfW = tileSize.x / 2;
    final halfH = tileSize.y / 2;
    const cornerSize = 8.0;

    // Top corner
    canvas.drawLine(
      ui.Offset(center.x - cornerSize, center.y - halfH),
      ui.Offset(center.x, center.y - halfH - cornerSize),
      cornerPaint,
    );
    canvas.drawLine(
      ui.Offset(center.x, center.y - halfH - cornerSize),
      ui.Offset(center.x + cornerSize, center.y - halfH),
      cornerPaint,
    );

    // Bottom corner
    canvas.drawLine(
      ui.Offset(center.x - cornerSize, center.y + halfH),
      ui.Offset(center.x, center.y + halfH + cornerSize),
      cornerPaint,
    );
    canvas.drawLine(
      ui.Offset(center.x, center.y + halfH + cornerSize),
      ui.Offset(center.x + cornerSize, center.y + halfH),
      cornerPaint,
    );
  }

  Color _getEnhancedTerrainColor(TerrainType terrain, double moisture) {
    Color baseColor;
    switch (terrain) {
      case TerrainType.grass:
        baseColor = Color.lerp(
          const Color(0xFF4A5D23),
          const Color(0xFF5D7A2B),
          moisture,
        )!;
        break;
      case TerrainType.stone:
        baseColor = Color.lerp(
          const Color(0xFF5A5A5A),
          const Color(0xFF6B6B6B),
          moisture * 0.5,
        )!;
        break;
      case TerrainType.water:
        baseColor = Color.lerp(
          const Color(0xFF1E5984),
          const Color(0xFF2E6994),
          moisture,
        )!;
        break;
      case TerrainType.desert:
        baseColor = Color.lerp(
          const Color(0xFF8B7355),
          const Color(0xFF9B8365),
          moisture * 0.3,
        )!;
        break;
      case TerrainType.forest:
        baseColor = Color.lerp(
          const Color(0xFF2D4A22),
          const Color(0xFF3D5A32),
          moisture * 0.7,
        )!;
        break;
      case TerrainType.mountain:
        baseColor = Color.lerp(
          const Color(0xFF4A3728),
          const Color(0xFF5A4738),
          moisture * 0.4,
        )!;
        break;
    }
    return baseColor;
  }

  Color _brightenColor(Color color, double factor) {
    return Color.fromARGB(
      color.alpha,
      (color.red + ((255 - color.red) * factor)).round().clamp(0, 255),
      (color.green + ((255 - color.green) * factor)).round().clamp(0, 255),
      (color.blue + ((255 - color.blue) * factor)).round().clamp(0, 255),
    );
  }

  Color _darkenColor(Color color, double factor) {
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - factor)).round().clamp(0, 255),
      (color.green * (1 - factor)).round().clamp(0, 255),
      (color.blue * (1 - factor)).round().clamp(0, 255),
    );
  }

  Vector2 isoToScreen(num row, num col, double originX, double originY) {
    final double rowD = row.toDouble();
    final double colD = col.toDouble();
    final double screenX = (colD - rowD) * (tileSize.x / 2) + originX;
    final double screenY = (colD + rowD) * (tileSize.y / 2) + originY;
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

  Vector2? _pickTileAt(Vector2 localPoint) {
    final double originX = size.x / 2;
    const double originY = 50;

    final double dx = localPoint.x - originX;
    final double dy = localPoint.y - originY;

    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    // Invert isoToScreen mapping
    final double colF = (dy / halfH + dx / halfW) / 2.0;
    final double rowF = (dy / halfH - dx / halfW) / 2.0;

    final int rc = rowF.round();
    final int cc = colF.round();

    // Check rounded tile first, then direct neighbors
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

  void clearHover() {
    hoveredRow = null;
    hoveredCol = null;
  }

  static List<CommandCenter> computeDefaultCommandCenters(int rows, int cols) {
    final int centerCol = cols ~/ 2;
    final int topLeftCol = (centerCol - 1).clamp(0, cols - 2);

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

/// Simple particle class for ambient effects
class Particle {
  Vector2 position;
  Vector2 velocity;
  double life;
  Color color;
  double maxLife;

  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.color,
  }) : maxLife = life;

  void update(double dt) {
    position += velocity * dt;
    velocity.y += 20 * dt; // Gravity
    life -= dt;
  }

  void render(ui.Canvas canvas) {
    if (life <= 0) return;

    final opacity = (life / maxLife).clamp(0.0, 1.0);
    final paint = ui.Paint()
      ..color = color.withOpacity(opacity * 0.6)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);

    canvas.drawCircle(
      ui.Offset(position.x, position.y),
      2 + (1 - opacity) * 3,
      paint,
    );
  }
}
