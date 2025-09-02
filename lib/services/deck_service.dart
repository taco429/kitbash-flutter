import 'package:flutter/foundation.dart';
import '../models/deck.dart';

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
      Deck(
        id: 'red_deck_001',
        name: 'Crimson Fury',
        color: 'red',
        description:
            'An aggressive deck focused on quick strikes and overwhelming force.',
        cardCount: 30,
      ),
      Deck(
        id: 'purple_deck_001',
        name: 'Mystic Shadows',
        color: 'purple',
        description:
            'A strategic deck utilizing mystical powers and cunning tactics.',
        cardCount: 30,
      ),
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
}
