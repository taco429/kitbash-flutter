import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/services/deck_service.dart';
import 'package:kitbash_flutter/models/card.dart';

void main() {
  group('DeckService Tests', () {
    late DeckService deckService;

    setUp(() {
      deckService = DeckService();
    });

    test('DeckService initializes with two decks', () {
      expect(deckService.availableDecks.length, 2);
      
      final redDeck = deckService.availableDecks
          .where((deck) => deck.color == 'red')
          .first;
      final purpleDeck = deckService.availableDecks
          .where((deck) => deck.color == 'purple')
          .first;
      
      expect(redDeck.name, 'Goblin Swarm');
      expect(purpleDeck.name, 'Undead Legion');
    });

    test('Red deck has correct composition', () {
      final redDeck = deckService.availableDecks
          .where((deck) => deck.color == 'red')
          .first;
      
      expect(redDeck.cardCount, 30);
      expect(redDeck.cards.isNotEmpty, true);
      
      // Check that all cards in the red deck are red
      for (final deckCard in redDeck.cards) {
        expect(deckCard.card.color, CardColor.red);
      }
    });

    test('Purple deck has correct composition', () {
      final purpleDeck = deckService.availableDecks
          .where((deck) => deck.color == 'purple')
          .first;
      
      expect(purpleDeck.cardCount, 30);
      expect(purpleDeck.cards.isNotEmpty, true);
      
      // Check that all cards in the purple deck are purple
      for (final deckCard in purpleDeck.cards) {
        expect(deckCard.card.color, CardColor.purple);
      }
    });

    test('Deck selection works correctly', () {
      final firstDeck = deckService.availableDecks.first;
      expect(deckService.selectedDeck, firstDeck);
      
      final secondDeck = deckService.availableDecks.last;
      deckService.selectDeck(secondDeck);
      expect(deckService.selectedDeck, secondDeck);
    });

    test('Deck selection by ID works correctly', () {
      const redDeckId = 'red_deck_001';
      const purpleDeckId = 'purple_deck_001';
      
      deckService.selectDeckById(redDeckId);
      expect(deckService.selectedDeck?.id, redDeckId);
      
      deckService.selectDeckById(purpleDeckId);
      expect(deckService.selectedDeck?.id, purpleDeckId);
    });

    test('getDeckCards returns correct cards', () {
      const redDeckId = 'red_deck_001';
      final cards = deckService.getDeckCards(redDeckId);
      
      expect(cards.isNotEmpty, true);
      
      final totalCards = cards.fold(0, (sum, deckCard) => sum + deckCard.quantity);
      expect(totalCards, 30);
    });

    test('getDeckCardCount returns correct count', () {
      const redDeckId = 'red_deck_001';
      const purpleDeckId = 'purple_deck_001';
      
      expect(deckService.getDeckCardCount(redDeckId), 30);
      expect(deckService.getDeckCardCount(purpleDeckId), 30);
    });

    test('Invalid deck ID returns empty results', () {
      const invalidId = 'invalid_deck_id';
      
      expect(deckService.getDeckCards(invalidId), isEmpty);
      expect(deckService.getDeckCardCount(invalidId), 0);
    });
  });
}