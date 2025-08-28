class PlayerState {
  final String id;
  final String name;
  final List<CardState> hand;

  PlayerState({required this.id, required this.name, required this.hand});

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    final handJson = (json['hand'] as List?) ?? [];
    return PlayerState(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hand: handJson.map((e) => CardState.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CardState {
  final String id;
  final String name;
  final int cost;

  CardState({required this.id, required this.name, required this.cost});

  factory CardState.fromJson(Map<String, dynamic> json) {
    return CardState(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Card',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
    );
  }
}

class BoardSlotState {
  final String? cardId;
  final int x;
  final int y;

  BoardSlotState({required this.cardId, required this.x, required this.y});

  factory BoardSlotState.fromJson(Map<String, dynamic> json) {
    return BoardSlotState(
      cardId: json['cardId']?.toString(),
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
    );
  }
}

class GameState {
  final String id;
  final List<PlayerState> players;
  final List<BoardSlotState> board;
  final String currentPlayerId;

  GameState({
    required this.id,
    required this.players,
    required this.board,
    required this.currentPlayerId,
  });

  factory GameState.empty() {
    return GameState(id: '', players: const [], board: const [], currentPlayerId: '');
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final playersJson = (json['players'] as List?) ?? [];
    final boardJson = (json['board'] as List?) ?? [];
    return GameState(
      id: json['id']?.toString() ?? '',
      players: playersJson.map((e) => PlayerState.fromJson(e as Map<String, dynamic>)).toList(),
      board: boardJson.map((e) => BoardSlotState.fromJson(e as Map<String, dynamic>)).toList(),
      currentPlayerId: json['currentPlayerId']?.toString() ?? '',
    );
  }
}

