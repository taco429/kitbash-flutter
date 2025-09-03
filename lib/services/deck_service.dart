import 'package:flutter/foundation.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/cards/creatures.dart';

class DeckService extends ChangeNotifier {
  List<Deck> _availableDecks = [];
  Deck? _selectedDeck;

  List<Deck> get availableDecks => List.unmodifiable(_availableDecks);
  Deck? get selectedDeck => _selectedDeck;

  DeckService() {
    _initializeTestDecks();
  }

  void _initializeTestDecks() {
    _availableDecks = [
      _createRedGoblinDeck(),
      _createPurpleSkeletonDeck(),
    ];

    // Select the first deck by default
    if (_availableDecks.isNotEmpty) {
      _selectedDeck = _availableDecks.first;
    }
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

  // Future method for when we add deck loading from backend
  Future<void> loadDecks() async {
    // TODO: Implement loading decks from backend
    // For now, just notify listeners that decks are ready
    notifyListeners();
  }

  // Future method for when we add deck saving to backend
  Future<void> saveDeckSelection() async {
    // TODO: Implement saving deck selection to backend
    debugPrint('Selected deck: ${_selectedDeck?.name}');
  }

  /// Create a red deck focused on goblins
  Deck _createRedGoblinDeck() {
    final cards = <DeckCard>[
      // Main goblin creatures - 23 basic goblins, 7 chieftains = 30 total
      DeckCard(card: CreatureCards.goblin, quantity: 23),
      DeckCard(card: CreatureCards.goblinChieftain, quantity: 7),
    ];

    return Deck(
      id: 'red_deck_001',
      name: 'Goblin Swarm',
      color: 'red',
      description: 'An aggressive deck full of fierce goblins ready for battle. Quick strikes and overwhelming numbers.',
      cards: cards,
    );
  }

  /// Create a purple deck focused on skeletons
  Deck _createPurpleSkeletonDeck() {
    final cards = <DeckCard>[
      // Main skeleton creatures - 15 basic skeletons, 15 archers = 30 total
      DeckCard(card: CreatureCards.skeleton, quantity: 15),
      DeckCard(card: CreatureCards.skeletonArcher, quantity: 15),
    ];

    return Deck(
      id: 'purple_deck_001',
      name: 'Undead Legion',
      color: 'purple',
      description: 'A strategic deck of undead warriors that never truly die. Balanced mix of melee and ranged units.',
      cards: cards,
    );
  }

  /// Get all cards in a specific deck
  List<DeckCard> getDeckCards(String deckId) {
    try {
      final deck = _availableDecks.firstWhere((d) => d.id == deckId);
      return deck.cards;
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
