import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_lobby_screen.dart';
import 'game_screen.dart';
import '../services/game_service.dart';
import '../widgets/deck_selector.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _createGame() async {
    final gameService = context.read<GameService>();
    final gameData = await gameService.createGame();

    if (gameData != null && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Game created: ${gameData['name']}')),
      );

      // Navigate to the game
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(gameId: gameData['id']),
        ),
      );
    } else if (mounted) {
      // Show error message
      final error = gameService.lastError ?? 'Failed to create game';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _createCpuGame() async {
    final gameService = context.read<GameService>();
    final gameData = await gameService.createCpuGame();

    if (gameData != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CPU Game created: ${gameData['name']}')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameScreen(gameId: gameData['id']),
        ),
      );
    } else if (mounted) {
      final error = gameService.lastError ?? 'Failed to create CPU game';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Deck Selector Section
              const DeckSelector(),
              const SizedBox(height: 40),

              // Game Action Buttons
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _createGame,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text('Create Game'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createCpuGame,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text('Play vs CPU'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement deck builder
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Deck Builder coming soon!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text('Deck Builder'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameLobbyScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text('Find Games'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
