import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/models/card.dart';

void main() {
  group('Card Model Tests', () {
    test('Card creation works correctly', () {
      const skeleton = GameCard(
        id: 'skeleton_001',
        name: 'Skeleton Warrior',
        cost: 2,
        type: CardType.creature,
        color: CardColor.purple,
        attack: 2,
        health: 1,
        abilities: ['Undead'],
        flavorText: 'Death is but the beginning of service.',
      );
      
      expect(skeleton.id, 'skeleton_001');
      expect(skeleton.name, 'Skeleton Warrior');
      expect(skeleton.cost, 2);
      expect(skeleton.type, CardType.creature);
      expect(skeleton.color, CardColor.purple);
      expect(skeleton.attack, 2);
      expect(skeleton.health, 1);
      expect(skeleton.abilities, contains('Undead'));
      expect(skeleton.isCreature, true);
      expect(skeleton.isSpell, false);
    });

    test('Card power level calculation works correctly', () {
      const creature = GameCard(
        id: 'test_001',
        name: 'Test Creature',
        cost: 2,
        type: CardType.creature,
        color: CardColor.red,
        attack: 2,
        health: 1,
      );
      
      const spell = GameCard(
        id: 'test_002',
        name: 'Test Spell',
        cost: 3,
        type: CardType.spell,
        color: CardColor.blue,
      );
      
      expect(creature.powerLevel, 3); // 2 attack + 1 health
      expect(spell.powerLevel, 3); // cost for non-creatures
    });

    test('Card JSON serialization works', () {
      const testCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        cost: 2,
        type: CardType.creature,
        color: CardColor.purple,
        attack: 2,
        health: 1,
        abilities: ['Test Ability'],
        flavorText: 'Test flavor text',
      );
      
      final json = testCard.toJson();
      final reconstructed = GameCard.fromJson(json);
      
      expect(reconstructed.id, testCard.id);
      expect(reconstructed.name, testCard.name);
      expect(reconstructed.cost, testCard.cost);
      expect(reconstructed.type, testCard.type);
      expect(reconstructed.color, testCard.color);
      expect(reconstructed.attack, testCard.attack);
      expect(reconstructed.health, testCard.health);
      expect(reconstructed.abilities, testCard.abilities);
      expect(reconstructed.flavorText, testCard.flavorText);
    });

    test('DeckCard creation works correctly', () {
      const testCard = GameCard(
        id: 'test_001',
        name: 'Test Card',
        cost: 1,
        type: CardType.creature,
        color: CardColor.red,
      );
      
      const deckCard = DeckCard(card: testCard, quantity: 4);
      
      expect(deckCard.card, testCard);
      expect(deckCard.quantity, 4);
    });

    test('Card type and color enums work correctly', () {
      expect(CardType.creature.displayName, 'Creature');
      expect(CardType.spell.displayName, 'Spell');
      expect(CardType.artifact.displayName, 'Artifact');
      
      expect(CardColor.red.displayName, 'Red');
      expect(CardColor.purple.displayName, 'Purple');
      expect(CardColor.neutral.displayName, 'Neutral');
    });

    test('JSON parsing handles invalid values gracefully', () {
      final json = {
        'id': 'test_001',
        'name': 'Test Card',
        'cost': 1,
        'type': 'invalid_type',
        'color': 'invalid_color',
      };
      
      final card = GameCard.fromJson(json);
      
      expect(card.type, CardType.creature); // Should default to creature
      expect(card.color, CardColor.neutral); // Should default to neutral
    });
  });
}