class Deck {
  final String id;
  final String name;
  final String color;
  final String description;
  final int cardCount;

  Deck({
    required this.id,
    required this.name,
    required this.color,
    required this.description,
    this.cardCount = 30,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      description: json['description'] ?? '',
      cardCount: json['cardCount'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
      'cardCount': cardCount,
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
