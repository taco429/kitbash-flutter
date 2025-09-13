import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../models/tile_data.dart';

/// Enhanced Isometric Grid Component with 2.5D/3D visual effects
class EnhancedIsometricGridComponent extends PositionComponent {
  final int rows;
  final int cols;
  final Vector2 tileSize;
  final GameService gameService;
  List<CommandCenter> _commandCenters;
  
  // Animation timers
  double _time = 0;
  double _waterAnimationTime = 0;
  double _vegetationSwayTime = 0;
  
  // Tile states
  int? highlightedRow;
  int? highlightedCol;
  int? hoveredRow;
  int? hoveredCol;
  
  // Tile data storage
  late List<List<TileData>> _tileData;
  late List<List<double>> _tileElevations;
  late List<List<double>> _tileAnimationOffsets;
  
  // Visual enhancement flags
  bool enableShadows = true;
  bool enableAnimations = true;
  bool enableParticles = true;
  bool enable3DEffect = true;
  
  // Particle system for atmospheric effects
  final List<Particle> _particles = [];
  
  EnhancedIsometricGridComponent({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.gameService,
    List<CommandCenter>? commandCenters,
  }) : _commandCenters = commandCenters ?? <CommandCenter>[] {
    size = Vector2(
      (cols + rows) * (tileSize.x / 2) + 100, // Extra space for 3D effects
      (cols + rows) * (tileSize.y / 2) + 200, // Extra height for elevation
    );
    
    _initializeTileData();
    _initializeElevations();
    _initializeParticles();
  }
  
  void _initializeTileData() {
    final random = math.Random(42); // Consistent seed for terrain generation
    _tileData = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        // Generate more interesting terrain patterns
        final noise = _perlinNoise(row * 0.1, col * 0.1);
        final distance = ((row - rows / 2).abs() + (col - cols / 2).abs()) / 2;
        
        TerrainType terrain;
        if (noise < -0.3) {
          terrain = TerrainType.water;
        } else if (noise < -0.1) {
          terrain = TerrainType.desert;
        } else if (noise < 0.1) {
          terrain = TerrainType.grass;
        } else if (noise < 0.3) {
          terrain = TerrainType.forest;
        } else if (noise < 0.5) {
          terrain = TerrainType.stone;
        } else {
          terrain = TerrainType.mountain;
        }
        
        // Add some variation based on distance from center
        if (distance < 2 && terrain != TerrainType.water) {
          terrain = TerrainType.grass;
        }
        
        return TileData(
          row: row,
          col: col,
          terrain: terrain,
        );
      });
    });
    
    // Initialize animation offsets for each tile
    _tileAnimationOffsets = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        return random.nextDouble() * math.pi * 2;
      });
    });
  }
  
  void _initializeElevations() {
    _tileElevations = List.generate(rows, (row) {
      return List.generate(cols, (col) {
        final terrain = _tileData[row][col].terrain;
        return _getTerrainElevation(terrain);
      });
    });
  }
  
  double _getTerrainElevation(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.water:
        return -8.0;
      case TerrainType.desert:
        return 2.0;
      case TerrainType.grass:
        return 0.0;
      case TerrainType.forest:
        return 4.0;
      case TerrainType.stone:
        return 8.0;
      case TerrainType.mountain:
        return 16.0;
    }
  }
  
  void _initializeParticles() {
    final random = math.Random();
    // Add some atmospheric particles
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        position: Vector2(
          random.nextDouble() * size.x,
          random.nextDouble() * size.y,
        ),
        velocity: Vector2(
          (random.nextDouble() - 0.5) * 10,
          -random.nextDouble() * 20 - 10,
        ),
        life: random.nextDouble() * 3 + 2,
        maxLife: 5,
        color: Colors.white.withOpacity(0.3),
        size: random.nextDouble() * 2 + 1,
      ));
    }
  }
  
  // Simple Perlin noise approximation for terrain generation
  double _perlinNoise(double x, double y) {
    final n = math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
    return (n - n.floor()) * 2 - 1;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (enableAnimations) {
      _time += dt;
      _waterAnimationTime += dt * 2;
      _vegetationSwayTime += dt * 0.5;
    }
    
    if (enableParticles) {
      _updateParticles(dt);
    }
  }
  
  void _updateParticles(double dt) {
    final random = math.Random();
    
    // Update existing particles
    _particles.removeWhere((particle) {
      particle.life -= dt;
      particle.position += particle.velocity * dt;
      particle.velocity.y += 50 * dt; // Gravity
      
      // Reset particle if it goes off screen
      if (particle.life <= 0 || particle.position.y > size.y) {
        return true;
      }
      return false;
    });
    
    // Add new particles occasionally
    if (_particles.length < 30 && random.nextDouble() < 0.1) {
      _particles.add(Particle(
        position: Vector2(
          random.nextDouble() * size.x,
          size.y,
        ),
        velocity: Vector2(
          (random.nextDouble() - 0.5) * 20,
          -random.nextDouble() * 30 - 20,
        ),
        life: random.nextDouble() * 3 + 2,
        maxLife: 5,
        color: Colors.white.withOpacity(0.2),
        size: random.nextDouble() * 3 + 1,
      ));
    }
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
    const double originY = 50; // Offset for 3D effect
    
    // First pass: Draw shadows
    if (enableShadows) {
      _renderShadows(canvas, originX, originY);
    }
    
    // Second pass: Draw tiles from back to front for proper depth sorting
    for (int r = rows - 1; r >= 0; r--) {
      for (int c = cols - 1; c >= 0; c--) {
        _renderEnhancedTile(canvas, r, c, originX, originY);
      }
    }
    
    // Third pass: Draw command centers
    _renderCommandCenters(canvas, originX, originY);
    
    // Fourth pass: Draw particles
    if (enableParticles) {
      _renderParticles(canvas);
    }
    
    // Fifth pass: Draw UI overlays (health bars, etc.)
    _renderUIOverlays(canvas, originX, originY);
  }
  
  void _renderShadows(ui.Canvas canvas, double originX, double originY) {
    final shadowPaint = ui.Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final elevation = _tileElevations[r][c];
        if (elevation > 0) {
          final center = isoToScreen(r, c, originX, originY);
          final shadowOffset = Vector2(elevation * 0.5, elevation * 0.3);
          final shadowCenter = center + shadowOffset;
          
          final shadowPath = _tileDiamond(shadowCenter, 1.1);
          canvas.drawPath(shadowPath, shadowPaint);
        }
      }
    }
  }
  
  void _renderEnhancedTile(ui.Canvas canvas, int r, int c, double originX, double originY) {
    final tileData = _tileData[r][c];
    final elevation = _tileElevations[r][c];
    final animOffset = _tileAnimationOffsets[r][c];
    
    Vector2 center = isoToScreen(r, c, originX, originY);
    
    // Apply elevation
    if (enable3DEffect) {
      center = Vector2(center.x, center.y - elevation);
    }
    
    // Apply animation for certain terrain types
    if (enableAnimations) {
      if (tileData.terrain == TerrainType.water) {
        final wave = math.sin(_waterAnimationTime + animOffset) * 2;
        center = Vector2(center.x, center.y + wave);
      } else if (tileData.terrain == TerrainType.forest || tileData.terrain == TerrainType.grass) {
        final sway = math.sin(_vegetationSwayTime + animOffset) * 0.5;
        center = Vector2(center.x + sway, center.y);
      }
    }
    
    // Draw tile with 3D effect
    if (enable3DEffect && elevation != 0) {
      _draw3DTile(canvas, center, tileData.terrain, elevation);
    } else {
      _drawFlatTile(canvas, center, tileData.terrain);
    }
    
    // Draw tile decorations
    _drawTileDecorations(canvas, center, tileData.terrain, animOffset);
    
    // Apply hover effect
    if (hoveredRow == r && hoveredCol == c) {
      _drawHoverEffect(canvas, center);
    }
    
    // Apply selection highlight
    if (highlightedRow == r && highlightedCol == c) {
      _drawSelectionEffect(canvas, center);
    }
  }
  
  void _draw3DTile(ui.Canvas canvas, Vector2 center, TerrainType terrain, double elevation) {
    final baseColor = getEnhancedTerrainColor(terrain);
    final darkColor = Color.lerp(baseColor, Colors.black, 0.3)!;
    final lightColor = Color.lerp(baseColor, Colors.white, 0.2)!;
    
    // Draw tile sides for 3D effect
    if (elevation > 0) {
      final sideHeight = elevation.abs();
      final leftSidePath = ui.Path()
        ..moveTo(center.x - tileSize.x / 2, center.y)
        ..lineTo(center.x - tileSize.x / 2, center.y + sideHeight)
        ..lineTo(center.x, center.y + tileSize.y / 2 + sideHeight)
        ..lineTo(center.x, center.y + tileSize.y / 2)
        ..close();
      
      final rightSidePath = ui.Path()
        ..moveTo(center.x, center.y + tileSize.y / 2)
        ..lineTo(center.x, center.y + tileSize.y / 2 + sideHeight)
        ..lineTo(center.x + tileSize.x / 2, center.y + sideHeight)
        ..lineTo(center.x + tileSize.x / 2, center.y)
        ..close();
      
      final leftSidePaint = ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(center.x - tileSize.x / 2, center.y),
          ui.Offset(center.x - tileSize.x / 2, center.y + sideHeight),
          [darkColor, darkColor.withOpacity(0.8)],
        );
      
      final rightSidePaint = ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(center.x + tileSize.x / 2, center.y),
          ui.Offset(center.x + tileSize.x / 2, center.y + sideHeight),
          [darkColor.withOpacity(0.9), darkColor.withOpacity(0.7)],
        );
      
      canvas.drawPath(leftSidePath, leftSidePaint);
      canvas.drawPath(rightSidePath, rightSidePaint);
    }
    
    // Draw main tile surface with gradient
    final tilePath = _tileDiamond(center, 1.0);
    final gradientPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(center.x, center.y),
        tileSize.x / 2,
        [lightColor, baseColor, darkColor],
        [0.0, 0.5, 1.0],
      );
    
    canvas.drawPath(tilePath, gradientPaint);
    
    // Add edge highlights
    final edgePaint = ui.Paint()
      ..color = lightColor.withOpacity(0.5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(tilePath, edgePaint);
    
    // Add texture pattern
    _drawTexturePattern(canvas, center, terrain);
  }
  
  void _drawFlatTile(ui.Canvas canvas, Vector2 center, TerrainType terrain) {
    final baseColor = getEnhancedTerrainColor(terrain);
    final tilePath = _tileDiamond(center, 1.0);
    
    final paint = ui.Paint()..color = baseColor;
    canvas.drawPath(tilePath, paint);
    
    // Add subtle gradient even for flat tiles
    final gradientPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(center.x, center.y),
        tileSize.x / 2,
        [baseColor.withOpacity(0.8), baseColor],
        [0.0, 1.0],
      )
      ..blendMode = ui.BlendMode.overlay;
    canvas.drawPath(tilePath, gradientPaint);
    
    // Edge
    final edgePaint = ui.Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(tilePath, edgePaint);
  }
  
  void _drawTexturePattern(ui.Canvas canvas, Vector2 center, TerrainType terrain) {
    final patternPaint = ui.Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = ui.PaintingStyle.stroke;
    
    switch (terrain) {
      case TerrainType.stone:
      case TerrainType.mountain:
        // Draw cracks
        for (int i = 0; i < 3; i++) {
          final offset = (i - 1) * 8.0;
          canvas.drawLine(
            ui.Offset(center.x - 10 + offset, center.y - 5),
            ui.Offset(center.x - 5 + offset, center.y + 5),
            patternPaint,
          );
        }
        break;
      case TerrainType.water:
        // Draw ripples
        for (int i = 1; i <= 2; i++) {
          canvas.drawCircle(
            ui.Offset(center.x, center.y),
            i * 8.0,
            patternPaint..color = Colors.white.withOpacity(0.05 * i),
          );
        }
        break;
      case TerrainType.grass:
      case TerrainType.forest:
        // Draw grass blades
        final grassPaint = ui.Paint()
          ..color = Colors.green.shade900.withOpacity(0.3)
          ..strokeWidth = 1;
        for (int i = 0; i < 5; i++) {
          final x = center.x + (i - 2) * 5;
          canvas.drawLine(
            ui.Offset(x, center.y + 3),
            ui.Offset(x - 1, center.y - 3),
            grassPaint,
          );
        }
        break;
      default:
        break;
    }
  }
  
  void _drawTileDecorations(ui.Canvas canvas, Vector2 center, TerrainType terrain, double animOffset) {
    if (!enableAnimations) return;
    
    switch (terrain) {
      case TerrainType.forest:
        // Draw animated trees
        final treePaint = ui.Paint()..color = Colors.green.shade800;
        final trunkPaint = ui.Paint()..color = Colors.brown.shade700;
        
        final swayOffset = math.sin(_vegetationSwayTime + animOffset) * 2;
        
        // Tree trunk
        canvas.drawRect(
          ui.Rect.fromCenter(
            center: ui.Offset(center.x + swayOffset / 2, center.y - 5),
            width: 3,
            height: 10,
          ),
          trunkPaint,
        );
        
        // Tree crown
        canvas.drawCircle(
          ui.Offset(center.x + swayOffset, center.y - 10),
          6,
          treePaint,
        );
        break;
        
      case TerrainType.water:
        // Draw animated water sparkles
        final sparkleAlpha = (math.sin(_waterAnimationTime * 3 + animOffset) + 1) / 2;
        final sparklePaint = ui.Paint()
          ..color = Colors.white.withOpacity(sparkleAlpha * 0.5)
          ..strokeWidth = 1;
        
        canvas.drawCircle(
          ui.Offset(center.x - 5, center.y),
          2,
          sparklePaint,
        );
        canvas.drawCircle(
          ui.Offset(center.x + 5, center.y - 3),
          1.5,
          sparklePaint,
        );
        break;
        
      case TerrainType.mountain:
        // Draw snow cap
        final snowPaint = ui.Paint()..color = Colors.white.withOpacity(0.7);
        final snowPath = ui.Path()
          ..moveTo(center.x, center.y - tileSize.y / 4)
          ..lineTo(center.x - tileSize.x / 4, center.y - tileSize.y / 8)
          ..lineTo(center.x, center.y - tileSize.y / 6)
          ..lineTo(center.x + tileSize.x / 4, center.y - tileSize.y / 8)
          ..close();
        canvas.drawPath(snowPath, snowPaint);
        break;
        
      default:
        break;
    }
  }
  
  void _drawHoverEffect(ui.Canvas canvas, Vector2 center) {
    // Animated glow effect
    final glowRadius = 30 + math.sin(_time * 3) * 5;
    final glowPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(center.x, center.y),
        glowRadius,
        [
          Colors.cyan.withOpacity(0.4),
          Colors.cyan.withOpacity(0.2),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    
    canvas.drawCircle(ui.Offset(center.x, center.y), glowRadius, glowPaint);
    
    // Highlight border
    final highlightPath = _tileDiamond(center, 1.05);
    final highlightPaint = ui.Paint()
      ..color = Colors.cyan
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(highlightPath, highlightPaint);
  }
  
  void _drawSelectionEffect(ui.Canvas canvas, Vector2 center) {
    // Pulsing selection effect
    final pulseScale = 1.0 + math.sin(_time * 4) * 0.05;
    final selectionPath = _tileDiamond(center, pulseScale);
    
    final selectionPaint = ui.Paint()
      ..color = Colors.yellow.withOpacity(0.5)
      ..style = ui.PaintingStyle.fill;
    canvas.drawPath(selectionPath, selectionPaint);
    
    final borderPaint = ui.Paint()
      ..color = Colors.yellow
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(selectionPath, borderPaint);
  }
  
  void _renderCommandCenters(ui.Canvas canvas, double originX, double originY) {
    for (final CommandCenter cc in _commandCenters) {
      final int r0 = cc.topLeftRow.clamp(0, rows - 1);
      final int c0 = cc.topLeftCol.clamp(0, cols - 1);
      
      // Draw command center as a larger elevated structure
      final centerRow = r0 + 0.5;
      final centerCol = c0 + 0.5;
      final center = isoToScreen(centerRow.toInt(), centerCol.toInt(), originX, originY);
      final elevatedCenter = Vector2(center.x, center.y - 20);
      
      // Draw base platform
      final platformPath = ui.Path();
      final platforms = <Vector2>[];
      for (int dr = 0; dr < 2; dr++) {
        for (int dc = 0; dc < 2; dc++) {
          if (r0 + dr < rows && c0 + dc < cols) {
            final pos = isoToScreen(r0 + dr, c0 + dc, originX, originY);
            platforms.add(Vector2(pos.x, pos.y - 10));
          }
        }
      }
      
      if (platforms.isNotEmpty) {
        // Draw platform shadow
        final shadowPaint = ui.Paint()
          ..color = const Color(0x60000000)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
        
        for (final platform in platforms) {
          final shadowPath = _tileDiamond(Vector2(platform.x + 5, platform.y + 5), 1.2);
          canvas.drawPath(shadowPath, shadowPaint);
        }
        
        // Draw platform tiles
        final Color baseColor = cc.isDestroyed
            ? const Color(0xFF424242)
            : (cc.playerIndex == 0 ? const Color(0xFF1B5E20) : const Color(0xFF880E4F));
        
        for (final platform in platforms) {
          // Draw 3D sides
          final sideHeight = 15.0;
          final leftSide = ui.Path()
            ..moveTo(platform.x - tileSize.x / 2, platform.y)
            ..lineTo(platform.x - tileSize.x / 2, platform.y + sideHeight)
            ..lineTo(platform.x, platform.y + tileSize.y / 2 + sideHeight)
            ..lineTo(platform.x, platform.y + tileSize.y / 2)
            ..close();
          
          final rightSide = ui.Path()
            ..moveTo(platform.x, platform.y + tileSize.y / 2)
            ..lineTo(platform.x, platform.y + tileSize.y / 2 + sideHeight)
            ..lineTo(platform.x + tileSize.x / 2, platform.y + sideHeight)
            ..lineTo(platform.x + tileSize.x / 2, platform.y)
            ..close();
          
          final sidePaint = ui.Paint()
            ..color = Color.lerp(baseColor, Colors.black, 0.4)!;
          
          canvas.drawPath(leftSide, sidePaint);
          canvas.drawPath(rightSide, sidePaint);
          
          // Draw top surface
          final topPath = _tileDiamond(platform, 1.0);
          final topPaint = ui.Paint()
            ..shader = ui.Gradient.linear(
              ui.Offset(platform.x - tileSize.x / 2, platform.y - tileSize.y / 2),
              ui.Offset(platform.x + tileSize.x / 2, platform.y + tileSize.y / 2),
              [
                Color.lerp(baseColor, Colors.white, 0.2)!,
                baseColor,
                Color.lerp(baseColor, Colors.black, 0.2)!,
              ],
            );
          canvas.drawPath(topPath, topPaint);
          
          // Edge highlight
          final edgePaint = ui.Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 1;
          canvas.drawPath(topPath, edgePaint);
        }
        
        // Draw central structure
        if (!cc.isDestroyed) {
          _drawCommandCenterStructure(canvas, elevatedCenter, cc.playerIndex);
        }
      }
    }
  }
  
  void _drawCommandCenterStructure(ui.Canvas canvas, Vector2 center, int playerIndex) {
    // Draw a futuristic tower structure
    final baseColor = playerIndex == 0 ? Colors.green : Colors.pink;
    
    // Tower base
    final basePath = ui.Path()
      ..addRect(ui.Rect.fromCenter(
        center: ui.Offset(center.x, center.y),
        width: 20,
        height: 30,
      ));
    
    final basePaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(center.x, center.y - 15),
        ui.Offset(center.x, center.y + 15),
        [
          Color.lerp(baseColor, Colors.white, 0.3)!,
          baseColor,
        ],
      );
    canvas.drawPath(basePath, basePaint);
    
    // Tower top with animation
    final topOffset = math.sin(_time * 2) * 2;
    final topPath = ui.Path()
      ..moveTo(center.x - 10, center.y - 15)
      ..lineTo(center.x, center.y - 25 + topOffset)
      ..lineTo(center.x + 10, center.y - 15)
      ..close();
    
    final topPaint = ui.Paint()
      ..color = Color.lerp(baseColor, Colors.white, 0.5)!;
    canvas.drawPath(topPath, topPaint);
    
    // Energy core (animated)
    final coreRadius = 3 + math.sin(_time * 4) * 1;
    final corePaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(center.x, center.y),
        coreRadius * 2,
        [
          Colors.white,
          baseColor,
          baseColor.withOpacity(0),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawCircle(ui.Offset(center.x, center.y), coreRadius * 2, corePaint);
  }
  
  void _renderParticles(ui.Canvas canvas) {
    for (final particle in _particles) {
      final opacity = particle.color.opacity * (particle.life / particle.maxLife);
      final paint = ui.Paint()
        ..color = particle.color.withOpacity(opacity)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
      
      canvas.drawCircle(
        ui.Offset(particle.position.x, particle.position.y),
        particle.size,
        paint,
      );
    }
  }
  
  void _renderUIOverlays(ui.Canvas canvas, double originX, double originY) {
    // Render health bars for command centers
    for (final CommandCenter cc in _commandCenters) {
      if (cc.isDestroyed) continue;
      
      final int r0 = cc.topLeftRow.clamp(0, rows - 1);
      final int c0 = cc.topLeftCol.clamp(0, cols - 1);
      final center = isoToScreen(r0, c0, originX, originY);
      
      _drawHealthBar(
        canvas,
        Vector2(center.x + tileSize.x / 2, center.y - 35),
        cc.healthPercentage,
        cc.playerIndex,
      );
    }
  }
  
  void _drawHealthBar(ui.Canvas canvas, Vector2 position, double healthPercentage, int playerIndex) {
    const double barWidth = 50.0;
    const double barHeight = 8.0;
    
    // Background
    final bgRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(position.x - barWidth / 2, position.y, barWidth, barHeight),
      const ui.Radius.circular(4),
    );
    canvas.drawRRect(bgRect, ui.Paint()..color = const Color(0xAA000000));
    
    // Health fill with gradient
    final fillWidth = barWidth * healthPercentage;
    final fillRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(position.x - barWidth / 2, position.y, fillWidth, barHeight),
      const ui.Radius.circular(4),
    );
    
    final healthColor = healthPercentage > 0.3
        ? (playerIndex == 0 ? Colors.green : Colors.pink)
        : Colors.red;
    
    final fillPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(position.x - barWidth / 2, position.y),
        ui.Offset(position.x - barWidth / 2, position.y + barHeight),
        [
          Color.lerp(healthColor, Colors.white, 0.3)!,
          healthColor,
        ],
      );
    canvas.drawRRect(fillRect, fillPaint);
    
    // Border with glow
    final borderPaint = ui.Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bgRect, borderPaint);
  }
  
  Color getEnhancedTerrainColor(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.grass:
        return const Color(0xFF4CAF50);
      case TerrainType.stone:
        return const Color(0xFF757575);
      case TerrainType.water:
        return const Color(0xFF2196F3);
      case TerrainType.desert:
        return const Color(0xFFFFB74D);
      case TerrainType.forest:
        return const Color(0xFF2E7D32);
      case TerrainType.mountain:
        return const Color(0xFF5D4037);
    }
  }
  
  Vector2 isoToScreen(int row, int col, double originX, double originY) {
    final double screenX = (col - row) * (tileSize.x / 2) + originX;
    final double screenY = (col + row) * (tileSize.y / 2) + originY;
    return Vector2(screenX, screenY);
  }
  
  ui.Path _tileDiamond(Vector2 center, double scale) {
    final double halfW = (tileSize.x / 2) * scale;
    final double halfH = (tileSize.y / 2) * scale;
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

/// Simple particle class for atmospheric effects
class Particle {
  Vector2 position;
  Vector2 velocity;
  double life;
  final double maxLife;
  final Color color;
  final double size;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });
}