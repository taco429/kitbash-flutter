import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class CardComponent extends PositionComponent with DragCallbacks, TapCallbacks {
  final String cardId;
  final String name;
  final int cost;

  Vector2? _dragStartPos;

  CardComponent({required this.cardId, required this.name, required this.cost});

  @override
  Future<void> onLoad() async {
    size = Vector2(100, 140);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Offset.zero & Size(size.x, size.y);
    final bg = Paint()..color = const Color(0xFF0E3A5A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      bg,
    );
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      border,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    );
    textPainter.layout(maxWidth: size.x - 12);
    textPainter.paint(canvas, const Offset(6, 8));

    final costPainter = TextPainter(
      text: TextSpan(
        text: cost.toString(),
        style: const TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    costPainter.layout();
    costPainter.paint(canvas, Offset(size.x - costPainter.width - 8, 8));
  }

  @override
  void onDragStart(DragStartEvent event) {
    _dragStartPos = position.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.add(event.delta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // Placeholder: snap back for now
    if (_dragStartPos != null) {
      position.setFrom(_dragStartPos!);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Placeholder interaction; keep for future expansion
  }
}

