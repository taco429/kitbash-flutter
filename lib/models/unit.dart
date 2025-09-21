/// Represents the direction a unit is facing/moving
enum UnitDirection {
  north('north'),
  northEast('northeast'),
  east('east'),
  southEast('southeast'),
  south('south'),
  southWest('southwest'),
  west('west'),
  northWest('northwest');

  const UnitDirection(this.value);
  final String value;

  static UnitDirection fromString(String value) {
    return UnitDirection.values.firstWhere(
      (dir) => dir.value == value.toLowerCase(),
      orElse: () => UnitDirection.north,
    );
  }
}

/// Position on the game board
class BoardPosition {
  final int row;
  final int col;

  const BoardPosition({
    required this.row,
    required this.col,
  });

  factory BoardPosition.fromJson(Map<String, dynamic> json) {
    return BoardPosition(
      row: json['row'] ?? 0,
      col: json['col'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardPosition && other.row == row && other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'BoardPosition(row: $row, col: $col)';
}

/// Represents a unit on the game board
class GameUnit {
  final String id;
  final String cardId;
  final int playerIndex;
  final BoardPosition position;
  final UnitDirection direction;
  
  // Stats
  final int attack;
  final int health;
  final int maxHealth;
  final int armor;
  final int speed;
  final int range;
  
  // State flags
  final bool hasMoved;
  final bool hasAttacked;
  final bool isAlive;
  final int turnSpawned;
  
  // Movement target (for visualization)
  final BoardPosition? targetPosition;
  
  const GameUnit({
    required this.id,
    required this.cardId,
    required this.playerIndex,
    required this.position,
    required this.direction,
    required this.attack,
    required this.health,
    required this.maxHealth,
    required this.armor,
    required this.speed,
    required this.range,
    required this.hasMoved,
    required this.hasAttacked,
    required this.isAlive,
    required this.turnSpawned,
    this.targetPosition,
  });

  factory GameUnit.fromJson(Map<String, dynamic> json) {
    return GameUnit(
      id: json['id'] ?? '',
      cardId: json['cardId'] ?? '',
      playerIndex: json['playerIndex'] ?? 0,
      position: BoardPosition.fromJson(json['position'] ?? {}),
      direction: UnitDirection.fromString(json['direction'] ?? 'north'),
      attack: json['attack'] ?? 0,
      health: json['health'] ?? 1,
      maxHealth: json['maxHealth'] ?? 1,
      armor: json['armor'] ?? 0,
      speed: json['speed'] ?? 1,
      range: json['range'] ?? 1,
      hasMoved: json['hasMoved'] ?? false,
      hasAttacked: json['hasAttacked'] ?? false,
      isAlive: json['isAlive'] ?? true,
      turnSpawned: json['turnSpawned'] ?? 0,
      targetPosition: json['targetPosition'] != null
          ? BoardPosition.fromJson(json['targetPosition'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'playerIndex': playerIndex,
      'position': position.toJson(),
      'direction': direction.value,
      'attack': attack,
      'health': health,
      'maxHealth': maxHealth,
      'armor': armor,
      'speed': speed,
      'range': range,
      'hasMoved': hasMoved,
      'hasAttacked': hasAttacked,
      'isAlive': isAlive,
      'turnSpawned': turnSpawned,
      'targetPosition': targetPosition?.toJson(),
    };
  }

  /// Returns the health percentage (0.0 to 1.0)
  double get healthPercentage {
    if (maxHealth <= 0) return 0.0;
    return (health / maxHealth).clamp(0.0, 1.0);
  }

  /// Returns true if this unit belongs to the current player
  bool isOwnedBy(int playerIndex) {
    return this.playerIndex == playerIndex;
  }

  /// Returns true if this unit is an enemy to the given player
  bool isEnemyTo(int playerIndex) {
    return this.playerIndex != playerIndex;
  }

  /// Returns the sprite asset path based on the unit's card ID and direction
  String getSpriteAsset() {
    // Map card IDs to sprite base names
    String spriteBase;
    switch (cardId) {
      case 'red_unit_goblin':
        spriteBase = 'goblin';
        break;
      case 'purple_unit_ghoul':
        spriteBase = 'ghoul';
        break;
      default:
        // Fallback to a generic unit sprite
        spriteBase = 'unit';
    }
    
    // Map direction to sprite suffix
    String directionSuffix;
    switch (direction) {
      case UnitDirection.north:
        directionSuffix = 'n';
        break;
      case UnitDirection.northEast:
        directionSuffix = 'ne';
        break;
      case UnitDirection.east:
        directionSuffix = 'e';
        break;
      case UnitDirection.southEast:
        directionSuffix = 'se';
        break;
      case UnitDirection.south:
        directionSuffix = 's';
        break;
      case UnitDirection.southWest:
        directionSuffix = 'sw';
        break;
      case UnitDirection.west:
        directionSuffix = 'w';
        break;
      case UnitDirection.northWest:
        directionSuffix = 'nw';
        break;
    }
    
    return 'assets/images/units/${spriteBase}_$directionSuffix.png';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameUnit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GameUnit(id: $id, cardId: $cardId, position: $position, health: $health/$maxHealth, attack: $attack)';
  }
}