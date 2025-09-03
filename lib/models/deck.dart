import 'card.dart';

class Deck {
  final String id;
  final String name;
  final String color;
  final String description;
  final List<DeckCard> cards;

  Deck({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
    this.cards = const [],
  });

  /// Get the total number of cards in the deck
  int get cardCount => cards.fold(0, (sum, deckCard) => sum + deckCard.quantity);

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      description: json['description'] ?? '',
      cards: [], // Cards would be loaded separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
      'cards': cards.map((deckCard) => deckCard.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deck && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
