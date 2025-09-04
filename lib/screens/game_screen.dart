import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game/kitbash_game.dart';
import '../services/game_service.dart';
import '../services/deck_service.dart';
import '../widgets/game_with_tooltip.dart';
import '../widgets/turn_indicator.dart';
import '../widgets/lock_in_button.dart';
import '../widgets/advanced_card_display.dart';
import '../models/card.dart';
import '../models/deck.dart';
import 'game_over_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _hasNavigatedToGameOver = false;
  bool _decksInitialized = false;
  List<GameCard> _playerDrawPile = [];
  List<GameCard> _opponentDrawPile = [];
  List<GameCard> _playerHand = [];

  void _initializeDecks(DeckService deckService) {
    if (_decksInitialized) return;
    if (deckService.availableDecks.isEmpty) return;

    final Deck playerDeckSelection =
        deckService.selectedDeck ?? deckService.availableDecks.first;
    final Deck opponentDeckSelection = deckService.availableDecks.firstWhere(
      (d) => d.id != playerDeckSelection.id,
      orElse: () => deckService.availableDecks.first,
    );

    final List<GameCard> playerCards = _expandDeck(playerDeckSelection);
    final List<GameCard> opponentCards = _expandDeck(opponentDeckSelection);
    playerCards.shuffle();
    opponentCards.shuffle();

    setState(() {
      _playerDrawPile = playerCards;
      _opponentDrawPile = opponentCards;
      _playerHand = [];
      _decksInitialized = true;
    });

    _drawInitialHand(7);
  }

  List<GameCard> _expandDeck(Deck deck) {
    final List<GameCard> cards = [];
    for (final deckCard in deck.allCards) {
      for (int i = 0; i < deckCard.quantity; i++) {
        cards.add(deckCard.card);
      }
    }
    return cards;
  }

  void _drawInitialHand(int count) {
    if (_playerDrawPile.isEmpty) return;
    final int toDraw = count.clamp(0, _playerDrawPile.length);
    final List<GameCard> drawn = [];
    for (int i = 0; i < toDraw; i++) {
      drawn.add(_playerDrawPile.removeLast());
    }
    setState(() {
      _playerHand.addAll(drawn);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, child) {
        final deckService = context.watch<DeckService>();
        if (!_decksInitialized && !deckService.isLoading && deckService.availableDecks.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeDecks(deckService);
          });
        }

        final int opponentDeckCount =
            _decksInitialized ? _opponentDrawPile.length : 0;
        final int playerDeckCount = _decksInitialized ? _playerDrawPile.length : 0;
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
                    SizedBox(
                      width: 110,
                      child:
                          _DeckPanel(title: 'Opponent Deck', count: opponentDeckCount),
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
                      child: _DeckPanel(title: 'Your Deck', count: playerDeckCount),
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
                  _HandBar(cards: _playerHand),
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
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 96,
            child: AdvancedCardDisplay(
              card: cards[index],
              width: 96,
              height: 136,
              enableParallax: false,
              enableGlow: true,
              enableShadow: true,
            ),
          );
        },
      ),
    );
  }
}
