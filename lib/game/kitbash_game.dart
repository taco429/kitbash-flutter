import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'components/card_component.dart';
    

class KitbashGame extends FlameGame with TapCallbacks, DragCallbacks {
  final String gameId;
  
  KitbashGame({required this.gameId}) {
    // Enable debug mode to see component boundaries
    debugMode = false;
  }

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

  @override
  Future<void> onLoad() async {
    // Initialize game components
    debugPrint('Loading game: $gameId');
    
    // TODO: Load game assets
    // TODO: Initialize game board
    // TODO: Load player decks
    // TODO: Connect to game service for real-time updates
    
    // Example: Add a test card (remove this in production)
    // Uncomment the following lines to test drag and drop:
    
    // final testCard = CardComponent(
    //   cardId: 'test-1',
    //   cardName: 'Test Card',
    //   position: Vector2(size.x / 2, size.y / 2),
    // );
    // add(testCard);
    
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Handle tap events
    // event.localPosition gives position relative to the game widget
    // event.canvasPosition gives position relative to the game canvas
    debugPrint('Tapped at: ${event.localPosition}');
    
    // TODO: Check if tap is on a card or game element
  }

  @override
  void onDragStart(DragStartEvent event) {
    // Handle drag start for card movement
    debugPrint('Drag started at: ${event.localPosition}');
    
    // TODO: Check if drag started on a draggable card
    // TODO: Store reference to dragged card
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Handle drag update
    // Note: DragUpdateEvent has limited position info
    // You may need to track position manually from start event
    debugPrint('Drag update');
    
    // TODO: Update position of dragged card
    // TODO: Show visual feedback for valid drop zones
  }

  @override
  void onDragEnd(DragEndEvent event) {
    // Handle drag end
    debugPrint('Drag ended');
    
    // TODO: Check if card was dropped in valid zone
    // TODO: Execute card action or return to original position
  }
} 