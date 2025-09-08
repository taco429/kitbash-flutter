import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../models/card_instance.dart';

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
  }) : playerChoicesLocked = playerChoicesLocked ?? {0: false, 1: false};

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
    );
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

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _lastError;
  String? get lastError => _lastError;

  GameState? _gameState;
  GameState? get gameState => _gameState;

  int _currentPlayerIndex =
      0; // Default to player 0, should be set when joining game
  int get currentPlayerIndex => _currentPlayerIndex;

  // Track cards marked for discard during planning phase (using instance IDs)
  final Set<String> _cardsToDiscard = {};
  Set<String> get cardsToDiscard => _cardsToDiscard;

  bool isCardMarkedForDiscard(String instanceId) =>
      _cardsToDiscard.contains(instanceId);

  void toggleCardDiscard(String instanceId) {
    if (_cardsToDiscard.contains(instanceId)) {
      _cardsToDiscard.remove(instanceId);
    } else {
      _cardsToDiscard.add(instanceId);
    }
    notifyListeners();
  }

  void clearDiscardSelection() {
    _cardsToDiscard.clear();
    notifyListeners();
  }

  // REST API methods
  Future<List<dynamic>> findGames() async {
    try {
      _lastError = null;
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
        _lastError = error;
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error finding games: $e';
      _lastError = error;
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
        return gameData;
      } else {
        _lastError =
            'Failed to create game: ${response.statusCode} ${response.reasonPhrase} ${response.body}';
        throw Exception(_lastError);
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
        return gameData;
      } else {
        _lastError =
            'Failed to create CPU game: ${response.statusCode} ${response.reasonPhrase} ${response.body}';
        throw Exception(_lastError);
      }
    } catch (e) {
      debugPrint('Error creating CPU game: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinGame(String gameId) async {
    try {
      _lastError = null;
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
        return gameData;
      } else {
        final error =
            'Failed to join game: ${response.statusCode} ${response.reasonPhrase}';
        _lastError = error;
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error joining game: $e';
      _lastError = error;
      debugPrint('GameService: $error');
      return null;
    }
  }

  // WebSocket methods
  Future<void> connectToGame(String gameId) async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/game/$gameId'),
      );

      _isConnected = true;
      notifyListeners();

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
      _isConnected = false;
      notifyListeners();
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
          _gameState = GameState.fromJson(gameStateData);
          debugPrint(
            'Updated game state: ${_gameState?.status}, Command Centers: ${_gameState?.commandCenters.length}',
          );
        }
      } else if (messageType == 'player_locked') {
        // Handle player lock update
        final playerIndex = data['playerIndex'];
        if (playerIndex != null && _gameState != null) {
          _gameState!.playerChoicesLocked[playerIndex] = true;
          debugPrint('Player $playerIndex locked their choice');
        }
      } else if (messageType == 'turn_advanced') {
        // Handle turn advancement when both players have locked
        final newTurn = data['newTurn'];
        final gameStateData = data['gameState'];
        if (newTurn != null && _gameState != null) {
          // If game state is included, use it (it should have reset lock states)
          if (gameStateData != null) {
            _gameState = GameState.fromJson(gameStateData);
            debugPrint('Updated game state from turn advancement');
          } else {
            // Otherwise just reset lock states locally
            _gameState!.playerChoicesLocked[0] = false;
            _gameState!.playerChoicesLocked[1] = false;
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
          if (newPhase == 'reveal_resolve' && _cardsToDiscard.isNotEmpty) {
            // The backend will handle moving cards to discard pile
            // Clear local discard selection
            clearDiscardSelection();
          }

          // If game state is included in the message, use it directly
          if (gameStateData != null) {
            _gameState = GameState.fromJson(gameStateData);
            debugPrint('Updated game state from phase change');
          } else {
            // Only request game state if not included in the message
            requestGameState();
          }
        }
      } else if (messageType == 'resolution_timeline') {
        final round = data['round'];
        debugPrint('Resolution timeline received for round $round');
        // After resolution, fetch the latest authoritative state
        requestGameState();
      } else if (messageType == 'player_joined') {
        // Set the current player index when joining
        final playerIndex = data['playerIndex'];
        if (playerIndex != null) {
          _currentPlayerIndex = playerIndex;
          debugPrint('Joined as player $playerIndex');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  void sendAction(Map<String, dynamic> action) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(json.encode(action));
    }
  }

  // Deal damage to a command center
  Future<bool> dealDamage(String gameId, int playerIndex, int damage) async {
    try {
      _lastError = null;

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
        _lastError = 'Failed to deal damage: ${response.statusCode}';
        throw Exception(_lastError);
      }
    } catch (e) {
      _lastError = 'Error dealing damage: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  // Get current game state
  Future<GameState?> getGameState(String gameId) async {
    try {
      _lastError = null;

      final response = await http.get(
        Uri.parse('$baseUrl/api/games/$gameId/state'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final gameStateData = json.decode(response.body);
        _gameState = GameState.fromJson(gameStateData);
        notifyListeners();
        return _gameState;
      } else {
        _lastError = 'Failed to get game state: ${response.statusCode}';
        throw Exception(_lastError);
      }
    } catch (e) {
      _lastError = 'Error getting game state: $e';
      debugPrint(_lastError);
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
      _lastError = null;

      // Send discard information along with lock choice if any cards are marked
      final discardList = _cardsToDiscard.toList();

      // Update local state optimistically
      if (_gameState != null) {
        _gameState!.playerChoicesLocked[playerIndex] = true;
        notifyListeners();
      }

      // Send lock choice via WebSocket for real-time updates
      sendAction({
        'type': 'lock_choice',
        'playerIndex': playerIndex,
        'gameId': gameId,
        'discardCards': discardList,
      });

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
      if (_gameState != null && _gameState!.allPlayersLocked) {
        debugPrint('Both players locked - turn should advance');
      }

      return true;
    } catch (e) {
      // Revert optimistic update on error
      if (_gameState != null) {
        _gameState!.playerChoicesLocked[playerIndex] = false;
        notifyListeners();
      }
      _lastError = 'Error locking choice: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
