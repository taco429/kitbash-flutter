import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// Example draggable card component for the game
class CardComponent extends PositionComponent with DragCallbacks, TapCallbacks {
  final String cardId;
  final String cardName;
  late TextComponent nameText;
  Vector2? _dragStartPosition;
  Vector2? _dragOffset;
  bool _isDragging = false;

  CardComponent({
    required this.cardId,
    required this.cardName,
    required Vector2 position,
    Vector2? size,
  }) : super(
          position: position,
          size: size ?? Vector2(80, 120),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    // Add visual representation
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.blue.shade700
        ..style = PaintingStyle.fill,
    ),);

    // Add border
    add(RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ),);

    // Add card name
    nameText = TextComponent(
      text: cardName,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(size.x / 2, size.y - 20),
      anchor: Anchor.center,
    );
    add(nameText);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _dragStartPosition = position.clone();
    
    // Visual feedback - scale up slightly
    add(ScaleEffect.to(
      Vector2.all(1.1),
      EffectController(duration: 0.1),
    ),);
    
    // Bring to front by changing priority
    priority = 1000;
  }


  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    priority = 0;
    
    // Visual feedback - scale back to normal
    add(ScaleEffect.to(
      Vector2.all(1.0),
      EffectController(duration: 0.1),
    ),);
    
    // TODO: Check if dropped in valid zone
    // For now, just snap back to original position
    if (_dragStartPosition != null) {
      add(MoveToEffect(
        _dragStartPosition!,
        EffectController(duration: 0.3, curve: Curves.easeOut),
      ),);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Handle tap on card (e.g., show details, select)
    debugPrint('Card tapped: $cardName');
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // This determines the hit area for the card
    return super.containsLocalPoint(point);
  }
} 