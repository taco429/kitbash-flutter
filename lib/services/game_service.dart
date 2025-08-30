import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class GameService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8080';
  WebSocketChannel? _channel;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // REST API methods
  Future<List<dynamic>> findGames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/games'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load games');
      }
    } catch (e) {
      debugPrint('Error finding games: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createGame() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/lobbies'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'max_players': 2,
          'host': 'Player ${DateTime.now().millisecondsSinceEpoch % 1000}',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final gameData = json.decode(response.body);
        // Connect to WebSocket for game
        await connectToGame(gameData['id']);
        return gameData;
      } else {
        throw Exception('Failed to create game: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating game: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> joinGame(String gameId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/games/$gameId/join'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final gameData = json.decode(response.body);
        // Connect to WebSocket for game
        await connectToGame(gameId);
        return gameData;
      } else {
        throw Exception('Failed to join game');
      }
    } catch (e) {
      debugPrint('Error joining game: $e');
      return null;
    }
  }

  // WebSocket methods
  Future<void> connectToGame(String gameId) async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://localhost:8080/ws/game/$gameId'),
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
