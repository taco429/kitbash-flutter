import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import 'game_screen.dart';

class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  List<dynamic> _availableGames = [];
  bool _isLoading = false;
  bool _isCreatingGame = false;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
    });

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
    setState(() {
      _isCreatingGame = true;
    });

    final gameService = context.read<GameService>();
    final gameData = await gameService.createGame();

    if (mounted) {
      setState(() {
        _isCreatingGame = false;
      });

      if (gameData != null) {
        // Navigate to the game screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(gameId: gameData['id']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create game')),
        );
      }
    }
  }

  Future<void> _joinGame(String gameId) async {
    final gameService = context.read<GameService>();
    final gameData = await gameService.joinGame(gameId);

    if (gameData != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(gameId: gameId),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join game')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGames,
        child: Column(
          children: [
            // Header section with create game button
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Join a game or create your own!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCreatingGame ? null : _createGame,
                      icon: _isCreatingGame
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isCreatingGame ? 'Creating...' : 'Create New Game'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Games list section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _availableGames.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.games_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No games available',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a new game to get started!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextButton.icon(
                                onPressed: _loadGames,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _availableGames.length,
                          itemBuilder: (context, index) {
                            final game = _availableGames[index];
                            final playerCount = game['players'] ?? game['player_count'] ?? 1;
                            final maxPlayers = game['max_players'] ?? 2;
                            final gameStatus = game['status'] ?? 'waiting';
                            final hostName = game['host'] ?? 'Unknown';
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: gameStatus == 'waiting'
                                      ? Colors.green
                                      : Colors.orange,
                                  child: Icon(
                                    gameStatus == 'waiting'
                                        ? Icons.hourglass_empty
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  'Game ${game['id']?.substring(0, 8) ?? index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Host: $hostName'),
                                    Text('Players: $playerCount/$maxPlayers'),
                                    Text(
                                      'Status: ${gameStatus == 'waiting' ? 'Waiting for players' : 'In progress'}',
                                      style: TextStyle(
                                        color: gameStatus == 'waiting'
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: playerCount < maxPlayers
                                    ? ElevatedButton(
                                        onPressed: () => _joinGame(game['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Join'),
                                      )
                                    : const Chip(
                                        label: Text('Full'),
                                        backgroundColor: Colors.grey,
                                      ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadGames,
        tooltip: 'Refresh games',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
