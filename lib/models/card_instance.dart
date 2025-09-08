/// Represents a specific instance of a card in a game.
/// Each physical card in a deck has its own CardInstance, even if multiple
/// cards share the same cardId (duplicates of the same card type).
class CardInstance {
  final String instanceId;
  final String cardId;

  const CardInstance({
    required this.instanceId,
    required this.cardId,
  });

  factory CardInstance.fromJson(Map<String, dynamic> json) {
    return CardInstance(
      instanceId: json['instanceId']?.toString() ?? '',
      cardId: json['cardId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instanceId': instanceId,
      'cardId': cardId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardInstance && other.instanceId == instanceId;
  }

  @override
  int get hashCode => instanceId.hashCode;

  @override
  String toString() {
    return 'CardInstance(instanceId: $instanceId, cardId: $cardId)';
  }
}
