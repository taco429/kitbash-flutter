import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/widgets/game_with_tooltip.dart';
import 'package:kitbash_flutter/game/kitbash_game.dart';
import 'package:kitbash_flutter/services/game_service.dart';
import 'package:kitbash_flutter/models/tile_data.dart';

void main() {
  group('GameWithTooltip Tests', () {
    late KitbashGame game;
    late GameService gameService;

    setUp(() {
      gameService = GameService();
      game = KitbashGame(gameId: 'test-game', gameService: gameService);
    });

    testWidgets('should render game and tooltip overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      // Should find the Stack container
      expect(find.byType(Stack), findsOneWidget);
      
      // Should find the GameWidget (though it may not render fully in tests)
      expect(find.byType(GameWithTooltip), findsOneWidget);
    });

    testWidgets('should initially have no tooltip visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tooltip should exist but not be visible
      expect(find.byType(GameTooltip), findsOneWidget);
      
      // No tooltip content should be visible initially
      expect(find.text('Grass'), findsNothing);
      expect(find.text('Tile ('), findsNothing);
    });

    testWidgets('should handle hover callback and show tooltip after delay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate hover callback through the game's callback mechanism
      const testTileData = TileData(
        row: 2,
        col: 3,
        terrain: TerrainType.forest,
      );
      const testPosition = Offset(150, 200);

      // Trigger the hover callback that was set on the game
      game.onTileHover?.call(testTileData, testPosition);
      
      // Should update hover state immediately
      await tester.pump();
      
      // Tooltip should not be visible yet (waiting for delay)
      expect(find.text('Forest'), findsNothing);

      // Wait for tooltip delay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Now tooltip should be visible
      expect(find.text('Forest'), findsOneWidget);
      expect(find.text('Tile (2, 3)'), findsOneWidget);
    });

    testWidgets('should hide tooltip when hover ends', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start hover
      const testTileData = TileData(
        row: 1,
        col: 1,
        terrain: TerrainType.grass,
      );
      game.onTileHover?.call(testTileData, const Offset(100, 100));
      
      // Wait for tooltip to appear
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      
      expect(find.text('Grass'), findsOneWidget);

      // End hover
      game.onTileHover?.call(null, null);
      await tester.pump();

      // Tooltip should be hidden immediately
      expect(find.text('Grass'), findsNothing);
    });

    testWidgets('should cancel tooltip timer when hover changes quickly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start hover on first tile
      const tileData1 = TileData(
        row: 1,
        col: 1,
        terrain: TerrainType.grass,
      );
      game.onTileHover?.call(tileData1, const Offset(100, 100));
      
      // Quickly move to second tile before delay
      await tester.pump(const Duration(milliseconds: 200));
      
      const tileData2 = TileData(
        row: 2,
        col: 2,
        terrain: TerrainType.stone,
      );
      game.onTileHover?.call(tileData2, const Offset(150, 150));

      // Wait for tooltip delay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should show second tile, not first
      expect(find.text('Stone'), findsOneWidget);
      expect(find.text('Grass'), findsNothing);
      expect(find.text('Tile (2, 2)'), findsOneWidget);
    });

    testWidgets('should dispose timer when widget is disposed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Start a hover to create a timer
      const testTileData = TileData(
        row: 1,
        col: 1,
        terrain: TerrainType.grass,
      );
      game.onTileHover?.call(testTileData, const Offset(100, 100));
      
      await tester.pump();

      // Dispose the widget
      await tester.pumpWidget(const SizedBox.shrink());
      
      // Should not crash - timer should be properly disposed
      await tester.pumpAndSettle();
    });

    testWidgets('should maintain tooltip position correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test different positions
      const positions = [
        Offset(50, 50),
        Offset(200, 300),
        Offset(400, 100),
      ];

      for (final position in positions) {
        const testTileData = TileData(
          row: 0,
          col: 0,
          terrain: TerrainType.water,
        );
        
        game.onTileHover?.call(testTileData, position);
        
        // Wait for tooltip to appear
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        // Check that tooltip is positioned correctly
        final positionedFinder = find.byType(Positioned);
        expect(positionedFinder, findsOneWidget);

        final positionedWidget = tester.widget<Positioned>(positionedFinder);
        expect(positionedWidget.left, equals(position.dx + 10));
        expect(positionedWidget.top, equals(position.dy - 60));

        // Clear hover for next iteration
        game.onTileHover?.call(null, null);
        await tester.pump();
      }
    });

    testWidgets('should handle game hover callback setup', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the game has a hover callback set
      expect(game.onTileHover, isNotNull);
    });
  });

  group('GameWithTooltip Integration Tests', () {
    testWidgets('should work with different tile data types', (WidgetTester tester) async {
      final gameService = GameService();
      final game = KitbashGame(gameId: 'test-game', gameService: gameService);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameWithTooltip(game: game),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test with unit
      const tileWithUnit = TileData(
        row: 1,
        col: 1,
        terrain: TerrainType.grass,
        unit: Unit(
          name: 'Test Warrior',
          playerIndex: 0,
          health: 85,
          maxHealth: 100,
          type: UnitType.infantry,
        ),
      );

      game.onTileHover?.call(tileWithUnit, const Offset(100, 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Test Warrior'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);

      // Clear and test with building
      game.onTileHover?.call(null, null);
      await tester.pump();

      const tileWithBuilding = TileData(
        row: 2,
        col: 2,
        terrain: TerrainType.stone,
        building: Building(
          name: 'Fortress',
          playerIndex: 1,
          health: 300,
          maxHealth: 400,
          type: BuildingType.tower,
        ),
      );

      game.onTileHover?.call(tileWithBuilding, const Offset(200, 200));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Fortress'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
      expect(find.text('300/400'), findsOneWidget);
    });
  });
}