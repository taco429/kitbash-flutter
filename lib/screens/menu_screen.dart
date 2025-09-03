import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'game_lobby_screen.dart';
import 'game_screen.dart';
import 'collection_screen.dart';
import '../services/game_service.dart';
import '../widgets/deck_selector.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final String manifestString = await rootBundle.loadString('pubspec.yaml');
      final RegExp versionRegex = RegExp(r'version:\s*(.+)');
      final Match? match = versionRegex.firstMatch(manifestString);
      if (match != null) {
        setState(() {
          _version = match.group(1)!.trim();
        });
      }
    } catch (e) {
      setState(() {
        _version = '1.0.0+1'; // Fallback version
      });
    }
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CollectionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                    ),
                    child: const Text('View Collection'),
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

              // Version number at the bottom
              const SizedBox(height: 40),
              Text(
                'Version: $_version',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
