import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/deck.dart';
import '../models/card.dart';

class DeckService extends ChangeNotifier {
  final List<Deck> _availableDecks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;
  String? _error;

  // Backend API base URL - should be configurable
  static const String _baseUrl = 'http://192.168.4.156:8080/api';

  List<Deck> get availableDecks => List.unmodifiable(_availableDecks);
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DeckService() {
    _loadDecksFromBackend();
  }

  /// Load decks from the backend API
  Future<void> _loadDecksFromBackend() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/decks/prebuilt'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final decksJson = data['decks'] as List<dynamic>;

        _availableDecks.clear();
        for (final deckJson in decksJson) {
          final deck = _parseDeckFromBackend(deckJson as Map<String, dynamic>);
          _availableDecks.add(deck);
        }

        // Select the first deck by default
        if (_availableDecks.isNotEmpty && _selectedDeck == null) {
          _selectedDeck = _availableDecks.first;
        }

        debugPrint('Loaded ${_availableDecks.length} decks from backend');
      } else {
        throw Exception('Failed to load decks: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Failed to load decks: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Parse a deck from backend response format
  Deck _parseDeckFromBackend(Map<String, dynamic> json) {
    final pawnCards = <DeckCard>[];
    final mainCards = <DeckCard>[];

    // Parse populated cards from backend response
    if (json['populatedCards'] != null) {
      final populatedCards = json['populatedCards'] as List<dynamic>;
      for (final cardEntry in populatedCards) {
        final cardData = cardEntry['card'] as Map<String, dynamic>;
        final quantity = cardEntry['quantity'] as int;

        final card = GameCard.fromJson(cardData);
        final deckCard = DeckCard(card: card, quantity: quantity);

        // For now, we'll categorize based on card ID patterns
        // TODO: Backend should indicate if card is pawn or main card
        if (card.id.contains('pawn')) {
          pawnCards.add(deckCard);
        } else if (card.id.contains('hero')) {
          // Hero cards are handled separately
          continue;
        } else {
          mainCards.add(deckCard);
        }
      }
    }

    return Deck(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      description: json['description'] ?? '',
      heroCardId: json['heroCardId'],
      pawnCards: pawnCards,
      mainCards: mainCards,
    );
  }

  void selectDeck(Deck deck) {
    if (_availableDecks.contains(deck)) {
      _selectedDeck = deck;
      notifyListeners();
    }
  }

  void selectDeckById(String deckId) {
    try {
      final deck = _availableDecks.firstWhere((d) => d.id == deckId);
      selectDeck(deck);
    } catch (e) {
      debugPrint('Deck with id $deckId not found');
    }
  }

  bool isDeckSelected(Deck deck) {
    return _selectedDeck?.id == deck.id;
  }

  /// Refresh decks from backend
  Future<void> loadDecks() async {
    await _loadDecksFromBackend();
  }

  // Future method for when we add deck saving to backend
  Future<void> saveDeckSelection() async {
    // TODO: Implement saving deck selection to backend
    debugPrint('Selected deck: ${_selectedDeck?.name}');
  }

  /// Get all cards in a specific deck
  List<DeckCard> getDeckCards(String deckId) {
    try {
      final deck = _availableDecks.firstWhere((d) => d.id == deckId);
      return deck.allCards;
    } catch (e) {
      debugPrint('Deck with id $deckId not found');
      return [];
    }
  }

  /// Get the total card count for a deck
  int getDeckCardCount(String deckId) {
    try {
      final deck = _availableDecks.firstWhere((d) => d.id == deckId);
      return deck.cardCount;
    } catch (e) {
      debugPrint('Deck with id $deckId not found');
      return 0;
    }
  }
}
