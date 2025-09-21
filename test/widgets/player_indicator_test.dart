import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:kitbash_cards/widgets/player_indicator.dart';
import 'package:kitbash_cards/services/game_service.dart';
import 'package:kitbash_cards/services/deck_service.dart';
import 'package:kitbash_cards/services/card_service.dart';
import 'package:kitbash_cards/models/resources.dart';

void main() {
  group('PlayerIndicator', () {
    late CardService cardService;
    late DeckService deckService;
    late GameService gameService;

    setUp(() {
      cardService = CardService();
      deckService = DeckService(cardService);
      gameService = GameService();
    });

    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cardService),
          ChangeNotifierProvider.value(value: deckService),
          ChangeNotifierProvider.value(value: gameService),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('displays correctly for current player', (tester) async {
      final playerState = PlayerBattleState(
        playerIndex: 0,
        deckId: 'test-deck',
        hand: const [],
        deckCount: 20,
        resources: const Resources(gold: 5, mana: 3),
        resourceIncome: const ResourceGeneration(gold: 2, mana: 1),
      );

      await tester.pumpWidget(createTestWidget(
        PlayerIndicator(
          playerState: playerState,
          playerName: 'Test Player',
          accentColor: Colors.green,
          isCurrentPlayer: true,
          showResources: true,
        ),
      ));

      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('Deck'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('displays correctly for opponent', (tester) async {
      final opponentState = PlayerBattleState(
        playerIndex: 1,
        deckId: 'opponent-deck',
        hand: const [],
        deckCount: 15,
        resources: const Resources(gold: 3, mana: 2),
        resourceIncome: const ResourceGeneration(gold: 1, mana: 1),
      );

      await tester.pumpWidget(createTestWidget(
        PlayerIndicator(
          playerState: opponentState,
          playerName: 'Opponent',
          accentColor: Colors.pink,
          isCurrentPlayer: false,
          showResources: true,
          compact: true,
        ),
      ));

      expect(find.text('Opponent'), findsOneWidget);
      expect(find.text('Deck'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('can hide resources when showResources is false', (tester) async {
      final playerState = PlayerBattleState(
        playerIndex: 0,
        deckId: 'test-deck',
        hand: const [],
        deckCount: 20,
        resources: const Resources(gold: 5, mana: 3),
        resourceIncome: const ResourceGeneration(gold: 2, mana: 1),
      );

      await tester.pumpWidget(createTestWidget(
        PlayerIndicator(
          playerState: playerState,
          playerName: 'Test Player',
          accentColor: Colors.green,
          isCurrentPlayer: true,
          showResources: false,
        ),
      ));

      // ResourceDisplay should not be present
      expect(find.byType(PlayerIndicator), findsOneWidget);
      // The widget should still show hero, deck, and discard
      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('Deck'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('respects maxWidth constraint', (tester) async {
      final playerState = PlayerBattleState(
        playerIndex: 0,
        deckId: 'test-deck',
        hand: const [],
        deckCount: 20,
        resources: const Resources(gold: 5, mana: 3),
        resourceIncome: const ResourceGeneration(gold: 2, mana: 1),
      );

      await tester.pumpWidget(createTestWidget(
        PlayerIndicator(
          playerState: playerState,
          playerName: 'Test Player',
          accentColor: Colors.green,
          isCurrentPlayer: true,
          showResources: true,
          maxWidth: 300,
        ),
      ));

      // Find the ConstrainedBox and verify its constraints
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byType(ConstrainedBox).first,
      );
      expect(constrainedBox.constraints.maxWidth, 300);
    });

    testWidgets('works with null playerState', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const PlayerIndicator(
          playerState: null,
          playerName: 'Test Player',
          accentColor: Colors.green,
          isCurrentPlayer: true,
        ),
      ));

      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('Deck'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });
  });
}