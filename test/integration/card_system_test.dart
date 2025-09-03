import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/models/card.dart';
import 'package:kitbash_flutter/models/deck.dart';

void main() {
  group('Card System Integration Tests', () {
    test('Card and Deck models work together', () {
      // Create test cards
      const testCard1 = GameCard(
        id: 'test_001',
        name: 'Test Creature 1',
        cost: 1,
        type: CardType.creature,
        color: CardColor.red,
        attack: 1,
        health: 1,
      );
      
      const testCard2 = GameCard(
        id: 'test_002',
        name: 'Test Creature 2',
        cost: 2,
        type: CardType.creature,
        color: CardColor.red,
        attack: 2,
        health: 2,
      );
      
      // Create deck cards
      const deckCard1 = DeckCard(card: testCard1, quantity: 4);
      const deckCard2 = DeckCard(card: testCard2, quantity: 2);
      
      // Create deck
      final testDeck = Deck(
        id: 'test_deck_001',
        name: 'Test Deck',
        color: 'red',
        description: 'A test deck for validation',
        cards: [deckCard1, deckCard2],
      );
      
      // Verify deck properties
      expect(testDeck.cardCount, 6); // 4 + 2
      expect(testDeck.cards.length, 2);
      expect(testDeck.cards.first.card.name, 'Test Creature 1');
      expect(testDeck.cards.last.card.name, 'Test Creature 2');
    });

    test('Card JSON round-trip preserves data', () {
      const originalCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        description: 'Test description',
        cost: 3,
        type: CardType.spell,
        color: CardColor.blue,
        abilities: ['Test', 'Ability'],
        flavorText: 'Test flavor',
      );
      
      final json = originalCard.toJson();
      final reconstructedCard = GameCard.fromJson(json);
      
      expect(reconstructedCard.id, originalCard.id);
      expect(reconstructedCard.name, originalCard.name);
      expect(reconstructedCard.description, originalCard.description);
      expect(reconstructedCard.cost, originalCard.cost);
      expect(reconstructedCard.type, originalCard.type);
      expect(reconstructedCard.color, originalCard.color);
      expect(reconstructedCard.abilities, originalCard.abilities);
      expect(reconstructedCard.flavorText, originalCard.flavorText);
    });

    test('Deck JSON serialization works', () {
      const testCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        cost: 1,
        type: CardType.creature,
        color: CardColor.red,
      );
      
      final testDeck = Deck(
        id: 'test_deck_001',
        name: 'Test Deck',
        color: 'red',
        description: 'Test deck',
        cards: [DeckCard(card: testCard, quantity: 3)],
      );
      
      final json = testDeck.toJson();
      
      expect(json['id'], 'test_deck_001');
      expect(json['name'], 'Test Deck');
      expect(json['color'], 'red');
      expect(json['cards'], isA<List>());
      expect((json['cards'] as List).length, 1);
    });
  });
}