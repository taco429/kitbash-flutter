import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../models/card_instance.dart';
import '../models/card_drag_payload.dart';
import 'granular_game_state.dart';
import '../models/planned_play.dart';

class RoundDiscardSummary {
  final int roundNumber;
  final Map<int, int> playerToDiscardCount;

  RoundDiscardSummary({
    required this.roundNumber,
    Map<int, int>? playerToDiscardCount,
  }) : playerToDiscardCount = playerToDiscardCount ?? {0: 0, 1: 0};

  RoundDiscardSummary copyWith({
    Map<int, int>? playerToDiscardCount,
  }) {
    return RoundDiscardSummary(
      roundNumber: roundNumber,
      playerToDiscardCount:
          playerToDiscardCount ?? Map<int, int>.from(this.playerToDiscardCount),
    );
  }
}

class CommandCenter {
  final int playerIndex;
  final int topLeftRow;
  final int topLeftCol;
  final int health;
  final int maxHealth;

  CommandCenter({
    required this.playerIndex,
    required this.topLeftRow,
    required this.topLeftCol,
    required this.health,
    required this.maxHealth,
  });

  factory CommandCenter.fromJson(Map<String, dynamic> json) {
    return CommandCenter(
      playerIndex: json['playerIndex'] ?? 0,
      topLeftRow: json['topLeftRow'] ?? 0,
      topLeftCol: json['topLeftCol'] ?? 0,
      health: json['health'] ?? 100,
      maxHealth: json['maxHealth'] ?? 100,
    );
  }

  bool get isDestroyed => health <= 0;
  double get healthPercentage => maxHealth > 0 ? health / maxHealth : 0.0;
}

class GameState {
  final String id;
  final String status;
  final List<CommandCenter> commandCenters;
  final List<PlayerBattleState> playerStates;
  final int currentTurn;
  final String currentPhase;
  final DateTime? phaseStartTime;
  final int turnCount;
  final int? winnerPlayerIndex;
  final Map<int, bool> playerChoicesLocked;
  final Map<int, List<PlannedPlay>> plannedPlays;

  GameState({
    required this.id,
    required this.status,
    required this.commandCenters,
    required this.playerStates,
    required this.currentTurn,
    required this.currentPhase,
    this.phaseStartTime,
    required this.turnCount,
    this.winnerPlayerIndex,
    Map<int, bool>? playerChoicesLocked,
    Map<int, List<PlannedPlay>>? plannedPlays,
  })  : playerChoicesLocked = playerChoicesLocked ?? {0: false, 1: false},
        plannedPlays = plannedPlays ?? {0: const [], 1: const []};

  factory GameState.fromJson(Map<String, dynamic> json) {
    // Parse player choices locked state
    final Map<int, bool> playerChoicesLocked = {0: false, 1: false};
    if (json['playerChoicesLocked'] != null) {
      final locked = json['playerChoicesLocked'];
      if (locked is Map) {
        locked.forEach((key, value) {
          final playerIndex = key is String ? int.tryParse(key) : key;
          if (playerIndex != null) {
            playerChoicesLocked[playerIndex] = value == true;
          }
        });
      }
    }

    // Parse phase start time
    DateTime? phaseStartTime;
    if (json['phaseStartTime'] != null) {
      try {
        phaseStartTime = DateTime.parse(json['phaseStartTime']);
      } catch (_) {
        // Ignore parse errors
      }
    }

    return GameState(
      id: json['id'] ?? '',
      status: json['status'] ?? 'waiting',
      commandCenters: (json['commandCenters'] as List<dynamic>?)
              ?.map((cc) => CommandCenter.fromJson(cc))
              .toList() ??
          [],
      playerStates: (json['playerStates'] as List<dynamic>?)
              ?.map((ps) => PlayerBattleState.fromJson(ps))
              .toList() ??
          [],
      currentTurn: json['currentTurn'] ?? 0,
      currentPhase: json['currentPhase'] ?? 'draw_income',
      phaseStartTime: phaseStartTime,
      turnCount: json['turnCount'] ?? 0,
      winnerPlayerIndex: json['winnerPlayerIndex'],
      playerChoicesLocked: playerChoicesLocked,
      plannedPlays: _parsePlannedPlays(json['plannedPlays']),
    );
  }

  static Map<int, List<PlannedPlay>> _parsePlannedPlays(dynamic value) {
    final Map<int, List<PlannedPlay>> result = {0: const [], 1: const []};
    if (value is Map) {
      value.forEach((k, v) {
        int? idx;
        if (k is int) {
          idx = k;
        } else if (k is String) {
          idx = int.tryParse(k);
        }
        if (idx == null) {
          return;
        }
        if (v is List) {
          final list = <PlannedPlay>[];
          for (final e in v) {
            if (e is Map<String, dynamic>) {
              list.add(PlannedPlay.fromJson(e));
            } else if (e is Map) {
              list.add(PlannedPlay.fromJson(e.cast<String, dynamic>()));
            }
          }
          result[idx] = list;
        }
      });
    }
    return result;
  }

  /// Determines if the game is over (one player has won)
  bool get isGameOver => status == 'finished' || winnerPlayerIndex != null;

  /// Gets the winner player index by checking which player still has alive command centers
  int? get computedWinner {
    if (winnerPlayerIndex != null) return winnerPlayerIndex;

    final alivePlayers = <int>{};
    for (final cc in commandCenters) {
      if (!cc.isDestroyed) {
        alivePlayers.add(cc.playerIndex);
      }
    }

    // If only one player has alive command centers, they win
    if (alivePlayers.length == 1) {
      return alivePlayers.first;
    }

    // If no players have alive command centers, it's a draw (return null)
    // If multiple players still have alive command centers, game is not over
    return null;
  }

  /// Gets the winner name for display
  String getWinnerName(int playerIndex) {
    return 'Player ${playerIndex + 1}';
  }

  /// Check if all players have locked in their choices for this turn
  bool get allPlayersLocked {
    return playerChoicesLocked.values.every((locked) => locked);
  }

  /// Check if a specific player has locked their choice
  bool isPlayerLocked(int playerIndex) {
    return playerChoicesLocked[playerIndex] ?? false;
  }
}

class PlayerBattleState {
  final int playerIndex;
  final String deckId;
  final List<CardInstance> hand; // List of CardInstances
  final int deckCount;
  final List<CardInstance> drawPile; // Cards remaining in deck
  final List<CardInstance> discardPile; // Cards in discard pile

  const PlayerBattleState({
    required this.playerIndex,
    required this.deckId,
    required this.hand,
    required this.deckCount,
    this.drawPile = const [],
    this.discardPile = const [],
  });

  factory PlayerBattleState.fromJson(Map<String, dynamic> json) {
    final rawHand = json['hand'];
    List<CardInstance> handInstances = [];
    if (rawHand is List) {
      handInstances = rawHand.map((e) {
        if (e is Map<String, dynamic>) {
          return CardInstance.fromJson(e);
        } else if (e is String) {
          // Backwards compatibility: if we get just a string, treat it as cardId with no instanceId
          return CardInstance(instanceId: e, cardId: e);
        }
        return CardInstance(instanceId: '', cardId: e.toString());
      }).toList();
    }

    // Parse draw pile
    List<CardInstance> drawPileInstances = [];
    final rawDrawPile = json['drawPile'];
    if (rawDrawPile is List) {
      drawPileInstances = rawDrawPile.map((e) {
        if (e is Map<String, dynamic>) {
          return CardInstance.fromJson(e);
        }
        return CardInstance(instanceId: '', cardId: e.toString());
      }).toList();
    }

    // Parse discard pile
    List<CardInstance> discardPileInstances = [];
    final rawDiscardPile = json['discardPile'];
    if (rawDiscardPile is List) {
      discardPileInstances = rawDiscardPile.map((e) {
        if (e is Map<String, dynamic>) {
          return CardInstance.fromJson(e);
        }
        return CardInstance(instanceId: '', cardId: e.toString());
      }).toList();
    }

    return PlayerBattleState(
      playerIndex: json['playerIndex'] ?? 0,
      deckId: json['deckId']?.toString() ?? '',
      hand: handInstances,
      deckCount: json['deckCount'] ?? 0,
      drawPile: drawPileInstances,
      discardPile: discardPileInstances,
    );
  }
}

class GameService extends ChangeNotifier {
  // Change this to your backend server IP address
  static const String baseUrl = 'http://192.168.4.156:8080';
  static const String wsUrl = 'ws://192.168.4.156:8080';
  WebSocketChannel? _channel;

  // Granular notifiers for specific state aspects
  late final ConnectionStateNotifier connectionState;
  late final GameStateNotifier gameStateNotifier;
  final discardSelection = DiscardSelectionNotifier();
  final cardPreview = CardPreviewNotifier();
  final cardPlacement = CardPlacementNotifier();
  final lockState = LockStateNotifier();
  final discardLog = DiscardLogNotifier();
  final targetValidation = TargetValidationNotifier();
  final playLog = PlayLogNotifier();

  GameService() {
    connectionState = ConnectionStateNotifier();
    gameStateNotifier = GameStateNotifier();

    // Listen to gameStateNotifier changes and propagate them
    gameStateNotifier.addListener(_onGameStateChanged);
    // Also listen to discard selection changes so hand UI updates immediately
    discardSelection.addListener(_onDiscardSelectionChanged);
  }

  void _onGameStateChanged() {
    // Notify GameService listeners when game state changes
    notifyListeners();
  }

  void _onDiscardSelectionChanged() {
    // Rebuild dependents (e.g., hand UI) when discard selection changes
    notifyListeners();
  }

  bool get isConnected => connectionState.value;
  String? get lastError => gameStateNotifier.lastError;
  GameState? get gameState => gameStateNotifier.gameState;

  int _currentPlayerIndex =
      0; // Default to player 0, should be set when joining game
  int get currentPlayerIndex => _currentPlayerIndex;

  // Delegate to granular notifiers
  RoundDiscardSummary _ensureRoundSummary(int round) {
    return discardLog.ensureRoundSummary(round);
  }

  void _recordDiscardEvent(
      {required int round, required int playerIndex, required int count}) {
    discardLog.recordDiscardEvent(
      round: round,
      playerIndex: playerIndex,
      count: count,
    );
  }

  // Delegate discard tracking to granular notifier
  Set<String> get cardsToDiscard => discardSelection.value;

  bool isCardMarkedForDiscard(String instanceId) =>
      discardSelection.isCardMarkedForDiscard(instanceId);

  void toggleCardDiscard(String instanceId) {
    discardSelection.toggleCardDiscard(instanceId);
  }

  void clearDiscardSelection() {
    discardSelection.clearDiscardSelection();
  }

  // Delegate placement/preview to granular notifiers
  CardDragPayload? get pendingPlacement => cardPlacement.value;
  CardDragPayload? get previewPayload => cardPreview.value;

  void beginCardPlacement(CardDragPayload payload) {
    cardPlacement.beginCardPlacement(payload);
  }

  void showCardPreview(CardDragPayload payload) {
    cardPreview.showCardPreview(payload);
  }

  void clearCardPreview() {
    cardPreview.clearCardPreview();
  }

  void clearCardPlacement() {
    cardPlacement.clearCardPlacement();
  }

  // REST API methods
  Future<List<dynamic>> findGames() async {
    try {
      gameStateNotifier.setError(null);
      debugPrint('GameService: Finding games at $baseUrl/api/games');

      final response = await http.get(
        Uri.parse('$baseUrl/api/games'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('GameService: Find games response: ${response.statusCode}');
      debugPrint('GameService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final games = json.decode(response.body);
        debugPrint('GameService: Found ${games.length} games');
        return games;
      } else {
        final error =
            'Failed to load games: ${response.statusCode} ${response.reasonPhrase}';
        gameStateNotifier.setError(error);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error finding games: $e';
      gameStateNotifier.setError(error);
      debugPrint('GameService: $error');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createGame() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lobbies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': 'Quick Match',
          'hostName': 'Player ${DateTime.now().millisecondsSinceEpoch % 1000}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final gameData = json.decode(response.body);
        // Connect to WebSocket for game
        await connectToGame(gameData['id']);

        // Also request game state via REST to ensure we have initial state
        await getGameState(gameData['id']);

        return gameData;
      } else {
        final error =
            'Failed to create game: ${response.statusCode} ${response.reasonPhrase} ${response.body}';
        gameStateNotifier.setError(error);
        throw Exception(lastError);
      }
    } catch (e) {
      debugPrint('Error creating game: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createCpuGame() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/games/cpu'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final gameData = json.decode(response.body);
        await connectToGame(gameData['id']);

        // Also request game state via REST to ensure we have initial state
        await getGameState(gameData['id']);

        return gameData;
      } else {
        final error =
            'Failed to create CPU game: ${response.statusCode} ${response.reasonPhrase} ${response.body}';
        gameStateNotifier.setError(error);
        throw Exception(lastError);
      }
    } catch (e) {
      debugPrint('Error creating CPU game: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinGame(String gameId) async {
    try {
      gameStateNotifier.setError(null);
      debugPrint(
        'GameService: Joining game $gameId at $baseUrl/api/games/$gameId/join',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/api/games/$gameId/join'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('GameService: Join game response: ${response.statusCode}');
      debugPrint('GameService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final gameData = json.decode(response.body);
        debugPrint('GameService: Successfully joined game: ${gameData['id']}');

        // Connect to WebSocket for game
        await connectToGame(gameId);

        // Also request game state via REST to ensure we have initial state
        await getGameState(gameId);

        return gameData;
      } else {
        final error =
            'Failed to join game: ${response.statusCode} ${response.reasonPhrase}';
        gameStateNotifier.setError(error);
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error joining game: $e';
      gameStateNotifier.setError(error);
      debugPrint('GameService: $error');
      return null;
    }
  }

  // WebSocket methods
  Future<void> connectToGame(String gameId) async {
    try {
      debugPrint('Connecting to game WebSocket: $wsUrl/ws/game/$gameId');
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/game/$gameId'),
      );

      connectionState.setConnected(true);
      debugPrint('WebSocket connected successfully');

      _channel!.stream.listen(
        (message) {
          handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          disconnect();
        },
        onDone: () {
          disconnect();
        },
      );
    } catch (e) {
      debugPrint('Error connecting to game: $e');
      connectionState.setConnected(false);
    }
  }

  void handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);
      debugPrint('Received: $data');

      final messageType = data['type'];
      if (messageType == 'game_state') {
        final gameStateData = data['gameState'];
        if (gameStateData != null) {
          final newState = GameState.fromJson(gameStateData);
          gameStateNotifier.updateGameState(newState);
          // Update lock states separately
          lockState.setPlayerLocked(0, newState.isPlayerLocked(0));
          lockState.setPlayerLocked(1, newState.isPlayerLocked(1));
          debugPrint(
            'Updated game state: ${newState.status}, Command Centers: ${newState.commandCenters.length}, Player States: ${newState.playerStates.length}',
          );
          // Debug: Check if player states have hand data
          for (var ps in newState.playerStates) {
            debugPrint(
                'Player ${ps.playerIndex}: hand=${ps.hand.length}, deck=${ps.deckCount}');
          }
        }
      } else if (messageType == 'target_validation') {
        final result = TargetValidationResult(
          row: (data['row'] is int)
              ? data['row']
              : (data['row'] as num?)?.toInt() ?? 0,
          col: (data['col'] is int)
              ? data['col']
              : (data['col'] as num?)?.toInt() ?? 0,
          cardInstanceId: (data['cardInstanceId'] ?? '').toString(),
          valid: data['valid'] == true,
          reason: data['reason']?.toString(),
        );
        targetValidation.setResult(result);
      } else if (messageType == 'player_locked') {
        // Handle player lock update
        final playerIndex = data['playerIndex'];
        if (playerIndex != null && gameState != null) {
          gameState!.playerChoicesLocked[playerIndex] = true;
          lockState.setPlayerLocked(playerIndex, true);
          debugPrint('Player $playerIndex locked their choice');
        }
      } else if (messageType == 'turn_advanced') {
        // Handle turn advancement when both players have locked
        final newTurn = data['newTurn'];
        final gameStateData = data['gameState'];
        if (newTurn != null && gameState != null) {
          // If game state is included, use it (it should have reset lock states)
          if (gameStateData != null) {
            final newState = GameState.fromJson(gameStateData);
            gameStateNotifier.updateGameState(newState);
            lockState.setPlayerLocked(0, false);
            lockState.setPlayerLocked(1, false);
            debugPrint('Updated game state from turn advancement');
          } else {
            // Otherwise just reset lock states locally
            gameState!.playerChoicesLocked[0] = false;
            gameState!.playerChoicesLocked[1] = false;
            lockState.setPlayerLocked(0, false);
            lockState.setPlayerLocked(1, false);
          }
          debugPrint('Turn advanced to $newTurn');
        }
      } else if (messageType == 'phase_changed') {
        // Handle phase change notification
        final newPhase = data['phase'];
        final gameStateData = data['gameState'];
        if (newPhase != null) {
          debugPrint('Phase changed to $newPhase');

          // When entering reveal_resolve phase, process discards
          if (newPhase == 'reveal_resolve' && cardsToDiscard.isNotEmpty) {
            // The backend will handle moving cards to discard pile
            // Clear local discard selection
            clearDiscardSelection();
          }

          // If game state is included in the message, use it directly
          if (gameStateData != null) {
            final newState = GameState.fromJson(gameStateData);
            gameStateNotifier.updateGameState(newState);
            lockState.setPlayerLocked(0, newState.isPlayerLocked(0));
            lockState.setPlayerLocked(1, newState.isPlayerLocked(1));
            debugPrint('Updated game state from phase change');
          } else {
            // Only request game state if not included in the message
            requestGameState();
          }
        }
      } else if (messageType == 'resolution_timeline') {
        final roundRaw = data['round'];
        int? round;
        if (roundRaw is int) {
          round = roundRaw;
        } else if (roundRaw is double) {
          round = roundRaw.toInt();
        } else if (roundRaw is String) {
          round = int.tryParse(roundRaw);
        }
        if (round != null) {
          debugPrint('Resolution timeline received for round $round');
          // Ensure there is a summary entry for this round (zero counts by default)
          _ensureRoundSummary(round);

          // Parse events for discard counts
          final events = data['events'];
          if (events is List) {
            for (final evt in events) {
              if (evt is Map) {
                final type = evt['type'];
                if (type == 'discard') {
                  final evtData = evt['data'];
                  int? playerIdx;
                  int count = 0;
                  if (evtData is Map) {
                    final pi = evtData['playerIndex'];
                    if (pi is int) {
                      playerIdx = pi;
                    } else if (pi is double) {
                      playerIdx = pi.toInt();
                    } else if (pi is String) {
                      playerIdx = int.tryParse(pi);
                    }
                    final c = evtData['count'];
                    if (c is int) {
                      count = c;
                    } else if (c is double) {
                      count = c.toInt();
                    } else if (c is String) {
                      count = int.tryParse(c) ?? 0;
                    }
                  }
                  if (playerIdx != null) {
                    _recordDiscardEvent(
                        round: round, playerIndex: playerIdx, count: count);
                  }
                } else if (type == 'effect') {
                  final evtData = evt['data'];
                  if (evtData is Map) {
                    final action = evtData['action'];
                    if (action == 'play_card' || evtData['cardId'] != null) {
                      final playerIdx =
                          (evtData['playerIndex'] as num?)?.toInt() ?? 0;
                      final cardId = (evtData['cardId'] ?? '').toString();
                      final instanceId =
                          (evtData['cardInstanceId'] ?? '').toString();
                      final row = (evtData['row'] as num?)?.toInt() ?? 0;
                      final col = (evtData['col'] as num?)?.toInt() ?? 0;
                      playLog.add(PlayEventEntry(
                        round: round,
                        playerIndex: playerIdx,
                        cardId: cardId,
                        cardInstanceId: instanceId,
                        row: row,
                        col: col,
                      ));
                    }
                  }
                }
              }
            }
          }
        } else {
          debugPrint(
              'Resolution timeline received with unknown round: ${data['round']}');
        }
        // After resolution/upkeep, fetch the latest authoritative state
        requestGameState();
      } else if (messageType == 'player_joined') {
        // Set the current player index when joining
        final playerIndex = data['playerIndex'];
        if (playerIndex != null) {
          _currentPlayerIndex = playerIndex;
          debugPrint('Joined as player $playerIndex');
        }
      }

      // Most state is now handled by specific notifiers
      // But we still need to notify for currentPlayerIndex changes
      if (messageType == 'player_joined') {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  void sendAction(Map<String, dynamic> action) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(json.encode(action));
    }
  }

  // Validate a target tile for a card via WS
  void validateTarget({
    required int playerIndex,
    required String cardInstanceId,
    required int row,
    required int col,
    String? cardId,
  }) {
    sendAction({
      'type': 'validate_target',
      'playerIndex': playerIndex,
      'cardInstanceId': cardInstanceId,
      'row': row,
      'col': col,
      if (cardId != null) 'cardId': cardId,
    });
  }

  // Deal damage to a command center
  Future<bool> dealDamage(String gameId, int playerIndex, int damage) async {
    try {
      gameStateNotifier.setError(null);

      final response = await http.post(
        Uri.parse('$baseUrl/api/games/$gameId/damage'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'playerIndex': playerIndex,
          'damage': damage,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint('Damage dealt successfully: ${result['destroyed']}');

        // Also send via WebSocket for real-time updates
        sendAction({
          'type': 'deal_damage',
          'playerIndex': playerIndex,
          'damage': damage,
        });

        return result['destroyed'] ?? false;
      } else {
        gameStateNotifier
            .setError('Failed to deal damage: ${response.statusCode}');
        throw Exception(lastError);
      }
    } catch (e) {
      gameStateNotifier.setError('Error dealing damage: $e');
      debugPrint(lastError);
      return false;
    }
  }

  // Get current game state
  Future<GameState?> getGameState(String gameId) async {
    try {
      gameStateNotifier.setError(null);

      final response = await http.get(
        Uri.parse('$baseUrl/api/games/$gameId/state'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final gameStateData = json.decode(response.body);
        final newState = GameState.fromJson(gameStateData);
        gameStateNotifier.updateGameState(newState);
        // Update lock states separately
        lockState.setPlayerLocked(0, newState.isPlayerLocked(0));
        lockState.setPlayerLocked(1, newState.isPlayerLocked(1));
        return gameState;
      } else {
        final error = 'Failed to get game state: ${response.statusCode}';
        gameStateNotifier.setError(error);
        throw Exception(error);
      }
    } catch (e) {
      gameStateNotifier.setError('Error getting game state: $e');
      debugPrint('Error getting game state: $e');
      return null;
    }
  }

  // Request game state via WebSocket
  void requestGameState() {
    sendAction({'type': 'get_game_state'});
  }

  /// Stage a play-card action locally and notify the backend (placeholder)
  void stagePlayCard(
    String gameId,
    int playerIndex,
    String cardInstanceId,
    int row,
    int col,
  ) {
    debugPrint(
        'Stage play card instance=$cardInstanceId at ($row,$col) by player $playerIndex');
    sendAction({
      'type': 'stage_play_card',
      'gameId': gameId,
      'playerIndex': playerIndex,
      'cardInstanceId': cardInstanceId,
      'row': row,
      'col': col,
    });
    // Future: Update local optimistic UI, e.g. mark tile as targeted
  }

  // Lock in player's choices for the current turn
  Future<bool> lockPlayerChoice(String gameId, int playerIndex) async {
    try {
      gameStateNotifier.setError(null);

      // Send discard information along with lock choice if any cards are marked
      final discardList = cardsToDiscard.toList();

      // Debug: Log what we're sending
      debugPrint(
          'Locking player $playerIndex with ${discardList.length} cards to discard');
      if (discardList.isNotEmpty) {
        debugPrint('Cards to discard: $discardList');
      }

      // Update local state optimistically
      if (gameState != null) {
        gameState!.playerChoicesLocked[playerIndex] = true;
        lockState.setPlayerLocked(playerIndex, true);
      }

      // Send lock choice via WebSocket for real-time updates
      final lockMessage = {
        'type': 'lock_choice',
        'playerIndex': playerIndex,
        'gameId': gameId,
        'discardCards': discardList,
      };
      debugPrint('Sending lock message: ${json.encode(lockMessage)}');
      sendAction(lockMessage);

      // Try to send to backend via REST as well (optional, may not be implemented yet)
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/api/games/$gameId/lock-choice'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'playerIndex': playerIndex,
              }),
            )
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          debugPrint(
              'Player $playerIndex locked their choice (REST confirmed)');
        } else if (response.statusCode == 404) {
          // Endpoint not implemented yet, but WebSocket should handle it
          debugPrint(
              'Lock choice endpoint not implemented, using WebSocket only');
        }
      } catch (restError) {
        // REST endpoint might not be implemented, rely on WebSocket
        debugPrint(
            'Lock choice REST failed (may not be implemented): $restError');
      }

      debugPrint('Player $playerIndex locked their choice');

      // Check if both players have locked and simulate turn advancement
      if (gameState != null && gameState!.allPlayersLocked) {
        debugPrint('Both players locked - turn should advance');
      }

      return true;
    } catch (e) {
      // Revert optimistic update on error
      if (gameState != null) {
        gameState!.playerChoicesLocked[playerIndex] = false;
        lockState.setPlayerLocked(playerIndex, false);
      }
      gameStateNotifier.setError('Error locking choice: $e');
      debugPrint(lastError);
      return false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    connectionState.setConnected(false);
  }

  @override
  void dispose() {
    gameStateNotifier.removeListener(_onGameStateChanged);
    discardSelection.removeListener(_onDiscardSelectionChanged);
    disconnect();
    super.dispose();
  }
}
