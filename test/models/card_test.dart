import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/models/card.dart';
import 'package:kitbash_flutter/models/cards/creatures.dart';

void main() {
  group('Card Model Tests', () {
    test('Skeleton card has correct properties', () {
      const skeleton = CreatureCards.skeleton;
      
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

    test('Goblin card has correct properties', () {
      const goblin = CreatureCards.goblin;
      
      expect(goblin.id, 'goblin_001');
      expect(goblin.name, 'Goblin Raider');
      expect(goblin.cost, 1);
      expect(goblin.type, CardType.creature);
      expect(goblin.color, CardColor.red);
      expect(goblin.attack, 2);
      expect(goblin.health, 1);
      expect(goblin.abilities, contains('Haste'));
      expect(goblin.isCreature, true);
      expect(goblin.isSpell, false);
    });

    test('Card power level calculation works correctly', () {
      const skeleton = CreatureCards.skeleton;
      const goblin = CreatureCards.goblin;
      
      expect(skeleton.powerLevel, 3); // 2 attack + 1 health
      expect(goblin.powerLevel, 3); // 2 attack + 1 health
    });

    test('Card JSON serialization works', () {
      const skeleton = CreatureCards.skeleton;
      final json = skeleton.toJson();
      final reconstructed = GameCard.fromJson(json);
      
      expect(reconstructed.id, skeleton.id);
      expect(reconstructed.name, skeleton.name);
      expect(reconstructed.cost, skeleton.cost);
      expect(reconstructed.type, skeleton.type);
      expect(reconstructed.color, skeleton.color);
      expect(reconstructed.attack, skeleton.attack);
      expect(reconstructed.health, skeleton.health);
    });

    test('DeckCard creation works correctly', () {
      const skeleton = CreatureCards.skeleton;
      const deckCard = DeckCard(card: skeleton, quantity: 4);
      
      expect(deckCard.card, skeleton);
      expect(deckCard.quantity, 4);
    });

    test('CreatureCards collections work correctly', () {
      expect(CreatureCards.allCreatures.length, 4);
      expect(CreatureCards.purpleCreatures.length, 2);
      expect(CreatureCards.redCreatures.length, 2);
      
      // Check that all purple creatures are actually purple
      for (final card in CreatureCards.purpleCreatures) {
        expect(card.color, CardColor.purple);
      }
      
      // Check that all red creatures are actually red
      for (final card in CreatureCards.redCreatures) {
        expect(card.color, CardColor.red);
      }
    });
  });
}