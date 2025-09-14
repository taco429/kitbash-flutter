import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../models/tile_data.dart';

/// Enhanced isometric grid component with 2.5D/3D visual effects
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
  final double baseElevation = 8.0;
  final double tileDepth = 12.0;
  final double shadowOffset = 4.0;
  final double commandCenterHeight = 40.0;

  // Animation properties
  double _time = 0.0;
  double _pulseAnimation = 0.0;
  double _floatAnimation = 0.0;

  // Tile data and elevation map
  late List<List<TileData>> _tileData;
  late List<List<double>> _elevationMap;
  late List<List<double>> _moistureMap;

  // Gradient paints provision removed (unused shaders)

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
    _initializeElevationMap();
    // Shaders removed (unused)
  }

  void _initializeTileData() {
    // Seeded randomness reserved for future use (removed unused var)
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

  void _initializeElevationMap() {
    final random = math.Random(42);
    _elevationMap = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        final terrain = _tileData[row][col].terrain;
        double baseHeight = 0.0;

        // Set base height based on terrain type
        switch (terrain) {
          case TerrainType.water:
            baseHeight = -5.0;
            break;
          case TerrainType.grass:
            baseHeight = 0.0;
            break;
          case TerrainType.forest:
            baseHeight = 2.0;
            break;
          case TerrainType.desert:
            baseHeight = 1.0;
            break;
          case TerrainType.stone:
            baseHeight = 4.0;
            break;
          case TerrainType.mountain:
            baseHeight = 8.0 + random.nextDouble() * 4.0;
            break;
        }

        // Add some noise for natural variation
        baseHeight += (random.nextDouble() - 0.5) * 2.0;
        return baseHeight.clamp(-5.0, 12.0);
      });
    });

    // Smooth the elevation map
    _smoothElevationMap();

    // Initialize moisture map for visual variety
    _moistureMap = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        return random.nextDouble();
      });
    });
  }

  void _smoothElevationMap() {
    // Apply smoothing filter to create more natural terrain
    for (int iter = 0; iter < 2; iter++) {
      final smoothed = List.generate(rows, (row) {
        return List.generate(cols, (col) {
          double sum = _elevationMap[row][col] * 4;
          int count = 4;

          // Average with neighbors
          if (row > 0) {
            sum += _elevationMap[row - 1][col];
            count++;
          }
          if (row < rows - 1) {
            sum += _elevationMap[row + 1][col];
            count++;
          }
          if (col > 0) {
            sum += _elevationMap[row][col - 1];
            count++;
          }
          if (col < cols - 1) {
            sum += _elevationMap[row][col + 1];
            count++;
          }

          return sum / count;
        });
      });
      _elevationMap = smoothed;
    }
  }

  // Shaders removed

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
          .withValues(alpha: 0.6),
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

    // First pass: render shadows
    _renderShadows(canvas, originX, originY);

    // Second pass: render tiles with 3D effect
    _renderTiles(canvas, originX, originY);

    // Third pass: render command centers with unique 3D structures
    _renderCommandCenters(canvas, originX, originY);

    // Fourth pass: render particles and effects
    _renderParticles(canvas);

    // Fifth pass: render overlays (hover, selection)
    _renderOverlays(canvas, originX, originY);
  }

  void _renderShadows(ui.Canvas canvas, double originX, double originY) {
    final shadowPaint = ui.Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

    for (int r = rows - 1; r >= 0; r--) {
      for (int c = cols - 1; c >= 0; c--) {
        final elevation = _elevationMap[r][c];
        final Vector2 center = isoToScreen(r, c, originX, originY, elevation);

        // Draw shadow offset based on elevation
        final shadowCenter = Vector2(
          center.x + shadowOffset + elevation * 0.5,
          center.y + shadowOffset + elevation * 0.3,
        );

        final ui.Path shadowPath = _tileDiamond(shadowCenter, 1.1);
        canvas.drawPath(shadowPath, shadowPaint);
      }
    }
  }

  void _renderTiles(ui.Canvas canvas, double originX, double originY) {
    // Render tiles from back to front for proper depth sorting
    for (int r = rows - 1; r >= 0; r--) {
      for (int c = cols - 1; c >= 0; c--) {
        _render3DTile(canvas, r, c, originX, originY);
      }
    }
  }

  void _render3DTile(
      ui.Canvas canvas, int row, int col, double originX, double originY) {
    final elevation = _elevationMap[row][col];
    final terrain = _tileData[row][col].terrain;
    final moisture = _moistureMap[row][col];

    final Vector2 topCenter =
        isoToScreen(row, col, originX, originY, elevation);
    final Vector2 baseCenter = isoToScreen(row, col, originX, originY, 0);

    // Calculate tile vertices for 3D effect
    final double halfW = tileSize.x / 2;
    final double halfH = tileSize.y / 2;

    // Get terrain color with moisture variation
    final Color baseColor = _getEnhancedTerrainColor(terrain, moisture);

    // Draw tile sides (3D depth effect)
    if (elevation > 0) {
      _drawTileSides(
          canvas, topCenter, baseCenter, halfW, halfH, baseColor, elevation);
    }

    // Draw tile top face with gradient
    final ui.Path topPath = _tileDiamond(topCenter, 1.0);

    // Create gradient paint for top face
    final topPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(topCenter.x, topCenter.y),
        halfW * 1.5,
        [
          _brightenColor(baseColor, 0.2),
          baseColor,
          _darkenColor(baseColor, 0.1),
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawPath(topPath, topPaint);

    // Add texture details based on terrain type
    _drawTerrainDetails(canvas, topCenter, terrain, halfW, halfH);

    // Draw tile outline
    final outlinePaint = ui.Paint()
      ..color = _darkenColor(baseColor, 0.3).withValues(alpha: 0.5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(topPath, outlinePaint);
  }

  void _drawTileSides(ui.Canvas canvas, Vector2 topCenter, Vector2 baseCenter,
      double halfW, double halfH, Color baseColor, double elevation) {
    // Calculate the actual depth to draw
    final depth = math.min(elevation + tileDepth, 20.0);

    // Left side face
    final leftSidePath = ui.Path()
      ..moveTo(topCenter.x - halfW, topCenter.y)
      ..lineTo(topCenter.x, topCenter.y + halfH)
      ..lineTo(topCenter.x, topCenter.y + halfH + depth)
      ..lineTo(topCenter.x - halfW, topCenter.y + depth)
      ..close();

    final leftPaint = ui.Paint()..color = _darkenColor(baseColor, 0.4);
    canvas.drawPath(leftSidePath, leftPaint);

    // Right side face
    final rightSidePath = ui.Path()
      ..moveTo(topCenter.x, topCenter.y + halfH)
      ..lineTo(topCenter.x + halfW, topCenter.y)
      ..lineTo(topCenter.x + halfW, topCenter.y + depth)
      ..lineTo(topCenter.x, topCenter.y + halfH + depth)
      ..close();

    final rightPaint = ui.Paint()..color = _darkenColor(baseColor, 0.25);
    canvas.drawPath(rightSidePath, rightPaint);
  }

  void _drawTerrainDetails(ui.Canvas canvas, Vector2 center,
      TerrainType terrain, double halfW, double halfH) {
    final detailPaint = ui.Paint()..style = ui.PaintingStyle.fill;

    switch (terrain) {
      case TerrainType.forest:
        // Draw small tree representations
        for (int i = 0; i < 3; i++) {
          final offset = Vector2(
            center.x + (i - 1) * halfW * 0.3,
            center.y + (i - 1) * halfH * 0.2,
          );
          detailPaint.color = const Color(0xFF1B5E20).withValues(alpha: 0.6);
          canvas.drawCircle(ui.Offset(offset.x, offset.y - 2), 3, detailPaint);
        }
        break;

      case TerrainType.mountain:
        // Draw rocky texture
        detailPaint.color = const Color(0xFF424242).withValues(alpha: 0.3);
        canvas.drawCircle(
            ui.Offset(center.x - halfW * 0.3, center.y), 2, detailPaint);
        canvas.drawCircle(
            ui.Offset(center.x + halfW * 0.2, center.y - halfH * 0.2),
            3,
            detailPaint);
        break;

      case TerrainType.water:
        // Draw water ripples
        detailPaint
          ..color = const Color(0xFF64B5F6).withValues(alpha: 0.3)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(
            ui.Offset(center.x, center.y), halfW * 0.3, detailPaint);
        break;

      default:
        break;
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
    const double elevation = 5.0; // Command centers are elevated

    final Vector2 baseCenter =
        isoToScreen(centerRow, centerCol, originX, originY, 0);
    final Vector2 topCenter = isoToScreen(centerRow, centerCol, originX,
        originY, elevation + commandCenterHeight + _floatAnimation);

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
          final Vector2 center = isoToScreen(r, c, originX, originY, 5.0);

          // Draw platform tile
          final platformPath = _tileDiamond(center, 1.0);
          final platformPaint = ui.Paint()
            ..color = color.withValues(alpha: 0.8)
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
    // Draw a futuristic tower/pyramid structure
    final structureHeight = commandCenterHeight;
    final baseWidth = tileSize.x * 0.8;
    final topWidth = tileSize.x * 0.3;

    // Calculate structure points
    final Vector2 structureBase = Vector2(baseCenter.x, baseCenter.y - 10);
    final Vector2 structureTop =
        Vector2(topCenter.x, topCenter.y - structureHeight);

    // Draw main tower body (trapezoid)
    final towerPath = ui.Path()
      ..moveTo(structureBase.x - baseWidth, structureBase.y)
      ..lineTo(structureTop.x - topWidth, structureTop.y)
      ..lineTo(structureTop.x + topWidth, structureTop.y)
      ..lineTo(structureBase.x + baseWidth, structureBase.y)
      ..close();

    // Create gradient for tower
    final towerPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(structureTop.x, structureTop.y),
        ui.Offset(structureBase.x, structureBase.y),
        [
          _brightenColor(primaryColor, 0.3),
          primaryColor,
          secondaryColor,
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawPath(towerPath, towerPaint);

    // Draw tower edges
    final edgePaint = ui.Paint()
      ..color = _brightenColor(primaryColor, 0.4)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(towerPath, edgePaint);

    // Draw glowing core/window
    if (!cc.isDestroyed) {
      final corePath = ui.Path()
        ..moveTo(structureTop.x - topWidth * 0.5, structureTop.y + 5)
        ..lineTo(structureTop.x - topWidth * 0.3, structureTop.y + 15)
        ..lineTo(structureTop.x + topWidth * 0.3, structureTop.y + 15)
        ..lineTo(structureTop.x + topWidth * 0.5, structureTop.y + 5)
        ..close();

      // Pulsing glow effect
      final glowPaint = ui.Paint()
        ..color = glowColor.withValues(alpha: 0.6 + _pulseAnimation * 0.4)
        ..maskFilter =
            ui.MaskFilter.blur(ui.BlurStyle.normal, 3 + _pulseAnimation * 2);
      canvas.drawPath(corePath, glowPaint);

      final corePaint = ui.Paint()..color = _brightenColor(glowColor, 0.5);
      canvas.drawPath(corePath, corePaint);
    }

    // Draw antenna/beacon on top
    if (!cc.isDestroyed) {
      final antennaBase = Vector2(structureTop.x, structureTop.y);
      final antennaTop = Vector2(structureTop.x, structureTop.y - 15);

      final antennaPaint = ui.Paint()
        ..color = secondaryColor
        ..strokeWidth = 3
        ..style = ui.PaintingStyle.stroke;

      canvas.drawLine(
        ui.Offset(antennaBase.x, antennaBase.y),
        ui.Offset(antennaTop.x, antennaTop.y),
        antennaPaint,
      );

      // Beacon light
      final beaconPaint = ui.Paint()
        ..color = glowColor.withValues(alpha: 0.8 + _pulseAnimation * 0.2)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
      canvas.drawCircle(
        ui.Offset(antennaTop.x, antennaTop.y),
        3 + _pulseAnimation * 2,
        beaconPaint,
      );
    }
  }

  void _drawEnergyShield(
      ui.Canvas canvas, Vector2 center, double healthPercent, Color color) {
    if (healthPercent <= 0) return;

    // Draw hexagonal energy shield
    final double shieldRadius = 35.0 + _pulseAnimation * 3;
    final shieldPaint = ui.Paint()
      ..color = color.withValues(alpha: 0.1 + _pulseAnimation * 0.1)
      ..style = ui.PaintingStyle.fill;

    final shieldPath = _createHexagon(center, shieldRadius);
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield border
    final borderPaint = ui.Paint()
      ..color = color.withValues(alpha: 0.3 + _pulseAnimation * 0.2)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(shieldPath, borderPaint);

    // Energy particles around shield
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) + _time;
      final particleX = center.x + math.cos(angle) * shieldRadius;
      final particleY = center.y + math.sin(angle) * shieldRadius * 0.5;

      final particlePaint = ui.Paint()
        ..color = color.withValues(alpha: 0.6 + _pulseAnimation * 0.4)
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
      ..color = const Color(0xFF000000).withValues(alpha: 0.5)
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
        ..color = glowColor.withValues(alpha: 0.3 * _pulseAnimation)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(3)),
        glowPaint,
      );
    }

    // Border
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

  void _renderParticles(ui.Canvas canvas) {
    for (final particle in _particles) {
      particle.render(canvas);
    }
  }

  void _renderOverlays(ui.Canvas canvas, double originX, double originY) {
    // Render hover effect
    if (hoveredRow != null && hoveredCol != null) {
      final elevation = _elevationMap[hoveredRow!][hoveredCol!];
      final Vector2 center =
          isoToScreen(hoveredRow!, hoveredCol!, originX, originY, elevation);

      final hoverPath = _tileDiamond(center, 1.05);
      final hoverPaint = ui.Paint()
        ..color = Colors.white.withValues(alpha: 0.2 + _pulseAnimation * 0.1)
        ..style = ui.PaintingStyle.fill;
      canvas.drawPath(hoverPath, hoverPaint);

      final hoverBorderPaint = ui.Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(hoverPath, hoverBorderPaint);
    }

    // Render selection effect
    if (highlightedRow != null && highlightedCol != null) {
      final elevation = _elevationMap[highlightedRow!][highlightedCol!];
      final Vector2 center = isoToScreen(
          highlightedRow!, highlightedCol!, originX, originY, elevation);

      // Animated selection ring
      final selectionPath = _tileDiamond(center, 1.1 + _pulseAnimation * 0.05);
      final selectionPaint = ui.Paint()
        ..color = const Color(0xFF54C7EC)
            .withValues(alpha: 0.3 + _pulseAnimation * 0.2)
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

    final double halfH = tileSize.y / 2;
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
    final double r = color.r + ((1.0 - color.r) * factor);
    final double g = color.g + ((1.0 - color.g) * factor);
    final double b = color.b + ((1.0 - color.b) * factor);
    return color.withValues(
        red: r.clamp(0.0, 1.0),
        green: g.clamp(0.0, 1.0),
        blue: b.clamp(0.0, 1.0));
  }

  Color _darkenColor(Color color, double factor) {
    final double r = color.r * (1.0 - factor);
    final double g = color.g * (1.0 - factor);
    final double b = color.b * (1.0 - factor);
    return color.withValues(
        red: r.clamp(0.0, 1.0),
        green: g.clamp(0.0, 1.0),
        blue: b.clamp(0.0, 1.0));
  }

  Vector2 isoToScreen(num row, num col, double originX, double originY,
      [num elevation = 0]) {
    final double rowD = row.toDouble();
    final double colD = col.toDouble();
    final double elevD = elevation.toDouble();
    final double screenX = (colD - rowD) * (tileSize.x / 2) + originX;
    final double screenY = (colD + rowD) * (tileSize.y / 2) + originY - elevD;
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

      final elevation = _elevationMap[row][col];
      final Vector2 center = isoToScreen(row, col, originX, originY, elevation);
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

    final double opacity = (life / maxLife).clamp(0.0, 1.0);
    final paint = ui.Paint()
      ..color = color.withValues(alpha: opacity * 0.6)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);

    canvas.drawCircle(
      ui.Offset(position.x, position.y),
      2 + (1 - opacity) * 3,
      paint,
    );
  }
}
