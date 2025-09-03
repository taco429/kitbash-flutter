/// Represents a collectible card in the game
class GameCard {
  final String id;
  final String name;
  final String description;
  final int cost;
  final CardType type;
  final CardColor color;
  final int? attack;
  final int? health;
  final List<String> abilities;
  final String? flavorText;

  const GameCard({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.type,
    required this.color,
    this.attack,
    this.health,
    this.abilities = const [],
    this.flavorText,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cost: json['cost'] ?? 0,
      type: _parseCardType(json['type']),
      color: _parseCardColor(json['color']),
      attack: json['attack'],
      health: json['health'],
      abilities: List<String>.from(json['abilities'] ?? []),
      flavorText: json['flavorText'],
    );
  }

  static CardType _parseCardType(dynamic typeValue) {
    final typeStr = typeValue?.toString() ?? 'creature';
    switch (typeStr.toLowerCase()) {
      case 'creature':
        return CardType.creature;
      case 'spell':
        return CardType.spell;
      case 'artifact':
        return CardType.artifact;
      default:
        return CardType.creature;
    }
  }

  static CardColor _parseCardColor(dynamic colorValue) {
    final colorStr = colorValue?.toString() ?? 'neutral';
    switch (colorStr.toLowerCase()) {
      case 'red':
        return CardColor.red;
      case 'purple':
        return CardColor.purple;
      case 'blue':
        return CardColor.blue;
      case 'green':
        return CardColor.green;
      case 'white':
        return CardColor.white;
      case 'black':
        return CardColor.black;
      case 'neutral':
      default:
        return CardColor.neutral;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cost': cost,
      'type': type.toString().split('.').last,
      'color': color.toString().split('.').last,
      'attack': attack,
      'health': health,
      'abilities': abilities,
      'flavorText': flavorText,
    };
  }

  /// Returns true if this is a creature card
  bool get isCreature => type == CardType.creature;

  /// Returns true if this is a spell card
  bool get isSpell => type == CardType.spell;

  /// Returns the card's power level (attack + health for creatures)
  int get powerLevel {
    if (isCreature && attack != null && health != null) {
      return attack! + health!;
    }
    return cost; // For spells, use cost as power indicator
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
    return 'GameCard(id: $id, name: $name, cost: $cost, type: $type, color: $color)';
  }
}

/// Types of cards available in the game
enum CardType {
  creature('Creature'),
  spell('Spell'),
  artifact('Artifact');

  const CardType(this.displayName);
  final String displayName;
}

/// Colors/factions available in the game
enum CardColor {
  red('Red'),
  purple('Purple'),
  blue('Blue'),
  green('Green'),
  white('White'),
  black('Black'),
  neutral('Neutral');

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