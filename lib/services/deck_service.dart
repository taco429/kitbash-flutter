import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/deck.dart';
import '../models/card.dart';

class DeckService extends ChangeNotifier {
  final List<Deck> _availableDecks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;
  String? _error;

  // Backend API base URL - should be configurable
  // For web platform, this needs to match the backend server's CORS settings
  static String get _baseUrl {
    if (kIsWeb) {
      // For web, try to use the same host if possible, or configure for CORS
      return 'http://localhost:8080/api';
    }
    return 'http://localhost:8080/api';
  }

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
      debugPrint('Fetching decks from: $_baseUrl/decks/prebuilt');
      final response = await http.get(
        Uri.parse('$_baseUrl/decks/prebuilt'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final decksJson = data['decks'] as List<dynamic>;

        _availableDecks.clear();
        for (final deckJson in decksJson) {
          try {
            final deck = _parseDeckFromBackend(deckJson as Map<String, dynamic>);
            _availableDecks.add(deck);
            debugPrint('Parsed deck: ${deck.name} with ${deck.cardCount} cards');
          } catch (e) {
            debugPrint('Error parsing deck: $e');
            debugPrint('Deck JSON: $deckJson');
          }
        }

        // Select the first deck by default
        if (_availableDecks.isNotEmpty && _selectedDeck == null) {
          _selectedDeck = _availableDecks.first;
          debugPrint('Selected default deck: ${_selectedDeck!.name}');
        }

        debugPrint('Successfully loaded ${_availableDecks.length} decks from backend');
      } else {
        _error = 'Server returned status code: ${response.statusCode}';
        debugPrint('$_error\nResponse body: ${response.body}');
        
        // Fallback to sample decks if backend is unavailable
        _loadSampleDecks();
      }
    } catch (e) {
      _error = 'Network error: $e';
      debugPrint(_error);
      
      // Fallback to sample decks if backend is unavailable
      _loadSampleDecks();
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

        // Categorize based on card type and ID patterns
        // Pawns have 'pawn' in their ID (e.g., 'red_pawn_goblin', 'purple_pawn_ghoul')
        if (card.id.toLowerCase().contains('pawn')) {
          pawnCards.add(deckCard);
        } else if (card.id.toLowerCase().contains('hero')) {
          // Hero cards are handled separately via heroCardId
          continue;
        } else {
          // All other cards are main deck cards
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
  
  /// Manually trigger loading of sample decks (for testing)
  void loadSampleDecksManually() {
    _loadSampleDecks();
    notifyListeners();
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

  /// Load sample decks as fallback when backend is unavailable
  void _loadSampleDecks() {
    debugPrint('Loading sample decks as fallback...');
    
    // Create sample cards for the decks
    final redGoblinPawn = GameCard(
      id: 'red_pawn_goblin',
      name: 'Goblin',
      description: 'Summons a Goblin unit.',
      goldCost: 1,
      manaCost: 0,
      type: CardType.unit,
      color: 'red',
      unitStats: const UnitStats(
        attack: 2,
        health: 2,
        armor: 0,
        speed: 1,
        range: 1,
      ),
      abilities: ['Melee'],
      flavorText: 'Scrappy fighters of the warband.',
    );

    final redOrcWarrior = GameCard(
      id: 'red_unit_orc_warrior',
      name: 'Orc Warrior',
      description: 'Summons an Orc Warrior unit.',
      goldCost: 2,
      manaCost: 1,
      type: CardType.unit,
      color: 'red',
      unitStats: const UnitStats(
        attack: 3,
        health: 2,
        armor: 0,
        speed: 1,
        range: 1,
      ),
      abilities: ['Melee'],
      flavorText: 'Strong warriors of the red army.',
    );

    final purpleGhoulPawn = GameCard(
      id: 'purple_pawn_ghoul',
      name: 'Ghoul',
      description: 'Summons a Ghoul unit.',
      goldCost: 1,
      manaCost: 0,
      type: CardType.unit,
      color: 'purple',
      unitStats: const UnitStats(
        attack: 1,
        health: 2,
        armor: 0,
        speed: 1,
        range: 1,
      ),
      abilities: ['Rekindle', 'Melee'],
      flavorText: 'Undead minions that refuse to stay down.',
    );

    final purpleDrainLife = GameCard(
      id: 'purple_spell_drain',
      name: 'Drain Life',
      description: 'Target unit takes 2 damage. Heal 2 health.',
      goldCost: 0,
      manaCost: 2,
      type: CardType.spell,
      color: 'purple',
      abilities: [],
      flavorText: 'Life force stolen from enemies.',
    );

    // Create the red deck
    final redDeck = Deck(
      id: 'red_deck_001',
      name: 'Goblin Warband',
      color: 'red',
      description: 'An aggressive red deck focused on overwhelming swarm tactics with goblin units.',
      heroCardId: 'red_hero_warchief',
      pawnCards: [
        DeckCard(card: redGoblinPawn, quantity: 10),
      ],
      mainCards: [
        DeckCard(card: redOrcWarrior, quantity: 20),
      ],
    );

    // Create the purple deck
    final purpleDeck = Deck(
      id: 'purple_deck_001',
      name: 'Undead Horde',
      color: 'purple',
      description: 'A purple deck that leverages necromancy and spell power to overwhelm enemies.',
      heroCardId: 'purple_hero_necromancer',
      pawnCards: [
        DeckCard(card: purpleGhoulPawn, quantity: 10),
      ],
      mainCards: [
        DeckCard(card: purpleDrainLife, quantity: 20),
      ],
    );

    _availableDecks.clear();
    _availableDecks.add(redDeck);
    _availableDecks.add(purpleDeck);

    // Select the first deck by default
    if (_selectedDeck == null && _availableDecks.isNotEmpty) {
      _selectedDeck = _availableDecks.first;
    }

    debugPrint('Loaded ${_availableDecks.length} sample decks');
  }
}
