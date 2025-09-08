import 'package:flutter/foundation.dart';

import 'card.dart';
import 'card_instance.dart';

/// Payload used when dragging a card from the hand onto the board
class CardDragPayload {
  /// The static card definition
  final GameCard card;

  /// The specific instance of the card in the player's hand
  final CardInstance? instance;

  /// Index of the card in the hand UI at drag start
  final int handIndex;

  const CardDragPayload({
    required this.card,
    required this.handIndex,
    this.instance,
  });

  @override
  String toString() {
    return 'CardDragPayload(cardId=${card.id}, instanceId=${instance?.instanceId}, handIndex=$handIndex)';
  }
}

