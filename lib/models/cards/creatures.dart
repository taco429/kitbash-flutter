import '../card.dart';

/// Collection of creature cards available in the game
class CreatureCards {
  /// Simple Skeleton - A basic purple creature
  static const GameCard skeleton = GameCard(
    id: 'skeleton_001',
    name: 'Skeleton Warrior',
    description: 'A reanimated warrior that fights with undying loyalty.',
    cost: 2,
    type: CardType.creature,
    color: CardColor.purple,
    attack: 2,
    health: 1,
    abilities: ['Undead'],
    flavorText: 'Death is but the beginning of service.',
  );

  /// Simple Goblin - A basic red creature
  static const GameCard goblin = GameCard(
    id: 'goblin_001',
    name: 'Goblin Raider',
    description: 'A fierce and quick goblin warrior ready for battle.',
    cost: 1,
    type: CardType.creature,
    color: CardColor.red,
    attack: 2,
    health: 1,
    abilities: ['Haste'],
    flavorText: 'Small in stature, big in fury.',
  );

  /// Enhanced Skeleton - A stronger purple creature
  static const GameCard skeletonArcher = GameCard(
    id: 'skeleton_002',
    name: 'Skeleton Archer',
    description: 'An undead archer that can strike from a distance.',
    cost: 3,
    type: CardType.creature,
    color: CardColor.purple,
    attack: 2,
    health: 2,
    abilities: ['Undead', 'Ranged'],
    flavorText: 'Even in death, their aim remains true.',
  );

  /// Enhanced Goblin - A stronger red creature
  static const GameCard goblinChieftain = GameCard(
    id: 'goblin_002',
    name: 'Goblin Chieftain',
    description: 'A powerful goblin leader that rallies other goblins.',
    cost: 3,
    type: CardType.creature,
    color: CardColor.red,
    attack: 3,
    health: 2,
    abilities: ['Haste', 'Rally'],
    flavorText: 'Where the chieftain leads, the tribe follows.',
  );

  /// All available creature cards
  static const List<GameCard> allCreatures = [
    skeleton,
    goblin,
    skeletonArcher,
    goblinChieftain,
  ];

  /// Get all creatures of a specific color
  static List<GameCard> getCreaturesByColor(CardColor color) {
    return allCreatures.where((card) => card.color == color).toList();
  }

  /// Get all purple (skeleton) creatures
  static List<GameCard> get purpleCreatures => getCreaturesByColor(CardColor.purple);

  /// Get all red (goblin) creatures
  static List<GameCard> get redCreatures => getCreaturesByColor(CardColor.red);
}