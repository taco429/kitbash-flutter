import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/kitbash_game.dart';
import '../services/game_service.dart';
import '../widgets/game_with_tooltip.dart';
import '../widgets/turn_indicator.dart';
import '../widgets/lock_in_button.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _hasNavigatedToGameOver = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, child) {
        // Check if game is over and navigate to game over screen
        final gameState = gameService.gameState;
        if (gameState != null &&
            !_hasNavigatedToGameOver &&
            (gameState.isGameOver || gameState.computedWinner != null)) {
          final winnerIndex =
              gameState.winnerPlayerIndex ?? gameState.computedWinner;
          if (winnerIndex != null) {
            _hasNavigatedToGameOver = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => GameOverScreen(
                    gameId: widget.gameId,
                    winnerPlayerIndex: winnerIndex,
                    winnerName: gameState.getWinnerName(winnerIndex),
                  ),
                ),
              );
            });
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Game ${widget.gameId}'),
            actions: [
              // Test buttons for dealing damage
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.green),
                tooltip: 'Damage Player 1 (Green)',
                onPressed: () => gameService.dealDamage(widget.gameId, 0, 10),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.pink),
                tooltip: 'Damage Player 2 (Pink)',
                onPressed: () => gameService.dealDamage(widget.gameId, 1, 10),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Game State',
                onPressed: () => gameService.requestGameState(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Game status bar with turn indicator
              Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      'Status: ${gameService.gameState?.status ?? 'Loading...'}',
                    ),
                    const Spacer(),
                    // Turn indicator
                    if (gameService.gameState != null)
                      TurnIndicator(
                        turnNumber: gameService.gameState!.currentTurn,
                        player1Locked: gameService.gameState!.isPlayerLocked(0),
                        player2Locked: gameService.gameState!.isPlayerLocked(1),
                      ),
                    const Spacer(),
                    if (gameService.gameState != null)
                      ...gameService.gameState!.commandCenters.map(
                        (cc) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.home,
                                color: cc.playerIndex == 0
                                    ? Colors.green
                                    : Colors.pink,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text('${cc.health}/${cc.maxHealth}'),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 50,
                                height: 8,
                                child: LinearProgressIndicator(
                                  value: cc.healthPercentage,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    cc.healthPercentage > 0.3
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Opponent deck area (left)
                    const SizedBox(
                      width: 110,
                      child: _DeckPanel(title: 'Opponent Deck', count: 30),
                    ),
                    // Game area with Flame GameWidget in the middle
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8)),
                        child: GameWithTooltip(
                          game: KitbashGame(
                            gameId: widget.gameId,
                            gameService: gameService,
                          ),
                        ),
                      ),
                    ),
                    // Player deck area (right)
                    const SizedBox(
                      width: 110,
                      child: _DeckPanel(title: 'Your Deck', count: 30),
                    ),
                  ],
                ),
              ),
              // Player control area with hand and lock-in button
              Column(
                children: [
                  // Lock-in button and waiting indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (gameService.gameState != null)
                          LockInButton(
                            isLocked: gameService.gameState!.isPlayerLocked(
                              gameService.currentPlayerIndex,
                            ),
                            isOpponentLocked:
                                gameService.gameState!.isPlayerLocked(
                              1 - gameService.currentPlayerIndex,
                            ),
                            playerIndex: gameService.currentPlayerIndex,
                            onLockIn: () {
                              gameService.lockPlayerChoice(
                                widget.gameId,
                                gameService.currentPlayerIndex,
                              );
                            },
                          ),
                        const SizedBox(width: 16),
                        if (gameService.gameState != null &&
                            gameService.gameState!.isPlayerLocked(
                              gameService.currentPlayerIndex,
                            ) &&
                            !gameService.gameState!.allPlayersLocked)
                          const WaitingIndicator(
                            isWaiting: true,
                            waitingText: 'Waiting for opponent to lock in...',
                          ),
                      ],
                    ),
                  ),
                  // Player hand at the bottom
                  const _HandBar(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeckPanel extends StatelessWidget {
  final String title;
  final int count;

  const _DeckPanel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    '$count cards',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandBar extends StatelessWidget {
  const _HandBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, -2),
            color: Colors.black26,
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return AspectRatio(
            aspectRatio: 63 / 88,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D2F36), Color(0xFF404556)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Card ${index + 1}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
