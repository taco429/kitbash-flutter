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

    setState(() {
      _availableGames = games;
      _isLoading = false;
    });
  }

  Future<void> _joinGame(String gameId) async {
    final gameService = context.read<GameService>();
    final gameData = await gameService.joinGame(gameId);

    if (gameData != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(gameId: gameId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitbash CCG'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
            ElevatedButton(
              onPressed: () {
                // TODO: Implement deck builder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deck Builder coming soon!')),
                );
              },
              child: const Text('Deck Builder'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGames,
              child: const Text('Find Games'),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_availableGames.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _availableGames.length,
                  itemBuilder: (context, index) {
                    final game = _availableGames[index];
                    return ListTile(
                      title: Text('Game ${game['id']}'),
                      subtitle: Text('Players: ${game['players']}/2'),
                      trailing: ElevatedButton(
                        onPressed: () => _joinGame(game['id']),
                        child: const Text('Join'),
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