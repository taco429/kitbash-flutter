import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import 'menu_screen.dart';
import 'game_lobby_screen.dart';
import 'game_screen.dart';

class GameOverScreen extends StatelessWidget {
  final String gameId;
  final int winnerPlayerIndex;
  final String winnerName;

  const GameOverScreen({
    super.key,
    required this.gameId,
    required this.winnerPlayerIndex,
    required this.winnerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Victory animation container
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _getPlayerColor(winnerPlayerIndex).withValues(alpha: 0.2),
                  border: Border.all(
                    color: _getPlayerColor(winnerPlayerIndex),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getPlayerColor(winnerPlayerIndex)
                          .withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: _getPlayerColor(winnerPlayerIndex),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'VICTORY',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getPlayerColor(winnerPlayerIndex),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Winner announcement
              Text(
                'GAME OVER',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
              ),

              const SizedBox(height: 16),

              Text(
                '$winnerName Wins!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _getPlayerColor(winnerPlayerIndex),
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                'Player ${winnerPlayerIndex + 1}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),

              const SizedBox(height: 60),

              // Action buttons
              Column(
                children: <Widget>[
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _playAgain(context),
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getPlayerColor(winnerPlayerIndex),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => _findNewGame(context),
                      icon: const Icon(Icons.search),
                      label: const Text(
                        'Find New Game',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white70, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: TextButton.icon(
                      onPressed: () => _returnToMenu(context),
                      icon: const Icon(Icons.home),
                      label: const Text(
                        'Main Menu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white54,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPlayerColor(int playerIndex) {
    return playerIndex == 0 ? Colors.green : Colors.pink;
  }

  void _playAgain(BuildContext context) {
    final gameService = Provider.of<GameService>(context, listen: false);

    // Disconnect from current game
    gameService.disconnect();

    // Create a new CPU game
    gameService.createCpuGame().then((gameData) {
      if (context.mounted) {
        if (gameData != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GameScreen(gameId: gameData['id']),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create new game'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _findNewGame(BuildContext context) {
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.disconnect();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GameLobbyScreen(),
      ),
    );
  }

  void _returnToMenu(BuildContext context) {
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.disconnect();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MenuScreen(),
      ),
    );
  }
}
