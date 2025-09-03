import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/cards/creatures.dart';

/// Service for managing the game's card collection
class CardService extends ChangeNotifier {
  late final Map<String, GameCard> _cardDatabase;
  
  CardService() {
    _initializeCardDatabase();
  }

  /// Initialize the card database with all available cards
  void _initializeCardDatabase() {
    _cardDatabase = <String, GameCard>{};
    
    // Add all creature cards to the database
    for (final card in CreatureCards.allCreatures) {
      _cardDatabase[card.id] = card;
    }
    
    debugPrint('Initialized card database with ${_cardDatabase.length} cards');
  }

  /// Get all available cards
  List<GameCard> get allCards => _cardDatabase.values.toList();

  /// Get a card by its ID
  GameCard? getCardById(String cardId) {
    return _cardDatabase[cardId];
  }

  /// Get all cards of a specific color
  List<GameCard> getCardsByColor(CardColor color) {
    return _cardDatabase.values
        .where((card) => card.color == color)
        .toList();
  }

  /// Get all cards of a specific type
  List<GameCard> getCardsByType(CardType type) {
    return _cardDatabase.values
        .where((card) => card.type == type)
        .toList();
  }

  /// Get all creature cards
  List<GameCard> get creatureCards => getCardsByType(CardType.creature);

  /// Get all spell cards
  List<GameCard> get spellCards => getCardsByType(CardType.spell);

  /// Get all red cards (goblins)
  List<GameCard> get redCards => getCardsByColor(CardColor.red);

  /// Get all purple cards (skeletons)
  List<GameCard> get purpleCards => getCardsByColor(CardColor.purple);

  /// Search for cards by name (case-insensitive)
  List<GameCard> searchCardsByName(String query) {
    if (query.isEmpty) return allCards;
    
    final lowercaseQuery = query.toLowerCase();
    return _cardDatabase.values
        .where((card) => card.name.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Get cards that cost a specific amount
  List<GameCard> getCardsByCost(int cost) {
    return _cardDatabase.values
        .where((card) => card.cost == cost)
        .toList();
  }

  /// Get cards within a cost range
  List<GameCard> getCardsByCostRange(int minCost, int maxCost) {
    return _cardDatabase.values
        .where((card) => card.cost >= minCost && card.cost <= maxCost)
        .toList();
  }

  /// Check if a card exists in the database
  bool cardExists(String cardId) {
    return _cardDatabase.containsKey(cardId);
  }

  /// Get the total number of cards in the database
  int get totalCards => _cardDatabase.length;

  /// Get cards with specific abilities
  List<GameCard> getCardsByAbility(String ability) {
    return _cardDatabase.values
        .where((card) => card.abilities.contains(ability))
        .toList();
  }

  /// Get summary statistics about the card collection
  Map<String, int> getCollectionStats() {
    final stats = <String, int>{};
    
    // Count by color
    for (final color in CardColor.values) {
      stats['${color.name}_count'] = getCardsByColor(color).length;
    }
    
    // Count by type
    for (final type in CardType.values) {
      stats['${type.name}_count'] = getCardsByType(type).length;
    }
    
    stats['total_cards'] = totalCards;
    
    return stats;
  }
}