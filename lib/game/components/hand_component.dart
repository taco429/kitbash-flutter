import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HandComponent extends PositionComponent {
  HandComponent();

  @override
  Future<void> onLoad() async {
    size = Vector2(1000, 160);
    position = Vector2(60, 540);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Offset.zero & Size(size.x, size.y);
    final paint = Paint()..color = const Color(0xFF222222);
    canvas.drawRect(rect, paint);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.2);
    canvas.drawRect(rect, border);

    // Placeholder card slots
    final slotPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.3);
    const slotWidth = 100.0;
    const slotHeight = 140.0;
    const gap = 16.0;
    var x = 16.0;
    for (var i = 0; i < 8; i++) {
      final slotRect = Rect.fromLTWH(x, 10, slotWidth, slotHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(slotRect, const Radius.circular(8)),
        slotPaint,
      );
      x += slotWidth + gap;
    }
  }
}

