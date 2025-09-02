import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

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
  final int currentTurn;
  final int turnCount;

  GameState({
    required this.id,
    required this.status,
    required this.commandCenters,
    required this.currentTurn,
    required this.turnCount,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      id: json['id'] ?? '',
      status: json['status'] ?? 'waiting',
      commandCenters: (json['commandCenters'] as List<dynamic>?)
              ?.map((cc) => CommandCenter.fromJson(cc))
              .toList() ??
          [],
      currentTurn: json['currentTurn'] ?? 0,
      turnCount: json['turnCount'] ?? 0,
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
