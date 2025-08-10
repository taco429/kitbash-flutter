import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import 'game_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<dynamic> _availableGames = [];
  bool _isLoading = false;
  bool _serverHealthy = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkServerHealth();
    _loadGames();
    
    // Set up auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkServerHealth();
        _loadGames(showLoading: false);
      }
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkServerHealth() async {
    final gameService = context.read<GameService>();
    final healthy = await gameService.checkHealth();
    if (mounted) {
      setState(() {
        _serverHealthy = healthy;
      });
    }
  }

  Future<void> _loadGames({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    final gameService = context.read<GameService>();
    final games = await gameService.findGames();

    if (mounted) {
      setState(() {
        _availableGames = games;
        _isLoading = false;
      });
    }
  }

  Future<void> _createGame() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String gameName = '';
        int maxPlayers = 2;
        
        return AlertDialog(
          title: const Text('Create New Game'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Game Name',
                      hintText: 'Enter game name',
                    ),
                    onChanged: (value) => gameName = value,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Max Players: '),
                      DropdownButton<int>(
                        value: maxPlayers,
                        items: List.generate(7, (i) => i + 2)
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.toString()),
                                ),)
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => maxPlayers = value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (gameName.isNotEmpty) {
                  Navigator.pop(context, {
                    'name': gameName,
                    'maxPlayers': maxPlayers,
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final gameService = context.read<GameService>();
      final gameData = await gameService.createGame(
        result['name'],
        result['maxPlayers'],
      );
      
      if (gameData != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Game created successfully!')),
        );
        _loadGames(); // Refresh the game list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create game')),
        );
      }
    }
  }

  Future<void> _joinGame(String gameId) async {
    final playerName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String name = '';
        
        return AlertDialog(
          title: const Text('Join Game'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your player name',
            ),
            onChanged: (value) => name = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (playerName != null && playerName.isNotEmpty) {
      final gameService = context.read<GameService>();
      final gameData = await gameService.joinGame(gameId, playerName);

      if (gameData != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(gameId: gameId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join game')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitbash CCG'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                _serverHealthy ? 'Server: Online' : 'Server: Offline',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _serverHealthy ? Colors.green : Colors.red,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Kitbash CCG',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement deck builder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deck Builder coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.style),
                  label: const Text('Deck Builder'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _serverHealthy ? _createGame : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Game'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadGames,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Games'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Available Games',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_availableGames.isEmpty)
              Column(
                children: [
                  const Icon(Icons.games_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _serverHealthy 
                      ? 'No active games. Create one to get started!' 
                      : 'Cannot connect to server',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _availableGames.length,
                  itemBuilder: (context, index) {
                    final game = _availableGames[index];
                    final currentPlayers = game['currentPlayers'] ?? game['players'] ?? 0;
                    final maxPlayers = game['maxPlayers'] ?? 2;
                    final gameName = game['name'] ?? 'Game ${game['id']}';
                    final isFull = currentPlayers >= maxPlayers;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isFull ? Colors.grey : Colors.green,
                          child: const Icon(
                            Icons.gamepad,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(gameName),
                        subtitle: Text(
                          'Players: $currentPlayers/$maxPlayers • ID: ${game['id']}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: isFull ? null : () => _joinGame(game['id'].toString()),
                          child: Text(isFull ? 'Full' : 'Join'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 