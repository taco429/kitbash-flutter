import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/kitbash_game.dart';
import '../services/game_service.dart';
import '../services/card_service.dart';
import '../services/deck_service.dart';
import '../widgets/game_with_tooltip.dart';
import '../widgets/turn_indicator.dart';
import '../widgets/lock_in_button.dart';
import '../widgets/advanced_card_display.dart';
import '../widgets/discard_pile.dart';
import '../widgets/hero_display.dart';
import '../widgets/reset_button.dart';
import '../widgets/player_deck_display.dart';
import '../widgets/animated_hand_display.dart';
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

        final int playerDeckCount = playerState?.deckCount ?? 0;

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
                    // Turn indicator with phase display
                    if (gameService.gameState != null)
                      TurnIndicator(
                        turnNumber: gameService.gameState!.currentTurn,
                        player1Locked: gameService.gameState!.isPlayerLocked(0),
                        player2Locked: gameService.gameState!.isPlayerLocked(1),
                        currentPhase: gameService.gameState!.currentPhase,
                        phaseStartTime: gameService.gameState!.phaseStartTime,
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
              // Game area taking full width (deck panels removed)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: GameWithTooltip(
                    game: KitbashGame(
                      gameId: widget.gameId,
                      gameService: gameService,
                    ),
                  ),
                ),
              ),
              // Player control area - reorganized layout
              Container(
                height: 260,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, -3),
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top row with controls and displays
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Left side: Lock-in and Reset buttons
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (gameService.gameState != null)
                                LockInButton(
                                  isLocked:
                                      gameService.gameState!.isPlayerLocked(
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
                              const SizedBox(height: 8),
                              ResetButton(
                                onReset: () {
                                  // TODO: Implement reset functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Reset functionality coming soon'),
                                    ),
                                  );
                                },
                                isEnabled: gameService.gameState != null &&
                                    !gameService.gameState!.isPlayerLocked(
                                      gameService.currentPlayerIndex,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Hero display
                          Consumer<DeckService>(
                            builder: (context, deckService, child) {
                              // Get hero card from player's deck
                              GameCard? heroCard;
                              if (playerState?.deckId != null) {
                                final deck =
                                    deckService.availableDecks.firstWhere(
                                  (d) => d.id == playerState!.deckId,
                                  orElse: () =>
                                      deckService.selectedDeck ??
                                      deckService.availableDecks.first,
                                );
                                if (deck.heroCardId != null) {
                                  heroCard =
                                      cardService.getCardById(deck.heroCardId!);
                                }
                              }
                              return HeroDisplay(
                                heroCard: heroCard,
                                playerName: 'Your Hero',
                                accentColor: Colors.green,
                              );
                            },
                          ),
                          // Center: Player hand (expanded)
                          Expanded(
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: AnimatedHandDisplay(
                                cards: playerHandCards,
                                isDrawPhase:
                                    gameState?.currentPhase == 'draw_income',
                              ),
                            ),
                          ),
                          // Right side: Discard pile and deck
                          PlayerDeckDisplay(
                            remainingCards: playerDeckCount,
                            label: 'Deck',
                            accentColor: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          const DiscardPile(
                            discardedCards: [], // TODO: Get discard pile from game state
                            label: 'Discard',
                            accentColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    // Waiting indicator if needed
                    if (gameService.gameState != null &&
                        gameService.gameState!.isPlayerLocked(
                          gameService.currentPlayerIndex,
                        ) &&
                        !gameService.gameState!.allPlayersLocked)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: WaitingIndicator(
                          isWaiting: true,
                          waitingText: 'Waiting for opponent to lock in...',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
