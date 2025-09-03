/// Stats for units created by Unit cards
class UnitStats {
  final int attack;
  final int health;
  final int armor;
  final int speed;
  final int range;

  const UnitStats({
    required this.attack,
    required this.health,
    required this.armor,
    required this.speed,
    required this.range,
  });

  factory UnitStats.fromJson(Map<String, dynamic> json) {
    return UnitStats(
      attack: json['attack'] ?? 0,
      health: json['health'] ?? 1,
      armor: json['armor'] ?? 0,
      speed: json['speed'] ?? 1,
      range: json['range'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attack': attack,
      'health': health,
      'armor': armor,
      'speed': speed,
      'range': range,
    };
  }
}

/// Effects for spell cards
class SpellEffect {
  final String targetType;
  final String effect;

  const SpellEffect({
    required this.targetType,
    required this.effect,
  });

  factory SpellEffect.fromJson(Map<String, dynamic> json) {
    return SpellEffect(
      targetType: json['targetType'] ?? 'unit',
      effect: json['effect'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetType': targetType,
      'effect': effect,
    };
  }
}

/// Stats for buildings created by Building cards
class BuildingStats {
  final int health;
  final int armor;
  final int? attack;
  final int? range;

  const BuildingStats({
    required this.health,
    required this.armor,
    this.attack,
    this.range,
  });

  factory BuildingStats.fromJson(Map<String, dynamic> json) {
    return BuildingStats(
      health: json['health'] ?? 1,
      armor: json['armor'] ?? 0,
      attack: json['attack'],
      range: json['range'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'health': health,
      'armor': armor,
      'attack': attack,
      'range': range,
    };
  }
}

/// Stats for hero cards
class HeroStats {
  final int attack;
  final int health;
  final int armor;
  final int speed;
  final int range;
  final int cooldown;

  const HeroStats({
    required this.attack,
    required this.health,
    required this.armor,
    required this.speed,
    required this.range,
    required this.cooldown,
  });

  factory HeroStats.fromJson(Map<String, dynamic> json) {
    return HeroStats(
      attack: json['attack'] ?? 0,
      health: json['health'] ?? 1,
      armor: json['armor'] ?? 0,
      speed: json['speed'] ?? 1,
      range: json['range'] ?? 1,
      cooldown: json['cooldown'] ?? 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attack': attack,
      'health': health,
      'armor': armor,
      'speed': speed,
      'range': range,
      'cooldown': cooldown,
    };
  }
}

/// Represents a collectible card in the game
class GameCard {
  final String id;
  final String name;
  final String description;
  final int goldCost;
  final int manaCost;
  final CardType type;
  final CardColor color;
  final UnitStats? unitStats;
  final SpellEffect? spellEffect;
  final BuildingStats? buildingStats;
  final HeroStats? heroStats;
  final List<String> abilities;
  final String? flavorText;

  const GameCard({
    required this.id,
    required this.name,
    required this.description,
    required this.goldCost,
    required this.manaCost,
    required this.type,
    required this.color,
    this.unitStats,
    this.spellEffect,
    this.buildingStats,
    this.heroStats,
    this.abilities = const [],
    this.flavorText,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      goldCost: json['goldCost'] ?? 0,
      manaCost: json['manaCost'] ?? 0,
      type: _parseCardType(json['type']),
      color: _parseCardColor(json['color']),
      unitStats: json['unitStats'] != null 
          ? UnitStats.fromJson(json['unitStats'])
          : null,
      spellEffect: json['spellEffect'] != null
          ? SpellEffect.fromJson(json['spellEffect'])
          : null,
      buildingStats: json['buildingStats'] != null
          ? BuildingStats.fromJson(json['buildingStats'])
          : null,
      heroStats: json['heroStats'] != null
          ? HeroStats.fromJson(json['heroStats'])
          : null,
      abilities: List<String>.from(json['abilities'] ?? []),
      flavorText: json['flavorText'],
    );
  }

  static CardType _parseCardType(dynamic typeValue) {
    final typeStr = typeValue?.toString() ?? 'unit';
    switch (typeStr.toLowerCase()) {
      case 'unit':
        return CardType.unit;
      case 'spell':
        return CardType.spell;
      case 'building':
        return CardType.building;
      case 'order':
        return CardType.order;
      case 'hero':
        return CardType.hero;
      default:
        return CardType.unit;
    }
  }

  static CardColor _parseCardColor(dynamic colorValue) {
    final colorStr = colorValue?.toString() ?? 'red';
    switch (colorStr.toLowerCase()) {
      case 'red':
        return CardColor.red;
      case 'orange':
        return CardColor.orange;
      case 'yellow':
        return CardColor.yellow;
      case 'green':
        return CardColor.green;
      case 'blue':
        return CardColor.blue;
      case 'purple':
        return CardColor.purple;
      default:
        return CardColor.red;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'goldCost': goldCost,
      'manaCost': manaCost,
      'type': type.toString().split('.').last,
      'color': color.toString().split('.').last,
      'unitStats': unitStats?.toJson(),
      'spellEffect': spellEffect?.toJson(),
      'buildingStats': buildingStats?.toJson(),
      'heroStats': heroStats?.toJson(),
      'abilities': abilities,
      'flavorText': flavorText,
    };
  }

  /// Returns true if this is a unit card
  bool get isUnit => type == CardType.unit;

  /// Returns true if this is a spell card
  bool get isSpell => type == CardType.spell;

  /// Returns true if this is a building card
  bool get isBuilding => type == CardType.building;

  /// Returns true if this is an order card
  bool get isOrder => type == CardType.order;

  /// Returns true if this is a hero card
  bool get isHero => type == CardType.hero;

  /// Returns the total resource cost
  int get totalCost => goldCost + manaCost;

  /// Returns the card's power level based on what it creates
  int get powerLevel {
    if (isUnit && unitStats != null) {
      return unitStats!.attack + unitStats!.health;
    }
    if (isBuilding && buildingStats != null) {
      return buildingStats!.health + (buildingStats!.armor * 2);
    }
    if (isHero && heroStats != null) {
      return heroStats!.attack + heroStats!.health;
    }
    return totalCost; // For spells and orders
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GameCard(id: $id, name: $name, goldCost: $goldCost, manaCost: $manaCost, type: $type, color: $color)';
  }
}

/// Types of cards available in the game
enum CardType {
  unit('Unit'),
  spell('Spell'),
  building('Building'),
  order('Order'),
  hero('Hero');

  const CardType(this.displayName);
  final String displayName;
}

/// Colors/factions available in the game
enum CardColor {
  red('Red'),
  orange('Orange'),
  yellow('Yellow'),
  green('Green'),
  blue('Blue'),
  purple('Purple');

  const CardColor(this.displayName);
  final String displayName;
}

/// Represents a card instance in a deck with quantity
class DeckCard {
  final GameCard card;
  final int quantity;

  const DeckCard({
    required this.card,
    required this.quantity,
  });

  factory DeckCard.fromJson(Map<String, dynamic> json, GameCard card) {
    return DeckCard(
      card: card,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': card.id,
      'quantity': quantity,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeckCard && other.card.id == card.id;
  }

  @override
  int get hashCode => card.id.hashCode;
}