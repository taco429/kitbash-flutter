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
  late final KitbashGame _game;

  @override
  void initState() {
    super.initState();
    final gameService = Provider.of<GameService>(context, listen: false);
    _game = KitbashGame(gameId: widget.gameId, gameService: gameService);
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
                          game: _game,
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
              // Player control area reorganized into Left/Middle/Right
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Lock-in + Reset, with Hero badge next to them
                    SizedBox(
                      width: 320,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Buttons column
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  _game.clearSelection();
                                },
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Reset'),
                              ),
                              const SizedBox(height: 8),
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
                          const SizedBox(width: 12),
                          // Hero compact display
                          _HeroBadge(
                            deckId: playerState?.deckId,
                          ),
                        ],
                      ),
                    ),
                    // Middle: Player hand centered
                    Expanded(
                      child: _HandBar(cards: playerHandCards),
                    ),
                    // Right: Discard pile and Deck
                    SizedBox(
                      width: 180,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _MiniStack(
                            label: 'Discard',
                            accentColor: Colors.orange.shade700,
                            countText: null,
                          ),
                          const SizedBox(width: 12),
                          _MiniStack(
                            label: 'Deck',
                            accentColor: Colors.green.shade700,
                            countText: '$playerDeckCount',
                          ),
                        ],
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

class _HeroBadge extends StatelessWidget {
  final String? deckId;

  const _HeroBadge({required this.deckId});

  @override
  Widget build(BuildContext context) {
    final cardService = context.watch<CardService>();
    final deckService = context.watch<DeckService>();

    if (deckId == null || deckId!.isEmpty) {
      return _HeroPlaceholder();
    }

    final String? heroId = deckService.getHeroCardIdForDeck(deckId!);
    if (heroId == null) {
      return _HeroPlaceholder();
    }

    final GameCard? heroCard = cardService.getCardById(heroId);
    if (heroCard == null) {
      return _HeroPlaceholder();
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AdvancedCardDisplay(
        card: heroCard,
        width: 84,
        height: 118,
        enableParallax: false,
        enableGlow: false,
        enableShadow: false,
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 118,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        'No Hero',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _MiniStack extends StatelessWidget {
  final String label;
  final Color accentColor;
  final String? countText;

  const _MiniStack({
    required this.label,
    required this.accentColor,
    this.countText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          _MiniStackCards(color: accentColor),
          if (countText != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                countText!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStackCards extends StatelessWidget {
  final Color color;

  const _MiniStackCards({required this.color});

  @override
  Widget build(BuildContext context) {
    const double w = 48;
    const double h = 66;
    const double dx = 6;
    const double dy = 5;

    return SizedBox(
      width: w + (dx * 3),
      height: h + (dy * 3),
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(4, (index) {
          final double ox = (3 - index) * dx;
          final double oy = (3 - index) * dy;
          final double alpha = 0.9 - index * 0.15;
          return Positioned(
            left: ox,
            top: oy,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: alpha.clamp(0.4, 0.9)),
                    color.withValues(alpha: (alpha - 0.2).clamp(0.3, 0.8)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black26, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
