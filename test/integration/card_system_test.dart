import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/models/card.dart';
import 'package:kitbash_flutter/models/deck.dart';

void main() {
  group('Card System Integration Tests', () {
    test('Card and Deck models work together', () {
      // Create test cards
      const testCard1 = GameCard(
        id: 'test_001',
        name: 'Test Unit 1',
        description: 'Test unit card 1',
        goldCost: 1,
        manaCost: 0,
        type: CardType.unit,
        color: CardColor.red,
        unitStats: UnitStats(
          attack: 1,
          health: 1,
          armor: 0,
          speed: 1,
          range: 1,
        ),
      );

      const testCard2 = GameCard(
        id: 'test_002',
        name: 'Test Unit 2',
        description: 'Test unit card 2',
        goldCost: 2,
        manaCost: 0,
        type: CardType.unit,
        color: CardColor.red,
        unitStats: UnitStats(
          attack: 2,
          health: 2,
          armor: 0,
          speed: 1,
          range: 1,
        ),
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
        heroCardId: 'test_hero_001',
        pawnCards: [deckCard1],
        mainCards: [deckCard2],
      );

      // Verify deck properties
      expect(testDeck.cardCount, 7); // 1 hero + 4 pawns + 2 main = 7
      expect(testDeck.allCards.length, 2);
      expect(testDeck.allCards.first.card.name, 'Test Unit 1');
      expect(testDeck.allCards.last.card.name, 'Test Unit 2');
    });

    test('Card JSON round-trip preserves data', () {
      const originalCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        description: 'Test description',
        goldCost: 0,
        manaCost: 3,
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
      expect(reconstructedCard.goldCost, originalCard.goldCost);
      expect(reconstructedCard.manaCost, originalCard.manaCost);
      expect(reconstructedCard.type, originalCard.type);
      expect(reconstructedCard.color, originalCard.color);
      expect(reconstructedCard.abilities, originalCard.abilities);
      expect(reconstructedCard.flavorText, originalCard.flavorText);
    });

    test('Deck JSON serialization works', () {
      const testCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        description: 'Test description',
        goldCost: 1,
        manaCost: 0,
        type: CardType.unit,
        color: CardColor.red,
      );

      final testDeck = Deck(
        id: 'test_deck_001',
        name: 'Test Deck',
        color: 'red',
        description: 'Test deck',
        heroCardId: 'test_hero_001',
        pawnCards: [const DeckCard(card: testCard, quantity: 3)],
        mainCards: [],
      );

      final json = testDeck.toJson();

      expect(json['id'], 'test_deck_001');
      expect(json['name'], 'Test Deck');
      expect(json['color'], 'red');
      expect(json['heroCardId'], 'test_hero_001');
      expect(json['pawnCards'], isA<List>());
      expect((json['pawnCards'] as List).length, 1);
    });
  });
}
