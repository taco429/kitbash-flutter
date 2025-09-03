/// Represents the data for a single tile on the game board
class TileData {
  final int row;
  final int col;
  final TerrainType terrain;
  final Unit? unit;
  final Building? building;

  const TileData({
    required this.row,
    required this.col,
    required this.terrain,
    this.unit,
    this.building,
  });

  /// Creates a copy of this tile data with optional modifications
  TileData copyWith({
    int? row,
    int? col,
    TerrainType? terrain,
    Unit? unit,
    Building? building,
  }) {
    return TileData(
      row: row ?? this.row,
      col: col ?? this.col,
      terrain: terrain ?? this.terrain,
      unit: unit ?? this.unit,
      building: building ?? this.building,
    );
  }

  /// Returns a description of what's on this tile for tooltips
  String getTooltipDescription() {
    final List<String> descriptions = ['Terrain: ${terrain.displayName}'];

    if (building != null) {
      descriptions.add('Building: ${building!.name}');
    }

    if (unit != null) {
      descriptions.add('Unit: ${unit!.name}');
    }

    return descriptions.join('\n');
  }

  /// Checks if this tile has any entities (units or buildings)
  bool get hasEntities => unit != null || building != null;
}

/// Represents different types of terrain
enum TerrainType {
  grass('Grass'),
  stone('Stone'),
  water('Water'),
  desert('Desert'),
  forest('Forest'),
  mountain('Mountain');

  const TerrainType(this.displayName);
  final String displayName;
}

/// Represents a unit on the board
class Unit {
  final String name;
  final int playerIndex;
  final int health;
  final int maxHealth;
  final UnitType type;

  const Unit({
    required this.name,
    required this.playerIndex,
    required this.health,
    required this.maxHealth,
    required this.type,
  });

  double get healthPercentage => maxHealth > 0 ? health / maxHealth : 0.0;
  bool get isDestroyed => health <= 0;
}

/// Types of units
enum UnitType {
  infantry('Infantry'),
  cavalry('Cavalry'),
  archer('Archer'),
  mage('Mage');

  const UnitType(this.displayName);
  final String displayName;
}

/// Represents a building on the board
class Building {
  final String name;
  final int playerIndex;
  final int health;
  final int maxHealth;
  final BuildingType type;

  const Building({
    required this.name,
    required this.playerIndex,
    required this.health,
    required this.maxHealth,
    required this.type,
  });

  double get healthPercentage => maxHealth > 0 ? health / maxHealth : 0.0;
  bool get isDestroyed => health <= 0;
}

/// Types of buildings
enum BuildingType {
  commandCenter('Command Center'),
  barracks('Barracks'),
  tower('Tower'),
  wall('Wall');

  const BuildingType(this.displayName);
  final String displayName;
}
