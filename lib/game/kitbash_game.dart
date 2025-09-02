import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../services/game_service.dart';

class KitbashGame extends FlameGame with TapCallbacks, DragCallbacks {
  final String gameId;
  final GameService gameService;
  IsometricGridComponent? _grid;

  KitbashGame({required this.gameId, required this.gameService});

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

  @override
  Future<void> onLoad() async {
    // Initialize game components
    debugPrint('Loading game: $gameId');

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

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Handle drag start for card movement
    debugPrint('Drag started at: ${event.localPosition}');
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Handle drag update
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    // Handle drag end
    debugPrint('Drag ended');
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
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Update command centers from game service
    final gameState = gameService.gameState;
    if (gameState != null && gameState.commandCenters.isNotEmpty) {
      _commandCenters = gameState.commandCenters;
    }

    final ui.Paint basePaint = ui.Paint()..color = const Color(0xFF3A3F4B);
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
        final Vector2 center = _isoToScreen(r, c, originX, originY);
        final ui.Path diamond = _tileDiamond(center);

        // Fill
        canvas.drawPath(diamond, basePaint);
        // Stroke
        canvas.drawPath(diamond, gridLinePaint);

        if (highlightedRow == r && highlightedCol == c) {
          canvas.drawPath(diamond, highlightPaint);
        }
      }
    }

    // Render command centers as 2x2 overlays with health bars
    for (final CommandCenter cc in _commandCenters) {
      final int r0 = cc.topLeftRow.clamp(0, rows - 1);
      final int c0 = cc.topLeftCol.clamp(0, cols - 1);
      final List<Vector2> centers = <Vector2>[
        _isoToScreen(r0, c0, originX, originY),
        if (c0 + 1 < cols) _isoToScreen(r0, c0 + 1, originX, originY),
        if (r0 + 1 < rows) _isoToScreen(r0 + 1, c0, originX, originY),
        if (r0 + 1 < rows && c0 + 1 < cols)
          _isoToScreen(r0 + 1, c0 + 1, originX, originY),
      ];

      // Choose color based on health
      ui.Paint paint;
      if (cc.isDestroyed) {
        paint = ui.Paint()..color = const Color(0xCC666666); // Gray for destroyed
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
        _drawHealthBar(canvas, topCenter, cc.healthPercentage, healthBarBg, 
                     cc.healthPercentage > 0.3 ? healthBarFill : healthBarLow,);
      }
    }
  }

  void handleTap(Vector2 localPoint) {
    final Vector2? grid = _screenToIso(localPoint);
    if (grid != null) {
      highlightedRow = grid.y.toInt();
      highlightedCol = grid.x.toInt();
    }
  }

  Vector2 _isoToScreen(int row, int col, double originX, double originY) {
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

  void _drawHealthBar(ui.Canvas canvas, Vector2 center, double healthPercentage, 
                     ui.Paint bgPaint, ui.Paint fillPaint,) {
    const double barWidth = 40.0;
    const double barHeight = 6.0;
    const double barOffsetY = -25.0; // Position above the command center

    final double barX = center.x - barWidth / 2;
    final double barY = center.y + barOffsetY;

    // Draw background
    final ui.Rect bgRect = ui.Rect.fromLTWH(barX, barY, barWidth, barHeight);
    canvas.drawRRect(ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(3)), bgPaint);

    // Draw health fill
    final double fillWidth = barWidth * healthPercentage;
    final ui.Rect fillRect = ui.Rect.fromLTWH(barX, barY, fillWidth, barHeight);
    canvas.drawRRect(ui.RRect.fromRectAndRadius(fillRect, const ui.Radius.circular(3)), fillPaint);

    // Draw border
    final ui.Paint borderPaint = ui.Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(ui.RRect.fromRectAndRadius(bgRect, const ui.Radius.circular(3)), borderPaint);
  }

  Vector2? _screenToIso(Vector2 localPoint) {
    // Reverse transform from screen (inside component) to grid indices
    final double originX = size.x / 2;
    const double originY = 0;

    final double dx = localPoint.x - originX;
    final double dy = localPoint.y - originY;

    // Based on equations:
    // x = (col - row) * tileW/2
    // y = (col + row) * tileH/2
    final double col = (dy / (tileSize.y / 2) + dx / (tileSize.x / 2)) / 2;
    final double row = (dy / (tileSize.y / 2) - dx / (tileSize.x / 2)) / 2;

    final int ci = col.floor();
    final int ri = row.floor();

    if (ci < 0 || ri < 0 || ci >= cols || ri >= rows) {
      return null;
    }
    return Vector2(ci.toDouble(), ri.toDouble());
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
