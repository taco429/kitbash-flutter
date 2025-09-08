import 'package:flutter_test/flutter_test.dart';
import '../lib/models/card_instance.dart';

void main() {
  group('CardInstance Tests', () {
    test('should create unique instance IDs for same card type', () {
      // Create multiple instances of the same card
      final instance1 = CardInstance(
        instanceId: 'instance-1',
        cardId: 'lightning-bolt',
      );
      final instance2 = CardInstance(
        instanceId: 'instance-2',
        cardId: 'lightning-bolt',
      );
      final instance3 = CardInstance(
        instanceId: 'instance-3',
        cardId: 'lightning-bolt',
      );

      // All instances should have the same card ID
      expect(instance1.cardId, equals('lightning-bolt'));
      expect(instance2.cardId, equals('lightning-bolt'));
      expect(instance3.cardId, equals('lightning-bolt'));

      // But different instance IDs
      expect(instance1.instanceId, isNot(equals(instance2.instanceId)));
      expect(instance2.instanceId, isNot(equals(instance3.instanceId)));
      expect(instance1.instanceId, isNot(equals(instance3.instanceId)));
    });

    test('should compare instances by instanceId not cardId', () {
      final instance1 = CardInstance(
        instanceId: 'instance-1',
        cardId: 'lightning-bolt',
      );
      final instance2 = CardInstance(
        instanceId: 'instance-2',
        cardId: 'lightning-bolt',
      );
      final instance1Copy = CardInstance(
        instanceId: 'instance-1',
        cardId: 'lightning-bolt',
      );

      // Different instances of same card should not be equal
      expect(instance1, isNot(equals(instance2)));

      // Same instance ID should be equal
      expect(instance1, equals(instance1Copy));
    });

    test('should serialize and deserialize correctly', () {
      final instance = CardInstance(
        instanceId: 'test-instance-123',
        cardId: 'fireball',
      );

      final json = instance.toJson();
      expect(json['instanceId'], equals('test-instance-123'));
      expect(json['cardId'], equals('fireball'));

      final deserialized = CardInstance.fromJson(json);
      expect(deserialized.instanceId, equals(instance.instanceId));
      expect(deserialized.cardId, equals(instance.cardId));
    });

    test('should handle a hand with duplicate cards', () {
      // Simulate a hand with 3 Lightning Bolts and 2 Fireballs
      final hand = [
        CardInstance(instanceId: 'inst-1', cardId: 'lightning-bolt'),
        CardInstance(instanceId: 'inst-2', cardId: 'fireball'),
        CardInstance(instanceId: 'inst-3', cardId: 'lightning-bolt'),
        CardInstance(instanceId: 'inst-4', cardId: 'fireball'),
        CardInstance(instanceId: 'inst-5', cardId: 'lightning-bolt'),
      ];

      // Count cards by type
      final cardCounts = <String, int>{};
      for (final instance in hand) {
        cardCounts[instance.cardId] = (cardCounts[instance.cardId] ?? 0) + 1;
      }

      expect(cardCounts['lightning-bolt'], equals(3));
      expect(cardCounts['fireball'], equals(2));

      // Each instance should be unique
      final instanceIds = hand.map((e) => e.instanceId).toSet();
      expect(instanceIds.length, equals(5));
    });

    test('should allow selecting specific duplicates for discard', () {
      final hand = [
        CardInstance(instanceId: 'inst-1', cardId: 'lightning-bolt'),
        CardInstance(instanceId: 'inst-2', cardId: 'lightning-bolt'),
        CardInstance(instanceId: 'inst-3', cardId: 'lightning-bolt'),
      ];

      // Select only the second Lightning Bolt for discard
      final selectedForDiscard = <String>{'inst-2'};

      // Check which cards are selected
      final discardedCards = hand
          .where((card) => selectedForDiscard.contains(card.instanceId))
          .toList();

      expect(discardedCards.length, equals(1));
      expect(discardedCards.first.instanceId, equals('inst-2'));

      // The other Lightning Bolts should not be selected
      final remainingCards = hand
          .where((card) => !selectedForDiscard.contains(card.instanceId))
          .toList();

      expect(remainingCards.length, equals(2));
      expect(remainingCards.any((c) => c.instanceId == 'inst-1'), isTrue);
      expect(remainingCards.any((c) => c.instanceId == 'inst-3'), isTrue);
    });
  });
}