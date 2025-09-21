import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/kitbash_game.dart';
import '../services/game_service.dart';
import '../services/card_service.dart';
import '../widgets/game_with_tooltip.dart';
// import '../widgets/turn_indicator.dart';
import '../widgets/lock_in_button.dart' hide WaitingIndicator;
import '../widgets/animated_hand_display.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import '../models/resources.dart';
import 'game_over_screen.dart';
import '../widgets/game_log.dart';
import '../widgets/waiting_indicator.dart';
import '../widgets/cached_drag_feedback.dart';
import '../widgets/player_indicator.dart';

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
      height: 280,
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
          // Top row with player indicator and hand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Left side: Player indicator (hero, deck, discard, resources)
                _buildPlayerIndicator(context, myIndex),
                // Center: Player hand (expanded) with isolated rebuild
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildHandDisplay(context, myIndex, gameState),
                  ),
                ),
                // Right side: Controls
                _buildControls(context, myIndex, gameState),
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

  Widget _buildPlayerIndicator(BuildContext context, int myIndex) {
    return Selector<GameService, PlayerBattleState?>(
      selector: (_, service) => service.gameState?.playerStates.firstWhere(
        (ps) => ps.playerIndex == myIndex,
        orElse: () => PlayerBattleState(
          playerIndex: myIndex,
          deckId: '',
          hand: const [],
          deckCount: 0,
          resources: const Resources(gold: 0, mana: 0),
          resourceIncome: const ResourceGeneration(gold: 0, mana: 0),
        ),
      ),
      builder: (context, playerState, child) {
        return PlayerIndicator(
          playerState: playerState,
          playerName: 'Your Hero',
          accentColor: Colors.green,
          isCurrentPlayer: true,
          showResources: true,
          compact: false,
          maxWidth: null, // No max width constraint for current player
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
            resources: const Resources(gold: 0, mana: 0),
            resourceIncome: const ResourceGeneration(gold: 0, mana: 0),
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

  Widget _buildControls(
      BuildContext context, int myIndex, GameState? gameState) {
    if (gameState == null) return const SizedBox.shrink();
    
    return Selector<GameService, (bool, bool, String?, int)>(
      selector: (_, service) => (
        service.gameState?.isPlayerLocked(myIndex) ?? false,
        service.gameState?.isPlayerLocked(1 - myIndex) ?? false,
        service.gameState?.currentPhase,
        service.gameState?.plannedPlays[myIndex]?.length ?? 0,
      ),
      builder: (context, data, child) {
        final isLocked = data.$1;
        final isOpponentLocked = data.$2;
        final currentPhase = data.$3;
        final plannedPlaysCount = data.$4;
        final isPlanning = currentPhase == 'planning';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reset button - only show during planning phase when not locked and has planned plays
            if (isPlanning && !isLocked && plannedPlaysCount > 0) ...[
              _buildResetButton(context, myIndex),
              const SizedBox(width: 8),
            ],
            // Lock button
            LockInButton(
              isLocked: isLocked,
              isOpponentLocked: isOpponentLocked,
              playerIndex: myIndex,
              onLockIn: () {
                context.read<GameService>().lockPlayerChoice(
                      widget.gameId,
                      myIndex,
                    );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildResetButton(BuildContext context, int playerIndex) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<GameService>().resetPlannedPlays(
                widget.gameId,
                playerIndex,
              );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade600,
                Colors.orange.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.shade800,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Reset',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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
