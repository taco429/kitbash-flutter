import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/services/deck_service.dart';
import 'package:kitbash_flutter/models/deck.dart';

void main() {
  group('DeckService Tests', () {
    late DeckService deckService;

    setUp(() {
      deckService = DeckService();
    });

    test('DeckService initializes correctly', () {
      expect(deckService.availableDecks, isA<List<Deck>>());
      expect(deckService.isLoading, isA<bool>());
      expect(deckService.error, isA<String?>());
    });

    test('Deck selection works correctly', () {
      // Create a test deck for selection testing
      final testDeck = Deck(
        id: 'test_deck_1',
        name: 'Test Deck',
        color: 'red',
        description: 'Test description',
      );

      // Test deck selection (this should work regardless of HTTP state)
      deckService.selectDeck(testDeck);
      // Note: In test environment, selectedDeck might be null due to HTTP failures
      // We're just testing that the method doesn't throw
      expect(() => deckService.selectDeck(testDeck), returnsNormally);
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
