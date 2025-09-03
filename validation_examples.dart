// This file demonstrates the key functionality of the hover tooltip implementation
// It shows how the various components work together
//ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'lib/models/tile_data.dart';
import 'lib/widgets/game_tooltip.dart';

void main() {
  // This file serves as documentation and validation of the implementation
  print('Hover Tooltip Implementation Validation');
  print('=========================================');

  // Demonstrate tile data creation
  demonstrateTileDataCreation();

  // Demonstrate terrain system
  demonstrateTerrainSystem();

  // Demonstrate tooltip content generation
  demonstrateTooltipContent();

  // Demonstrate coordinate system
  demonstrateCoordinateSystem();
}

void demonstrateTileDataCreation() {
  print('\n1. Tile Data Creation:');
  print('----------------------');

  // Basic tile with just terrain
  const grassTile = TileData(
    row: 2,
    col: 3,
    terrain: TerrainType.grass,
  );
  print('Basic tile: ${grassTile.getTooltipDescription()}');

  // Tile with unit
  const tileWithUnit = TileData(
    row: 1,
    col: 1,
    terrain: TerrainType.forest,
    unit: Unit(
      name: 'Elite Archer',
      playerIndex: 0,
      health: 75,
      maxHealth: 100,
      type: UnitType.archer,
    ),
  );
  print('Tile with unit: ${tileWithUnit.getTooltipDescription()}');

  // Tile with building
  const tileWithBuilding = TileData(
    row: 5,
    col: 5,
    terrain: TerrainType.stone,
    building: Building(
      name: 'Command Center',
      playerIndex: 1,
      health: 200,
      maxHealth: 250,
      type: BuildingType.commandCenter,
    ),
  );
  print('Tile with building: ${tileWithBuilding.getTooltipDescription()}');

  // Tile with both unit and building
  const complexTile = TileData(
    row: 0,
    col: 0,
    terrain: TerrainType.mountain,
    unit: Unit(
      name: 'Mountain Guard',
      playerIndex: 0,
      health: 90,
      maxHealth: 120,
      type: UnitType.infantry,
    ),
    building: Building(
      name: 'Watchtower',
      playerIndex: 0,
      health: 150,
      maxHealth: 200,
      type: BuildingType.tower,
    ),
  );
  print('Complex tile: ${complexTile.getTooltipDescription()}');
}

void demonstrateTerrainSystem() {
  print('\n2. Terrain System:');
  print('------------------');

  for (final terrain in TerrainType.values) {
    print('${terrain.displayName}: Available for tile generation');
  }

  print('\nTerrain generation example (distance-based):');
  for (int distance = 0; distance < 6; distance++) {
    final terrain = _getTerrainForDistance(distance);
    print('Distance $distance: ${terrain.displayName}');
  }
}

TerrainType _getTerrainForDistance(int distance) {
  // Simulates the terrain generation logic from IsometricGridComponent
  if (distance < 2) {
    return TerrainType.grass;
  } else if (distance < 4) {
    return distance % 3 == 0 ? TerrainType.forest : TerrainType.grass;
  } else if (distance < 6) {
    return distance % 4 == 0 ? TerrainType.stone : TerrainType.grass;
  } else {
    return TerrainType.mountain;
  }
}

void demonstrateTooltipContent() {
  print('\n3. Tooltip Content Generation:');
  print('------------------------------');

  const examples = [
    TileData(row: 0, col: 0, terrain: TerrainType.water),
    TileData(row: 1, col: 1, terrain: TerrainType.desert),
    TileData(
      row: 2,
      col: 2,
      terrain: TerrainType.grass,
      unit: Unit(
        name: 'Knight',
        playerIndex: 0,
        health: 100,
        maxHealth: 100,
        type: UnitType.cavalry,
      ),
    ),
  ];

  for (final tile in examples) {
    print('Tile (${tile.row}, ${tile.col}):');
    print('  ${tile.getTooltipDescription().replaceAll('\n', '\n  ')}');
    print('  Has entities: ${tile.hasEntities}');
  }
}

void demonstrateCoordinateSystem() {
  print('\n4. Coordinate System:');
  print('--------------------');

  // Demonstrate isometric coordinate conversion
  print('Isometric grid coordinate examples:');
  const examples = [
    (0, 0, 'Top corner'),
    (2, 2, 'Center area'),
    (5, 0, 'Right edge'),
    (0, 5, 'Left edge'),
  ];

  for (final (row, col, description) in examples) {
    // This would normally use the actual conversion from IsometricGridComponent
    final screenX = (col - row) * 32; // tileSize.x / 2
    final screenY = (col + row) * 16; // tileSize.y / 2
    print('Grid ($row, $col) -> Screen ($screenX, $screenY) - $description');
  }
}

// Example widget usage (for documentation purposes)
class ExampleTooltipUsage extends StatelessWidget {
  const ExampleTooltipUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameTooltip(
      isVisible: true,
      position: Offset(100, 100),
      tileData: TileData(
        row: 1,
        col: 1,
        terrain: TerrainType.grass,
        unit: Unit(
          name: 'Example Unit',
          playerIndex: 0,
          health: 80,
          maxHealth: 100,
          type: UnitType.infantry,
        ),
      ),
    );
  }
}

// Example of hover callback usage
void exampleHoverCallback(TileData? tileData, Offset? position) {
  if (tileData != null && position != null) {
    print('Hover detected at $position');
    print('Tile info: ${tileData.getTooltipDescription()}');
  } else {
    print('Hover ended');
  }
}

// Unit and building health calculations
void demonstrateHealthCalculations() {
  print('\n5. Health Calculations:');
  print('----------------------');

  const entities = [
    Unit(
        name: 'Healthy Unit',
        playerIndex: 0,
        health: 100,
        maxHealth: 100,
        type: UnitType.infantry),
    Unit(
        name: 'Injured Unit',
        playerIndex: 0,
        health: 30,
        maxHealth: 100,
        type: UnitType.infantry),
    Unit(
        name: 'Critical Unit',
        playerIndex: 0,
        health: 10,
        maxHealth: 100,
        type: UnitType.infantry),
    Building(
        name: 'Strong Building',
        playerIndex: 1,
        health: 250,
        maxHealth: 300,
        type: BuildingType.commandCenter),
    Building(
        name: 'Damaged Building',
        playerIndex: 1,
        health: 50,
        maxHealth: 200,
        type: BuildingType.tower),
  ];

  for (final entity in entities) {
    final healthPercent = entity is Unit
        ? entity.healthPercentage
        : (entity as Building).healthPercentage;
    final isDestroyed =
        entity is Unit ? entity.isDestroyed : (entity as Building).isDestroyed;
    final health = entity is Unit ? entity.health : (entity as Building).health;
    final maxHealth =
        entity is Unit ? entity.maxHealth : (entity as Building).maxHealth;
    final name = entity is Unit ? entity.name : (entity as Building).name;

    print(
        '$name: $health/$maxHealth (${(healthPercent * 100).toInt()}%) - ${isDestroyed ? 'DESTROYED' : 'ALIVE'}');
  }
}
