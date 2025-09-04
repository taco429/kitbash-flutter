import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/kitbash_game.dart';
import '../services/game_service.dart';
import '../services/card_service.dart';
import '../widgets/game_with_tooltip.dart';
import '../widgets/turn_indicator.dart';
import '../widgets/lock_in_button.dart';
import '../widgets/advanced_card_display.dart';
import '../widgets/deck_stack.dart';
import '../models/card.dart';
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
        final cardService = context.watch<CardService>();
        final gameState = gameService.gameState;
        final int myIndex = gameService.currentPlayerIndex;
        final playerState = gameState?.playerStates.firstWhere(
          (ps) => ps.playerIndex == myIndex,
          orElse: () => PlayerBattleState(
            playerIndex: myIndex,
            deckId: '',
            hand: const [],
            deckCount: 0,
          ),
        );
        final opponentState = gameState?.playerStates.firstWhere(
          (ps) => ps.playerIndex != myIndex,
          orElse: () => PlayerBattleState(
            playerIndex: 1 - myIndex,
            deckId: '',
            hand: const [],
            deckCount: 0,
          ),
        );

        final int playerDeckCount = playerState?.deckCount ?? 0;
        final int opponentDeckCount = opponentState?.deckCount ?? 0;

        final List<GameCard> playerHandCards = (playerState?.hand ?? [])
            .map((id) => cardService.getCardById(id))
            .whereType<GameCard>()
            .toList();
        // Check if game is over and navigate to game over screen
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
                    SizedBox(
                      width: 110,
                      child: DeckStack(
                        label: 'Opponent',
                        remainingCount: opponentDeckCount,
                        accentColor: Colors.pink,
                      ),
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
                    SizedBox(
                      width: 110,
                      child: DeckStack(
                        label: 'You',
                        remainingCount: playerDeckCount,
                        accentColor: Colors.green,
                      ),
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
                  _HandBar(cards: playerHandCards),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HandBar extends StatelessWidget {
  final List<GameCard> cards;

  const _HandBar({required this.cards});

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double cardWidth = 96;
          const double gapWidth = 12;
          const double horizontalPadding = 12;

          final int numCards = cards.length;
          final double contentWidth = numCards > 0
              ? (numCards * cardWidth) + ((numCards - 1) * gapWidth)
              : 0;

          final double viewportWidth =
              constraints.maxWidth > (horizontalPadding * 2)
                  ? (constraints.maxWidth - (horizontalPadding * 2))
                  : 0;

          final double sizedBoxWidth =
              contentWidth > viewportWidth ? contentWidth : viewportWidth;

          final List<Widget> children = [];
          for (int i = 0; i < numCards; i++) {
            children.add(SizedBox(
              width: cardWidth,
              child: AdvancedCardDisplay(
                card: cards[i],
                width: cardWidth,
                height: 136,
                enableParallax: false,
                enableGlow: true,
                enableShadow: true,
              ),
            ));
            if (i < numCards - 1) {
              children.add(const SizedBox(width: gapWidth));
            }
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: SizedBox(
              width: sizedBoxWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }
}
