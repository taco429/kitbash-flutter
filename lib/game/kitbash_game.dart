import 'dart:async';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../services/game_service.dart';
import 'models/game_state.dart';
import 'components/board_component.dart';
import 'components/hand_component.dart';
import 'components/card_component.dart';

class KitbashGame extends FlameGame with TapCallbacks, DragCallbacks {
  final String gameId;
  final GameService gameService;
  late final StreamSubscription<GameEvent> _subscription;
  final GameState state = GameState.empty();

  KitbashGame({required this.gameId, required this.gameService});

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

  @override
  Future<void> onLoad() async {
    // Initialize game components
    debugPrint('Loading game: $gameId');

    // TODO: Load game assets
    // Initialize placeholder board and hand components
    final board = BoardComponent();
    final hand = HandComponent();
    await add(board);
    await add(hand);

    // Add a couple of placeholder cards to the hand area
    final demoCards = [
      CardComponent(cardId: 'c1', name: 'Spark Mage', cost: 1)..position = Vector2(80, 560),
      CardComponent(cardId: 'c2', name: 'Stone Golem', cost: 3)..position = Vector2(196, 560),
      CardComponent(cardId: 'c3', name: 'Wind Scout', cost: 2)..position = Vector2(312, 560),
    ];
    for (final c in demoCards) {
      await add(c);
    }
    // TODO: Load player decks
    // TODO: Connect to game service for real-time updates

    _subscription = gameService.events.listen((event) {
      switch (event.type) {
        case GameEventType.connected:
          debugPrint('GameService connected');
          break;
        case GameEventType.disconnected:
          debugPrint('GameService disconnected');
          break;
        case GameEventType.message:
          _handleServerMessage(event.data ?? {});
          break;
      }
    });
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Handle tap events
    debugPrint('Tapped at: ${event.localPosition}');
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

  void _handleServerMessage(Map<String, dynamic> message) {
    // Simple echo for now; extend with real message handling later
    debugPrint('Server message in game: $message');
  }

  @override
  void onRemove() {
    // Clean up subscription when game is removed
    try {
      _subscription.cancel();
    } catch (_) {}
    super.onRemove();
  }
}
