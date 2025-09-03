import 'card.dart';

class Deck {
  final String id;
  final String name;
  final String color;
  final String description;
  final String? heroCardId;
  final List<DeckCard> pawnCards;
  final List<DeckCard> mainCards;

  Deck({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
    this.heroCardId,
    this.pawnCards = const [],
    this.mainCards = const [],
  });

  /// Get all cards in the deck (hero + pawns + main cards)
  List<DeckCard> get allCards {
    final cards = <DeckCard>[];
    
    // Note: Hero card would be added here if we have hero card data
    // For now, we'll just combine pawns and main cards
    cards.addAll(pawnCards);
    cards.addAll(mainCards);
    
    return cards;
  }

  /// Get the total number of cards in the deck
  int get cardCount {
    int total = heroCardId != null ? 1 : 0; // Hero card
    total += pawnCards.fold(0, (sum, deckCard) => sum + deckCard.quantity);
    total += mainCards.fold(0, (sum, deckCard) => sum + deckCard.quantity);
    return total;
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      description: json['description'] ?? '',
      heroCardId: json['heroCardId'],
      pawnCards: [], // Would be populated separately
      mainCards: [], // Would be populated separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
      'heroCardId': heroCardId,
      'pawnCards': pawnCards.map((deckCard) => deckCard.toJson()).toList(),
      'mainCards': mainCards.map((deckCard) => deckCard.toJson()).toList(),
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
