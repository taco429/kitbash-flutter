import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/models/card.dart';

void main() {
  group('Card Model Tests', () {
    test('Card creation works correctly', () {
      const goblin = GameCard(
        id: 'red_pawn_goblin',
        name: 'Goblin',
        description: 'Summons a Goblin unit.',
        goldCost: 1,
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
        abilities: ['Melee'],
        flavorText: 'Scrappy fighters of the warband.',
      );
      
      expect(goblin.id, 'red_pawn_goblin');
      expect(goblin.name, 'Goblin');
      expect(goblin.goldCost, 1);
      expect(goblin.manaCost, 0);
      expect(goblin.type, CardType.unit);
      expect(goblin.color, CardColor.red);
      expect(goblin.unitStats?.attack, 2);
      expect(goblin.unitStats?.health, 2);
      expect(goblin.abilities, contains('Melee'));
      expect(goblin.isUnit, true);
      expect(goblin.isSpell, false);
    });

    test('Card power level calculation works correctly', () {
      const unitCard = GameCard(
        id: 'test_001',
        name: 'Test Unit',
        description: 'Test unit card',
        goldCost: 1,
        manaCost: 1,
        type: CardType.unit,
        color: CardColor.red,
        unitStats: UnitStats(
          attack: 2,
          health: 1,
          armor: 0,
          speed: 1,
          range: 1,
        ),
      );
      
      const spell = GameCard(
        id: 'test_002',
        name: 'Test Spell',
        description: 'Test spell card',
        goldCost: 0,
        manaCost: 3,
        type: CardType.spell,
        color: CardColor.blue,
      );
      
      expect(unitCard.powerLevel, 3); // 2 attack + 1 health
      expect(spell.powerLevel, 3); // totalCost for spells
    });

    test('Card JSON serialization works', () {
      const testCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        description: 'Test description',
        goldCost: 1,
        manaCost: 1,
        type: CardType.unit,
        color: CardColor.purple,
        unitStats: UnitStats(
          attack: 2,
          health: 1,
          armor: 0,
          speed: 1,
          range: 1,
        ),
        abilities: ['Test Ability'],
        flavorText: 'Test flavor text',
      );
      
      final json = testCard.toJson();
      final reconstructed = GameCard.fromJson(json);
      
      expect(reconstructed.id, testCard.id);
      expect(reconstructed.name, testCard.name);
      expect(reconstructed.goldCost, testCard.goldCost);
      expect(reconstructed.manaCost, testCard.manaCost);
      expect(reconstructed.type, testCard.type);
      expect(reconstructed.color, testCard.color);
      expect(reconstructed.unitStats?.attack, testCard.unitStats?.attack);
      expect(reconstructed.unitStats?.health, testCard.unitStats?.health);
      expect(reconstructed.abilities, testCard.abilities);
      expect(reconstructed.flavorText, testCard.flavorText);
    });

    test('DeckCard creation works correctly', () {
      const testCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        description: 'Test description',
        goldCost: 1,
        manaCost: 0,
        type: CardType.unit,
        color: CardColor.red,
      );
      
      const deckCard = DeckCard(card: testCard, quantity: 4);
      
      expect(deckCard.card, testCard);
      expect(deckCard.quantity, 4);
    });

    test('Card type and color enums work correctly', () {
      expect(CardType.unit.displayName, 'Unit');
      expect(CardType.spell.displayName, 'Spell');
      expect(CardType.building.displayName, 'Building');
      expect(CardType.order.displayName, 'Order');
      expect(CardType.hero.displayName, 'Hero');
      
      expect(CardColor.red.displayName, 'Red');
      expect(CardColor.orange.displayName, 'Orange');
      expect(CardColor.yellow.displayName, 'Yellow');
      expect(CardColor.green.displayName, 'Green');
      expect(CardColor.blue.displayName, 'Blue');
      expect(CardColor.purple.displayName, 'Purple');
    });

    test('JSON parsing handles invalid values gracefully', () {
      final json = {
        'id': 'test_001',
        'name': 'Test Card',
        'description': 'Test description',
        'goldCost': 1,
        'manaCost': 0,
        'type': 'invalid_type',
        'color': 'invalid_color',
      };
      
      final card = GameCard.fromJson(json);
      
      expect(card.type, CardType.unit); // Should default to unit
      expect(card.color, CardColor.red); // Should default to red
    });
  });
}