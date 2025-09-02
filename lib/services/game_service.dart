import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class GameService extends ChangeNotifier {
  // Change this to your backend server IP address
  static const String baseUrl = 'http://192.168.4.156:8080';
  static const String wsUrl = 'ws://192.168.4.156:8080';
  WebSocketChannel? _channel;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _lastError;
  String? get lastError => _lastError;

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
      // Handle different message types here
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
