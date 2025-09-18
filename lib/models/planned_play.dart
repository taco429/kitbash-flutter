class PlannedPlay {
  final int playerIndex;
  final String cardInstanceId;
  final String cardId;
  final int row;
  final int col;

  const PlannedPlay({
    required this.playerIndex,
    required this.cardInstanceId,
    required this.cardId,
    required this.row,
    required this.col,
  });

  factory PlannedPlay.fromJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>?;
    return PlannedPlay(
      playerIndex: json['playerIndex'] ?? 0,
      cardInstanceId: json['cardInstanceId'] ?? json['cardInstanceID'] ?? '',
      cardId: json['cardId'] ?? '',
      row: position != null ? (position['row'] ?? 0) : (json['row'] ?? 0),
      col: position != null ? (position['col'] ?? 0) : (json['col'] ?? 0),
    );
  }
}
