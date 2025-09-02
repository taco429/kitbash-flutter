import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:kitbash_flutter/game/kitbash_game.dart';
import 'package:kitbash_flutter/services/game_service.dart';
import 'package:kitbash_flutter/models/tile_data.dart';

void main() {
  group('Hover Highlight Tests', () {
    late KitbashGame game;
    late GameService gameService;
    late IsometricGridComponent grid;

    setUp(() {
      gameService = GameService();
      game = KitbashGame(gameId: 'test-game', gameService: gameService);
      grid = IsometricGridComponent(
        rows: 5,
        cols: 5,
        tileSize: Vector2(64, 32),
        gameService: gameService,
      );
    });

    test('should initialize with no hovered tile', () {
      expect(grid.hoveredRow, isNull);
      expect(grid.hoveredCol, isNull);
    });

    test('should handle hover on valid tile coordinates', () {
      // Simulate hover at center of grid (approximately)
      final centerPoint = Vector2(grid.size.x / 2, grid.size.y / 4);
      final tileData = grid.handleHover(centerPoint);

      expect(tileData, isNotNull);
      expect(grid.hoveredRow, isNotNull);
      expect(grid.hoveredCol, isNotNull);
      expect(grid.hoveredRow! >= 0, isTrue);
      expect(grid.hoveredRow! < 5, isTrue);
      expect(grid.hoveredCol! >= 0, isTrue);
      expect(grid.hoveredCol! < 5, isTrue);
    });

    test('should return null for hover outside grid bounds', () {
      // Test hover far outside the grid
      final outsidePoint = Vector2(-1000, -1000);
      final tileData = grid.handleHover(outsidePoint);

      expect(tileData, isNull);
      expect(grid.hoveredRow, isNull);
      expect(grid.hoveredCol, isNull);
    });

    test('should clear hover when moving outside grid', () {
      // First hover over a valid tile
      final centerPoint = Vector2(grid.size.x / 2, grid.size.y / 4);
      var tileData = grid.handleHover(centerPoint);
      expect(tileData, isNotNull);
      expect(grid.hoveredRow, isNotNull);

      // Then hover outside
      final outsidePoint = Vector2(-1000, -1000);
      tileData = grid.handleHover(outsidePoint);
      expect(tileData, isNull);
      expect(grid.hoveredRow, isNull);
      expect(grid.hoveredCol, isNull);
    });

    test('should return tile data with correct terrain information', () {
      final centerPoint = Vector2(grid.size.x / 2, grid.size.y / 4);
      final tileData = grid.handleHover(centerPoint);

      expect(tileData, isNotNull);
      expect(tileData!.row, equals(grid.hoveredRow));
      expect(tileData.col, equals(grid.hoveredCol));
      expect(tileData.terrain, isA<TerrainType>());
    });

    test('should detect command center buildings on tiles', () {
      // Add a command center to the grid
      final commandCenter = CommandCenter(
        playerIndex: 0,
        topLeftRow: 1,
        topLeftCol: 1,
        health: 100,
        maxHealth: 100,
      );
      
      // Create a new grid with the command center
      final gridWithCC = IsometricGridComponent(
        rows: 5,
        cols: 5,
        tileSize: Vector2(64, 32),
        gameService: gameService,
        commandCenters: [commandCenter],
      );

      // Calculate hover point for command center tile (1,1)
      final ccPoint = gridWithCC.isoToScreen(1, 1, gridWithCC.size.x / 2, 0);
      final tileData = gridWithCC.handleHover(ccPoint);

      expect(tileData, isNotNull);
      expect(tileData!.building, isNotNull);
      expect(tileData.building!.type, equals(BuildingType.commandCenter));
      expect(tileData.building!.playerIndex, equals(0));
      expect(tileData.building!.health, equals(100));
    });

    test('should handle hover callback registration', () {
      TileData? callbackTileData;
      Offset? callbackPosition;
      
      game.setTileHoverCallback((tileData, position) {
        callbackTileData = tileData;
        callbackPosition = position;
      });

      expect(game.onTileHover, isNotNull);
      
      // Simulate callback
      game.onTileHover!(
        const TileData(row: 1, col: 1, terrain: TerrainType.grass),
        const Offset(100, 100),
      );

      expect(callbackTileData, isNotNull);
      expect(callbackTileData!.row, equals(1));
      expect(callbackTileData!.col, equals(1));
      expect(callbackPosition, equals(const Offset(100, 100)));
    });

    test('should maintain separate hover and selection states', () {
      final centerPoint = Vector2(grid.size.x / 2, grid.size.y / 4);
      
      // Hover over a tile
      grid.handleHover(centerPoint);
      final hoveredRow = grid.hoveredRow;
      final hoveredCol = grid.hoveredCol;
      
      // Tap on a different tile
      final tapPoint = Vector2(grid.size.x / 3, grid.size.y / 3);
      grid.handleTap(tapPoint);
      
      // Hover state should remain unchanged
      expect(grid.hoveredRow, equals(hoveredRow));
      expect(grid.hoveredCol, equals(hoveredCol));
      
      // Selection state should be different
      expect(grid.highlightedRow, isNot(equals(hoveredRow)));
      expect(grid.highlightedCol, isNot(equals(hoveredCol)));
    });
  });

  group('Terrain Color Tests', () {
    late IsometricGridComponent grid;
    late GameService gameService;

    setUp(() {
      gameService = GameService();
      grid = IsometricGridComponent(
        rows: 3,
        cols: 3,
        tileSize: Vector2(64, 32),
        gameService: gameService,
      );
    });

    test('should return different colors for different terrain types', () {
      final grassColor = grid.getTerrainColor(TerrainType.grass);
      final stoneColor = grid.getTerrainColor(TerrainType.stone);
      final waterColor = grid.getTerrainColor(TerrainType.water);

      expect(grassColor, isNot(equals(stoneColor)));
      expect(grassColor, isNot(equals(waterColor)));
      expect(stoneColor, isNot(equals(waterColor)));
    });

    test('should return consistent colors for same terrain type', () {
      final color1 = grid.getTerrainColor(TerrainType.forest);
      final color2 = grid.getTerrainColor(TerrainType.forest);

      expect(color1, equals(color2));
    });
  });

  group('Tile Data Model Tests', () {
    test('should create tile data with required fields', () {
      const tileData = TileData(
        row: 2,
        col: 3,
        terrain: TerrainType.grass,
      );

      expect(tileData.row, equals(2));
      expect(tileData.col, equals(3));
      expect(tileData.terrain, equals(TerrainType.grass));
      expect(tileData.unit, isNull);
      expect(tileData.building, isNull);
    });

    test('should create tile data with unit and building', () {
      const unit = Unit(
        name: 'Test Unit',
        playerIndex: 0,
        health: 50,
        maxHealth: 100,
        type: UnitType.infantry,
      );

      const building = Building(
        name: 'Test Building',
        playerIndex: 1,
        health: 200,
        maxHealth: 300,
        type: BuildingType.barracks,
      );

      const tileData = TileData(
        row: 1,
        col: 1,
        terrain: TerrainType.stone,
        unit: unit,
        building: building,
      );

      expect(tileData.unit, equals(unit));
      expect(tileData.building, equals(building));
      expect(tileData.hasEntities, isTrue);
    });

    test('should generate correct tooltip description', () {
      const tileData = TileData(
        row: 0,
        col: 0,
        terrain: TerrainType.forest,
        unit: Unit(
          name: 'Archer',
          playerIndex: 0,
          health: 75,
          maxHealth: 100,
          type: UnitType.archer,
        ),
      );

      final description = tileData.getTooltipDescription();
      expect(description, contains('Terrain: Forest'));
      expect(description, contains('Unit: Archer'));
    });

    test('should copy tile data with modifications', () {
      const original = TileData(
        row: 1,
        col: 2,
        terrain: TerrainType.grass,
      );

      final modified = original.copyWith(
        terrain: TerrainType.water,
        unit: const Unit(
          name: 'New Unit',
          playerIndex: 0,
          health: 100,
          maxHealth: 100,
          type: UnitType.mage,
        ),
      );

      expect(modified.row, equals(original.row));
      expect(modified.col, equals(original.col));
      expect(modified.terrain, equals(TerrainType.water));
      expect(modified.unit, isNotNull);
      expect(modified.unit!.name, equals('New Unit'));
    });
  });
}