import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BoardComponent extends PositionComponent {
  BoardComponent();

  @override
  Future<void> onLoad() async {
    size = Vector2(800, 400);
    position = Vector2(100, 100);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Offset.zero & Size(size.x, size.y);
    final paint = Paint()..color = const Color(0xFF3A3A3A);
    canvas.drawRect(rect, paint);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.2);
    canvas.drawRect(rect, border);
  }
}

