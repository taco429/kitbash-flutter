import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import '../services/game_service.dart';
import 'advanced_card_display.dart';
import '../models/card_drag_payload.dart';
import 'cached_drag_feedback.dart';

class AnimatedHandDisplay extends StatefulWidget {
  final List<GameCard> cards;
  final List<CardInstance> cardInstances;
  final bool isDrawPhase;

  const AnimatedHandDisplay({
    super.key,
    required this.cards,
    required this.cardInstances,
    this.isDrawPhase = false,
  });

  @override
  State<AnimatedHandDisplay> createState() => _AnimatedHandDisplayState();
}

class _AnimatedHandDisplayState extends State<AnimatedHandDisplay>
    with TickerProviderStateMixin {
  final List<AnimationController> _cardControllers = [];
  final List<Animation<double>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<double>> _scaleAnimations = [];
  List<String> _previousCardIds = [];
  List<String> _currentCardIds = [];
  bool _hasAnimatedDrawPhase = false;

  // Cache for reusing animations when card count doesn't change
  int _lastCardCount = -1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _currentCardIds = widget.cards.map((card) => card.id).toList();
  }

  void _initializeAnimations() {
    // Reuse existing controllers if card count is the same
    if (_lastCardCount == widget.cards.length &&
        _cardControllers.length == widget.cards.length) {
      return; // Reuse existing animations
    }

    _lastCardCount = widget.cards.length;

    for (int i = 0; i < widget.cards.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _cardControllers.add(controller);

      // Slide animation from deck position (right side) to hand position
      _slideAnimations.add(
        Tween<double>(
          begin: 300.0, // Start from right side (deck position)
          end: 0.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutCubic,
          ),
        ),
      );

      // Fade in animation
      _fadeAnimations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
          ),
        ),
      );

      // Scale animation for a nice pop effect
      _scaleAnimations.add(
        Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.elasticOut,
          ),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(AnimatedHandDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    _previousCardIds = _currentCardIds;
    _currentCardIds = widget.cards.map((card) => card.id).toList();

    // Check if we're in draw phase and have new cards
    if (widget.isDrawPhase && !_hasAnimatedDrawPhase) {
      _hasAnimatedDrawPhase = true;
      _animateNewCards();
    } else if (!widget.isDrawPhase) {
      _hasAnimatedDrawPhase = false;
    }

    // Handle card count changes
    if (widget.cards.length != _cardControllers.length) {
      _resetAnimations();
    } else if (_hasNewCards()) {
      _animateNewCards();
    }
  }

  bool _hasNewCards() {
    for (String cardId in _currentCardIds) {
      if (!_previousCardIds.contains(cardId)) {
        return true;
      }
    }
    return false;
  }

  void _resetAnimations() {
    // Dispose old controllers
    for (var controller in _cardControllers) {
      controller.dispose();
    }

    // IMPORTANT: Clear the lists to prevent memory leaks
    _cardControllers.clear();
    _slideAnimations.clear();
    _fadeAnimations.clear();
    _scaleAnimations.clear();

    // Reinitialize with new card count
    _initializeAnimations();

    // Animate all cards if we have new ones
    if (_hasNewCards() || widget.isDrawPhase) {
      _animateNewCards();
    } else {
      // Just show existing cards without animation
      for (var controller in _cardControllers) {
        controller.value = 1.0;
      }
    }
  }

  void _animateNewCards() {
    // Stagger the animations for each card
    for (int i = 0; i < _cardControllers.length; i++) {
      if (i >= _currentCardIds.length) break; // Safety check

      final cardId = _currentCardIds[i];
      final isNewCard = !_previousCardIds.contains(cardId);

      if (isNewCard || widget.isDrawPhase) {
        // Reset and start animation with stagger
        _cardControllers[i].reset();
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted && i < _cardControllers.length) {
            _cardControllers[i].forward();
          }
        });
      } else {
        // Existing card, ensure it's fully visible
        _cardControllers[i].value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: widget.cards.isEmpty
          ? _buildEmptyHandDisplay(context)
          : _buildCardDisplay(context),
    );
  }

  Widget _buildEmptyHandDisplay(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pan_tool,
            size: 48,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            'Your hand is empty',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDisplay(BuildContext context) {
    return Consumer<GameService>(
      builder: (context, gameService, child) {
        final isPlanning = gameService.gameState?.currentPhase == 'planning';
        final isLocked = gameService.gameState
                ?.isPlayerLocked(gameService.currentPlayerIndex) ??
            false;

        return LayoutBuilder(
          builder: (context, constraints) {
            const double cardWidth = 110;
            const double cardHeight = 160;
            const double gapWidth = 8;
            const double padding = 12;

            final int numCards = widget.cards.length;
            final double totalWidth = numCards > 0
                ? (numCards * cardWidth) + ((numCards - 1) * gapWidth)
                : 0;

            final bool needsScroll =
                totalWidth > (constraints.maxWidth - padding * 2);

            final Widget cardRow = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: needsScroll ? MainAxisSize.max : MainAxisSize.min,
              children: [
                for (int i = 0;
                    i < widget.cards.length && i < _cardControllers.length;
                    i++) ...[
                  RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        if (i < _slideAnimations.length) _slideAnimations[i],
                        if (i < _fadeAnimations.length) _fadeAnimations[i],
                        if (i < _scaleAnimations.length) _scaleAnimations[i],
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_slideAnimations[i].value, 0),
                          child: Transform.scale(
                            scale: _scaleAnimations[i].value,
                            child: Opacity(
                              opacity: _fadeAnimations[i].value,
                              child: _DraggableHandCard(
                                width: cardWidth,
                                height: cardHeight,
                                card: widget.cards[i],
                                isMarkedForDiscard:
                                    i < widget.cardInstances.length &&
                                        gameService.isCardMarkedForDiscard(
                                            widget.cardInstances[i].instanceId),
                                instance: i < widget.cardInstances.length
                                    ? widget.cardInstances[i]
                                    : null,
                                handIndex: i,
                                isPlanning: isPlanning,
                                isLocked: isLocked,
                                onToggleDiscard: () {
                                  if (i < widget.cardInstances.length) {
                                    gameService.toggleCardDiscard(
                                        widget.cardInstances[i].instanceId);
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (i < widget.cards.length - 1)
                    const SizedBox(width: gapWidth),
                ],
              ],
            );

            if (needsScroll) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: padding, vertical: 4),
                child: cardRow,
              );
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: padding, vertical: 4),
                  child: cardRow,
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _DraggableHandCard extends StatefulWidget {
  final double width;
  final double height;
  final GameCard card;
  final CardInstance? instance;
  final int handIndex;
  final bool isMarkedForDiscard;
  final bool isPlanning;
  final bool isLocked;
  final VoidCallback onToggleDiscard;

  const _DraggableHandCard({
    required this.width,
    required this.height,
    required this.card,
    required this.instance,
    required this.handIndex,
    required this.isMarkedForDiscard,
    required this.isPlanning,
    required this.isLocked,
    required this.onToggleDiscard,
  });

  @override
  State<_DraggableHandCard> createState() => _DraggableHandCardState();
}

class _DraggableHandCardState extends State<_DraggableHandCard> {
  late Widget _feedbackWidget;

  @override
  void initState() {
    super.initState();
    _buildFeedback();
  }

  @override
  void didUpdateWidget(_DraggableHandCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild feedback if card changed
    if (oldWidget.card.id != widget.card.id) {
      _buildFeedback();
    }
  }

  void _buildFeedback() {
    // Pre-build and cache the feedback widget
    _feedbackWidget = DragFeedbackCache.getFeedback(
      card: widget.card,
      width: widget.width,
      height: widget.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = CardDragPayload(
      card: widget.card,
      handIndex: widget.handIndex,
      instance: widget.instance,
    );

    final cardWidget = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height,
        decoration: widget.isMarkedForDiscard
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.6),
                  width: 2,
                ),
              )
            : null,
        child: Opacity(
          opacity: widget.isMarkedForDiscard ? 0.6 : 1.0,
          child: AdvancedCardDisplay(
            card: widget.card,
            width: widget.width,
            height: widget.height,
            enableParallax: true,
            enableGlow: true,
            enableShadow: true,
          ),
        ),
      ),
    );

    final Widget discardButton = widget.isPlanning && !widget.isLocked
        ? GestureDetector(
            onTap: widget.onToggleDiscard,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.isMarkedForDiscard
                    ? Colors.red
                    : Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          )
        : const SizedBox.shrink();

    return Draggable<CardDragPayload>(
      data: payload,
      feedback: _feedbackWidget,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedbackOffset: const Offset(0, -12),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: IgnorePointer(child: cardWidget),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showCardPreview(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (discardButton is! SizedBox) ...[
              Center(child: discardButton),
              const SizedBox(height: 4),
            ],
            cardWidget,
          ],
        ),
      ),
    );
  }

  void _showCardPreview(BuildContext context) {
    final gameService = Provider.of<GameService>(context, listen: false);
    gameService.showCardPreview(CardDragPayload(
      card: widget.card,
      handIndex: widget.handIndex,
      instance: widget.instance,
    ));
  }
}
