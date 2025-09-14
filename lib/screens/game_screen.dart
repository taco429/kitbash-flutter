import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/kitbash_game.dart';
import '../services/game_service.dart';
import '../services/card_service.dart';
import '../services/deck_service.dart';
import '../widgets/game_with_tooltip.dart';
// import '../widgets/turn_indicator.dart';
import '../widgets/lock_in_button.dart' hide WaitingIndicator;
import '../widgets/discard_pile.dart';
import '../widgets/hero_display.dart';
import '../widgets/player_deck_display.dart';
import '../widgets/animated_hand_display.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import 'game_over_screen.dart';
import '../widgets/game_log.dart';
import '../widgets/waiting_indicator.dart';
import '../widgets/cached_drag_feedback.dart';
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
    // Clear drag feedback cache to free memory
    DragFeedbackCache.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Selector for game over check only
    return Selector<GameService, (GameState?, int)>(
      selector: (_, service) => (service.gameState, service.currentPlayerIndex),
      builder: (context, data, child) {
        final gameState = data.$1;
        final myIndex = data.$2;

        // Handle game over navigation
        _checkGameOver(context, gameState);

        return Scaffold(
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // Game area
              Expanded(
                child: _buildGameArea(context),
              ),
              // Player control area
              _buildPlayerControlArea(context, myIndex, gameState),
            ],
          ),
        );
      },
    );
  }

  void _checkGameOver(BuildContext context, GameState? gameState) {
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
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final gameService = context.read<GameService>();
    return AppBar(
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
    );
  }

  Widget _buildGameArea(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: Stack(
        children: [
          // Game board
          Positioned.fill(
            child: GameWithTooltip(
              game: _game,
            ),
          ),
          // Floating game log overlay
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
    );
  }

  Widget _buildPlayerControlArea(
      BuildContext context, int myIndex, GameState? gameState) {
    return Container(
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
                // Hero display with isolated rebuild scope
                _buildHeroDisplay(context, myIndex),
                // Center: Player hand (expanded) with isolated rebuild
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHandDisplay(context, myIndex, gameState),
                  ),
                ),
                // Right side: Controls and piles with isolated rebuild
                _buildRightControls(context, myIndex, gameState),
              ],
            ),
          ),
          // Waiting indicator with isolated rebuild
          _buildWaitingIndicator(context, myIndex, gameState),
        ],
      ),
    );
  }

  // Optimized helper methods that use Selector for granular rebuilds

  Widget _buildHeroDisplay(BuildContext context, int myIndex) {
    return Selector<GameService, String?>(
      selector: (_, service) {
        final playerState = service.gameState?.playerStates.firstWhere(
          (ps) => ps.playerIndex == myIndex,
          orElse: () => PlayerBattleState(
            playerIndex: myIndex,
            deckId: '',
            hand: const [],
            deckCount: 0,
          ),
        );
        return playerState?.deckId;
      },
      builder: (context, deckId, child) {
        if (deckId == null || deckId.isEmpty) {
          return const HeroDisplay(
            heroCard: null,
            playerName: 'Your Hero',
            accentColor: Colors.green,
          );
        }

        final deckService = context.read<DeckService>();
        final cardService = context.read<CardService>();
        final deck = deckService.getDeckById(deckId) ??
            deckService.selectedDeck ??
            (deckService.availableDecks.isNotEmpty
                ? deckService.availableDecks.first
                : null);

        if (deck == null) {
          return const HeroDisplay(
            heroCard: null,
            playerName: 'Your Hero',
            accentColor: Colors.green,
          );
        }

        GameCard? heroCard;
        if (deck.heroCardId != null) {
          heroCard = cardService.getCardById(deck.heroCardId!);
        }

        return HeroDisplay(
          heroCard: heroCard,
          playerName: 'Your Hero',
          accentColor: Colors.green,
        );
      },
    );
  }

  Widget _buildHandDisplay(
      BuildContext context, int myIndex, GameState? gameState) {
    return Selector<GameService, (List<CardInstance>, String?)>(
      selector: (_, service) {
        final playerState = service.gameState?.playerStates.firstWhere(
          (ps) => ps.playerIndex == myIndex,
          orElse: () => PlayerBattleState(
            playerIndex: myIndex,
            deckId: '',
            hand: const [],
            deckCount: 0,
          ),
        );
        return (playerState?.hand ?? [], service.gameState?.currentPhase);
      },
      builder: (context, data, child) {
        final handInstances = data.$1;
        final currentPhase = data.$2;

        if (handInstances.isEmpty) {
          return AnimatedHandDisplay(
            cards: const [],
            cardInstances: const [],
            isDrawPhase: currentPhase == 'draw_income',
          );
        }

        // Direct transformation - CardService already has O(1) lookup
        final cardService = context.read<CardService>();
        final playerHandCards = handInstances
            .map((instance) => cardService.getCardById(instance.cardId))
            .whereType<GameCard>()
            .toList();

        return AnimatedHandDisplay(
          cards: playerHandCards,
          cardInstances: handInstances,
          isDrawPhase: currentPhase == 'draw_income',
        );
      },
    );
  }

  Widget _buildRightControls(
      BuildContext context, int myIndex, GameState? gameState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Lock button with isolated rebuild
        if (gameState != null)
          Selector<GameService, (bool, bool)>(
            selector: (_, service) => (
              service.gameState?.isPlayerLocked(myIndex) ?? false,
              service.gameState?.isPlayerLocked(1 - myIndex) ?? false,
            ),
            builder: (context, lockStates, child) {
              return LockInButton(
                isLocked: lockStates.$1,
                isOpponentLocked: lockStates.$2,
                playerIndex: myIndex,
                onLockIn: () {
                  context.read<GameService>().lockPlayerChoice(
                        widget.gameId,
                        myIndex,
                      );
                },
              );
            },
          ),
        const SizedBox(height: 8),
        // Deck and discard piles with isolated rebuild
        Selector<GameService, PlayerBattleState?>(
          selector: (_, service) => service.gameState?.playerStates.firstWhere(
            (ps) => ps.playerIndex == myIndex,
            orElse: () => PlayerBattleState(
              playerIndex: myIndex,
              deckId: '',
              hand: const [],
              deckCount: 0,
            ),
          ),
          builder: (context, playerState, child) {
            if (playerState == null) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayerDeckDisplay(
                    remainingCards: 0,
                    label: 'Deck',
                    accentColor: Colors.green,
                    deckCards: const [],
                    deckInstances: null,
                  ),
                  const SizedBox(width: 12),
                  DiscardPile(
                    discardedCards: const [],
                    discardInstances: null,
                    label: 'Discard',
                    accentColor: Colors.green,
                  ),
                ],
              );
            }

            final cardService = context.read<CardService>();

            // Direct transformation with O(1) lookup from CardService
            final deckCards = playerState.drawPile
                .map((instance) => cardService.getCardById(instance.cardId))
                .whereType<GameCard>()
                .toList();

            final discardCards = playerState.discardPile
                .map((instance) => cardService.getCardById(instance.cardId))
                .whereType<GameCard>()
                .toList();

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayerDeckDisplay(
                  remainingCards: playerState.deckCount,
                  label: 'Deck',
                  accentColor: Colors.green,
                  deckCards: deckCards,
                  deckInstances: playerState.drawPile,
                ),
                const SizedBox(width: 12),
                DiscardPile(
                  discardedCards: discardCards,
                  discardInstances: playerState.discardPile,
                  label: 'Discard',
                  accentColor: Colors.green,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWaitingIndicator(
      BuildContext context, int myIndex, GameState? gameState) {
    if (gameState == null) return const SizedBox.shrink();

    return Selector<GameService, bool>(
      selector: (_, service) =>
          service.gameState?.isPlayerLocked(myIndex) == true &&
          !(service.gameState?.allPlayersLocked ?? false),
      builder: (context, isWaiting, child) {
        if (!isWaiting) return const SizedBox.shrink();

        return const Padding(
          padding: EdgeInsets.only(top: 8),
          child: WaitingIndicator(
            isWaiting: true,
            waitingText: 'Waiting for opponent to lock in...',
          ),
        );
      },
    );
  }
}
