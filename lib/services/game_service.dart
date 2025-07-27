import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class GameService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8080';
  WebSocketChannel? _channel;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  String? _authToken;
  String? get authToken => _authToken;

  // REST API methods
  
  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error checking health: $e');
      return false;
    }
  }
  
  // List all active games
  Future<List<dynamic>> findGames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/games'));
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
  
  // Create a new game
  Future<Map<String, dynamic>?> createGame(String gameName, int maxPlayers) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/games'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': gameName,
          'maxPlayers': maxPlayers,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create game: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating game: $e');
      return null;
    }
  }
  
  // Get specific game info
  Future<Map<String, dynamic>?> getGameInfo(String gameId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/games/$gameId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get game info');
      }
    } catch (e) {
      debugPrint('Error getting game info: $e');
      return null;
    }
  }

  // Join a game with player name
  Future<Map<String, dynamic>?> joinGame(String gameId, String playerName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/games/$gameId/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'playerName': playerName,
        }),
      );
      
      if (response.statusCode == 200) {
        final gameData = json.decode(response.body);
        // Store auth token if provided
        if (gameData['token'] != null) {
          _authToken = gameData['token'];
        }
        // Connect to WebSocket for game
        await connectToGame(gameId);
        return gameData;
      } else {
        throw Exception('Failed to join game: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error joining game: $e');
      return null;
    }
  }

  // WebSocket methods
  Future<void> connectToGame(String gameId) async {
    try {
      // Build WebSocket URL with optional auth token
      String wsUrl = 'ws://localhost:8080/ws/game/$gameId';
      if (_authToken != null) {
        wsUrl += '?token=$_authToken';
      }
      
      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
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