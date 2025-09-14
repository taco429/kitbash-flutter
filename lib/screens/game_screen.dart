import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/kitbash_game.dart';
import '../services/game_service.dart';
import '../services/card_service.dart';
import '../services/deck_service.dart';
import '../widgets/game_with_tooltip.dart';
// import '../widgets/turn_indicator.dart';
import '../widgets/lock_in_button.dart';
import '../widgets/discard_pile.dart';
import '../widgets/hero_display.dart';
import '../widgets/player_deck_display.dart';
import '../widgets/animated_hand_display.dart';
import '../models/card.dart';
import 'game_over_screen.dart';
import '../widgets/game_log.dart';
// import '../widgets/opponent_indicator.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _hasNavigatedToGameOver = false;
  late KitbashGame _game;

  @override
  void initState() {
    super.initState();
    // Create the game instance once
    final gameService = context.read<GameService>();
    _game = KitbashGame(
      gameId: widget.gameId,
      gameService: gameService,
    );
  }

  @override
  void dispose() {
    // Clean up the game instance
    _game.onRemove();
    super.dispose();
  }

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
        // Opponent state now consumed in overlay inside GameWithTooltip

        final int playerDeckCount = playerState?.deckCount ?? 0;

        final List<GameCard> playerHandCards = (playerState?.hand ?? [])
            .map((instance) => cardService.getCardById(instance.cardId))
            .whereType<GameCard>()
            .toList();

        // Map card instances to their cards for display
        final handInstances = playerState?.hand ?? [];
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
              // Game area taking full width (deck panels removed)
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: Stack(
                    children: [
                      // Game board
                      Positioned.fill(
                        child: GameWithTooltip(
                          game: _game,
                        ),
                      ),
                      // Floating game log overlay anchored to bottom-left
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: const IgnorePointer(
                            ignoring: true,
                            child: GameLog(maxRows: 4),
                          ),
                        ),
                      ),
                    ],
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
                                cardInstances: handInstances,
                                isDrawPhase:
                                    gameState?.currentPhase == 'draw_income',
                              ),
                            ),
                          ),
                          // Right side: Discard pile and deck
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PlayerDeckDisplay(
                                    remainingCards: playerDeckCount,
                                    label: 'Deck',
                                    accentColor: Colors.green,
                                    deckCards: playerState?.drawPile
                                            .map((instance) => cardService
                                                .getCardById(instance.cardId))
                                            .whereType<GameCard>()
                                            .toList() ??
                                        [],
                                    deckInstances: playerState?.drawPile,
                                  ),
                                  const SizedBox(width: 12),
                                  DiscardPile(
                                    discardedCards: playerState?.discardPile
                                            .map((instance) => cardService
                                                .getCardById(instance.cardId))
                                            .whereType<GameCard>()
                                            .toList() ??
                                        [],
                                    discardInstances: playerState?.discardPile,
                                    label: 'Discard',
                                    accentColor: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Game log moved above the player's hand area
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
