import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitbash_flutter/widgets/game_tooltip.dart';
import 'package:kitbash_flutter/models/tile_data.dart';

void main() {
  group('GameTooltip Tests', () {
    testWidgets('should not display when isVisible is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameTooltip(
              isVisible: false,
              tileData: TileData(
                row: 1,
                col: 1,
                terrain: TerrainType.grass,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GameTooltip), findsOneWidget);
      expect(find.text('Tile (1, 1)'), findsNothing);
      expect(find.text('Grass'), findsNothing);
    });

    testWidgets('should not display when tileData is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameTooltip(
              isVisible: true,
              tileData: null,
            ),
          ),
        ),
      );

      expect(find.byType(GameTooltip), findsOneWidget);
      expect(find.text('Grass'), findsNothing);
    });

    // Positioning is no longer cursor-relative; tooltip is anchored.

    testWidgets('should display basic tile information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: true,
                  tileData: TileData(
                    row: 2,
                    col: 3,
                    terrain: TerrainType.forest,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(); // Start animation
      await tester
          .pump(const Duration(milliseconds: 200)); // Complete animation

      expect(find.text('Tile (2, 3)'), findsOneWidget);
      expect(find.text('Forest'), findsOneWidget);
      expect(find.byIcon(Icons.park), findsOneWidget);
    });

    testWidgets('should display different terrain types correctly',
        (WidgetTester tester) async {
      const terrainTypes = [
        (TerrainType.grass, 'Grass', Icons.grass),
        (TerrainType.stone, 'Stone', Icons.terrain),
        (TerrainType.water, 'Water', Icons.water),
        (TerrainType.desert, 'Desert', Icons.wb_sunny),
        (TerrainType.mountain, 'Mountain', Icons.landscape),
      ];

      for (final (terrain, name, icon) in terrainTypes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  GameTooltip(
                    isVisible: true,
                    tileData: TileData(
                      row: 0,
                      col: 0,
                      terrain: terrain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump(); // Start animation
        await tester
            .pump(const Duration(milliseconds: 200)); // Complete animation

        expect(find.text(name), findsOneWidget,
            reason: 'Failed to find terrain name: $name');
        expect(find.byIcon(icon), findsOneWidget,
            reason: 'Failed to find terrain icon: $icon');

        // Clear the widget tree for the next iteration
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('should display unit information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: true,
                  tileData: TileData(
                    row: 1,
                    col: 1,
                    terrain: TerrainType.grass,
                    unit: Unit(
                      name: 'Elite Archer',
                      playerIndex: 0,
                      health: 75,
                      maxHealth: 100,
                      type: UnitType.archer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(); // Start animation
      await tester
          .pump(const Duration(milliseconds: 200)); // Complete animation

      expect(find.text('Elite Archer'), findsOneWidget);
      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('75/100'), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget); // Archer icon
    });

    testWidgets('should display building information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: true,
                  tileData: TileData(
                    row: 2,
                    col: 2,
                    terrain: TerrainType.stone,
                    building: Building(
                      name: 'Command Center',
                      playerIndex: 1,
                      health: 150,
                      maxHealth: 200,
                      type: BuildingType.commandCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Command Center'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
      expect(find.text('150/200'), findsOneWidget);
      expect(find.byIcon(Icons.business), findsOneWidget);
    });

    testWidgets('should display both unit and building information',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: true,
                  tileData: TileData(
                    row: 3,
                    col: 3,
                    terrain: TerrainType.desert,
                    unit: Unit(
                      name: 'Knight',
                      playerIndex: 0,
                      health: 90,
                      maxHealth: 120,
                      type: UnitType.cavalry,
                    ),
                    building: Building(
                      name: 'Barracks',
                      playerIndex: 0,
                      health: 80,
                      maxHealth: 100,
                      type: BuildingType.barracks,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show terrain
      expect(find.text('Desert'), findsOneWidget);

      // Should show building
      expect(find.text('Barracks'), findsOneWidget);
      expect(find.text('80/100'), findsOneWidget);

      // Should show unit
      expect(find.text('Knight'), findsOneWidget);
      expect(find.text('90/120'), findsOneWidget);

      // Should show both player indicators
      expect(find.text('Player 1'),
          findsNWidgets(2)); // Both unit and building belong to player 1
    });

    testWidgets('should show correct unit icons for different unit types',
        (WidgetTester tester) async {
      const unitTypes = [
        (UnitType.infantry, Icons.person),
        (UnitType.cavalry, Icons.directions_run),
        (UnitType.archer, Icons.my_location),
        (UnitType.mage, Icons.auto_fix_high),
      ];

      for (final (unitType, expectedIcon) in unitTypes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  GameTooltip(
                    isVisible: true,
                    tileData: TileData(
                      row: 0,
                      col: 0,
                      terrain: TerrainType.grass,
                      unit: Unit(
                        name: 'Test Unit',
                        playerIndex: 0,
                        health: 100,
                        maxHealth: 100,
                        type: unitType,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(expectedIcon), findsOneWidget,
            reason:
                'Failed to find icon $expectedIcon for unit type $unitType');

        // Clear the widget tree for the next iteration
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('should display health bars with correct colors',
        (WidgetTester tester) async {
      // Test high health (should be green)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: true,
                  tileData: TileData(
                    row: 0,
                    col: 0,
                    terrain: TerrainType.grass,
                    unit: Unit(
                      name: 'Healthy Unit',
                      playerIndex: 0,
                      health: 80,
                      maxHealth: 100,
                      type: UnitType.infantry,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the health bar container
      final healthBarFinder = find.descendant(
        of: find.byType(GameTooltip),
        matching: find.byType(FractionallySizedBox),
      );
      expect(healthBarFinder, findsOneWidget);

      final healthBarWidget =
          tester.widget<FractionallySizedBox>(healthBarFinder);
      expect(healthBarWidget.widthFactor, equals(0.8)); // 80/100 = 0.8

      // Clear and test low health (should be red)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: true,
                  tileData: TileData(
                    row: 0,
                    col: 0,
                    terrain: TerrainType.grass,
                    unit: Unit(
                      name: 'Injured Unit',
                      playerIndex: 0,
                      health: 20,
                      maxHealth: 100,
                      type: UnitType.infantry,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final lowHealthBarFinder = find.descendant(
        of: find.byType(GameTooltip),
        matching: find.byType(FractionallySizedBox),
      );
      expect(lowHealthBarFinder, findsOneWidget);

      final lowHealthBarWidget =
          tester.widget<FractionallySizedBox>(lowHealthBarFinder);
      expect(lowHealthBarWidget.widthFactor, equals(0.2)); // 20/100 = 0.2
    });

    // Removed cursor-relative positioning test; tooltip is anchored.
  });

  group('GameTooltip Widget State Tests', () {
    testWidgets('should update animation when visibility changes',
        (WidgetTester tester) async {
      // Start with invisible tooltip
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: false,
                  tileData: TileData(
                    row: 1,
                    col: 1,
                    terrain: TerrainType.grass,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Grass'), findsNothing);

      // Make tooltip visible
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameTooltip(
                  isVisible: true,
                  tileData: TileData(
                    row: 1,
                    col: 1,
                    terrain: TerrainType.grass,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Animation should start
      await tester.pump();

      // Complete animation
      await tester.pumpAndSettle();

      // Content should now be visible
      expect(find.text('Grass'), findsOneWidget);
    });

    testWidgets('should handle rapid visibility changes',
        (WidgetTester tester) async {
      // Rapidly toggle visibility
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  GameTooltip(
                    isVisible: i.isEven,
                    tileData: const TileData(
                      row: 1,
                      col: 1,
                      terrain: TerrainType.grass,
                    ),
                    position: const Offset(100, 100),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
      }

      // Should not crash and should handle state correctly
      expect(find.byType(GameTooltip), findsOneWidget);
    });
  });
}
