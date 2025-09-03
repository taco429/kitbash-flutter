import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/card.dart';

/// Service for managing the game's card collection
class CardService extends ChangeNotifier {
  Map<String, GameCard> _cardDatabase = {};
  bool _isLoading = false;
  String? _error;
  
  // Backend API base URL - should be configurable
  static const String _baseUrl = 'http://localhost:8080/api';
  
  CardService() {
    _loadCardsFromBackend();
  }

  /// Load cards from the backend API
  Future<void> _loadCardsFromBackend() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cards'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final cardsJson = data['cards'] as List<dynamic>;
        
        _cardDatabase.clear();
        for (final cardJson in cardsJson) {
          final card = GameCard.fromJson(cardJson as Map<String, dynamic>);
          _cardDatabase[card.id] = card;
        }
        
        debugPrint('Loaded ${_cardDatabase.length} cards from backend');
      } else {
        throw Exception('Failed to load cards: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to load cards: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get loading state
  bool get isLoading => _isLoading;
  
  /// Get error state
  String? get error => _error;
  
  /// Refresh cards from backend
  Future<void> refreshCards() async {
    await _loadCardsFromBackend();
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