/// Resource models for the card game

/// Represents the resources a player has
class Resources {
  final int gold;
  final int mana;

  const Resources({
    required this.gold,
    required this.mana,
  });

  factory Resources.fromJson(Map<String, dynamic> json) {
    return Resources(
      gold: json['gold'] ?? 0,
      mana: json['mana'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gold': gold,
      'mana': mana,
    };
  }

  Resources copyWith({
    int? gold,
    int? mana,
  }) {
    return Resources(
      gold: gold ?? this.gold,
      mana: mana ?? this.mana,
    );
  }

  @override
  String toString() => 'Resources(gold: $gold, mana: $mana)';
}

/// Represents resource generation from buildings
class ResourceGeneration {
  final int gold;
  final int mana;

  const ResourceGeneration({
    required this.gold,
    required this.mana,
  });

  factory ResourceGeneration.fromJson(Map<String, dynamic> json) {
    return ResourceGeneration(
      gold: json['gold'] ?? 0,
      mana: json['mana'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gold': gold,
      'mana': mana,
    };
  }

  @override
  String toString() => 'ResourceGeneration(gold: $gold, mana: $mana)';
}

/// Building types
enum BuildingType {
  commandCenter,
}

/// Building levels
enum BuildingLevel {
  level1(1),
  level2(2),
  level3(3);

  final int value;
  const BuildingLevel(this.value);

  static BuildingLevel fromValue(int value) {
    switch (value) {
      case 1:
        return BuildingLevel.level1;
      case 2:
        return BuildingLevel.level2;
      case 3:
        return BuildingLevel.level3;
      default:
        return BuildingLevel.level1;
    }
  }
}

/// Represents a building that can generate resources
class Building {
  final BuildingType type;
  final BuildingLevel level;
  final int playerIndex;
  final int topLeftRow;
  final int topLeftCol;
  final int turnsSinceUpgrade;
  final DateTime lastUpgradeTime;
  final ResourceGeneration resourceGeneration;

  const Building({
    required this.type,
    required this.level,
    required this.playerIndex,
    required this.topLeftRow,
    required this.topLeftCol,
    required this.turnsSinceUpgrade,
    required this.lastUpgradeTime,
    required this.resourceGeneration,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    // Parse building type
    BuildingType type = BuildingType.commandCenter;
    if (json['type'] == 'command_center') {
      type = BuildingType.commandCenter;
    }

    // Parse building level
    BuildingLevel level = BuildingLevel.level1;
    if (json['level'] is int) {
      level = BuildingLevel.fromValue(json['level']);
    }

    // Parse last upgrade time
    DateTime lastUpgradeTime = DateTime.now();
    if (json['lastUpgradeTime'] != null) {
      try {
        lastUpgradeTime = DateTime.parse(json['lastUpgradeTime']);
      } catch (_) {
        // Ignore parse errors
      }
    }

    return Building(
      type: type,
      level: level,
      playerIndex: json['playerIndex'] ?? 0,
      topLeftRow: json['topLeftRow'] ?? 0,
      topLeftCol: json['topLeftCol'] ?? 0,
      turnsSinceUpgrade: json['turnsSinceUpgrade'] ?? 0,
      lastUpgradeTime: lastUpgradeTime,
      resourceGeneration: json['resourceGeneration'] != null
          ? ResourceGeneration.fromJson(json['resourceGeneration'])
          : const ResourceGeneration(gold: 0, mana: 0),
    );
  }

  /// Get the display name for the building level
  String get levelDisplay {
    switch (level) {
      case BuildingLevel.level1:
        return 'Level 1';
      case BuildingLevel.level2:
        return 'Level 2';
      case BuildingLevel.level3:
        return 'Level 3';
    }
  }

  /// Get the number of turns until next upgrade (3 turns per upgrade)
  int get turnsUntilUpgrade {
    if (level == BuildingLevel.level3) {
      return -1; // Max level
    }
    return 3 - turnsSinceUpgrade;
  }

  /// Check if building can upgrade
  bool get canUpgrade {
    return level != BuildingLevel.level3 && turnsSinceUpgrade >= 3;
  }

  @override
  String toString() => 'Building($type, $levelDisplay)';
}