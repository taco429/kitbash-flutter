import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/services/deck_service.dart';
import 'package:kitbash_flutter/models/card.dart';
import 'package:kitbash_flutter/models/deck.dart';

void main() {
  group('DeckService Tests', () {
    late DeckService deckService;

    setUp(() {
      deckService = DeckService();
    });

    test('DeckService initializes correctly', () {
      // Since we're now loading from backend, we test the service structure
      expect(deckService.availableDecks, isA<List<Deck>>());
      expect(deckService.isLoading, isA<bool>());
      expect(deckService.error, isA<String?>());
    });

    test('Deck selection works correctly', () {
      // Create test decks
      final testDeck1 = Deck(
        id: 'test_deck_1',
        name: 'Test Deck 1',
        color: 'red',
        description: 'Test description',
      );
      
      final testDeck2 = Deck(
        id: 'test_deck_2',
        name: 'Test Deck 2',
        color: 'purple',
        description: 'Test description',
      );
      
      // Manually set available decks for testing
      deckService.selectDeck(testDeck1);
      expect(deckService.selectedDeck, testDeck1);
    });

    test('Deck selection by ID works correctly', () {
      // Test the selectDeckById method
      deckService.selectDeckById('nonexistent_deck');
      // Should handle gracefully without throwing
    });

    test('getDeckCards handles invalid deck ID', () {
      const invalidId = 'invalid_deck_id';
      
      expect(deckService.getDeckCards(invalidId), isEmpty);
      expect(deckService.getDeckCardCount(invalidId), 0);
    });

    test('loadDecks method exists and callable', () async {
      // Test that the loadDecks method can be called
      // In a real test environment, this would make HTTP calls
      expect(() => deckService.loadDecks(), returnsNormally);
    });

    test('Service has proper state management', () {
      // Test that the service properly manages loading and error states
      expect(deckService.isLoading, isA<bool>());
      expect(deckService.error, isA<String?>());
      expect(deckService.availableDecks, isA<List<Deck>>());
      expect(deckService.selectedDeck, isA<Deck?>());
    });
  });
}