import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import '../services/game_service.dart';
import 'advanced_card_display.dart';
import '../models/card_drag_payload.dart';

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
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;
  List<String> _previousCardIds = [];
  List<String> _currentCardIds = [];
  bool _hasAnimatedDrawPhase = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _currentCardIds = widget.cards.map((card) => card.id).toList();
  }

  void _initializeAnimations() {
    _cardControllers = [];
    _slideAnimations = [];
    _fadeAnimations = [];
    _scaleAnimations = [];

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
      final cardId = _currentCardIds[i];
      final isNewCard = !_previousCardIds.contains(cardId);

      if (isNewCard || widget.isDrawPhase) {
        // Reset and start animation with stagger
        _cardControllers[i].reset();
        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) {
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
      height: 180,
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
                for (int i = 0; i < widget.cards.length; i++) ...[
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _slideAnimations[i],
                      _fadeAnimations[i],
                      _scaleAnimations[i],
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
                  if (i < widget.cards.length - 1)
                    const SizedBox(width: gapWidth),
                ],
              ],
            );

            if (needsScroll) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(padding),
                child: cardRow,
              );
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(padding),
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

class _DraggableHandCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final payload = CardDragPayload(
      card: card,
      handIndex: handIndex,
      instance: instance,
    );

    final cardWidget = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: isMarkedForDiscard
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.6),
                  width: 2,
                ),
              )
            : null,
        child: Opacity(
          opacity: isMarkedForDiscard ? 0.6 : 1.0,
          child: AdvancedCardDisplay(
            card: card,
            width: width,
            height: height,
            enableParallax: true,
            enableGlow: true,
            enableShadow: true,
          ),
        ),
      ),
    );

    final discardButton = isPlanning && !isLocked
        ? Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onToggleDiscard,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isMarkedForDiscard
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
            ),
          )
        : const SizedBox.shrink();

    // Feedback widget for drag
    final feedback = Opacity(
      opacity: 0.9,
      child: Material(
        type: MaterialType.transparency,
        child: AdvancedCardDisplay(
          card: card,
          width: width * 1.1,
          height: height * 1.1,
          enableParallax: false,
          enableGlow: true,
          enableShadow: true,
        ),
      ),
    );

    return Draggable<CardDragPayload>(
      data: payload,
      feedback: feedback,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedbackOffset: const Offset(0, -12),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: IgnorePointer(child: cardWidget),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showCardPreview(context),
        child: Stack(
          children: [
            cardWidget,
            if (discardButton is! SizedBox) discardButton,
          ],
        ),
      ),
    );
  }

  void _showCardPreview(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double maxWidth = size.width * 0.9;
    final double baseWidth = size.width < 600 ? size.width * 0.8 : 420;
    final double previewWidth = baseWidth.clamp(260.0, maxWidth);
    final double aspectRatio = height > 0 ? (height / width) : (160.0 / 110.0);
    final double previewHeight = previewWidth * aspectRatio;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 720;
              final double cardW = isWide
                  ? (constraints.maxWidth * 0.42).clamp(280.0, 540.0)
                  : previewWidth;
              final double cardH = cardW * aspectRatio;

              final content = isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Center(
                            child: AdvancedCardDisplay(
                              card: card,
                              width: cardW,
                              height: cardH,
                              enableParallax: true,
                              enableGlow: true,
                              enableShadow: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: _CardDetailsPanel(
                            card: card,
                            onPlay: () {
                              Navigator.of(ctx).pop();
                              final gameService = Provider.of<GameService>(context, listen: false);
                              gameService.beginCardPlacement(CardDragPayload(
                                card: card,
                                handIndex: handIndex,
                                instance: instance,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Select a tile on the board to play this card'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: AdvancedCardDisplay(
                              card: card,
                              width: cardW,
                              height: cardH,
                              enableParallax: true,
                              enableGlow: true,
                              enableShadow: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _CardDetailsPanel(
                            card: card,
                            onPlay: () {
                              Navigator.of(ctx).pop();
                              final gameService = Provider.of<GameService>(context, listen: false);
                              gameService.beginCardPlacement(CardDragPayload(
                                card: card,
                                handIndex: handIndex,
                                instance: instance,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Select a tile on the board to play this card'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );

              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: content,
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CardDetailsPanel extends StatelessWidget {
  final GameCard card;
  final VoidCallback? onPlay;

  const _CardDetailsPanel({required this.card, this.onPlay});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.name,
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                icon: Icons.category,
                label: card.type.displayName,
                color: Colors.blueAccent,
              ),
              _pill(
                icon: Icons.palette,
                label: card.color.displayName,
                color: _colorForCardColor(card.color),
              ),
              if (card.goldCost > 0)
                _pill(
                  icon: Icons.monetization_on,
                  label: '${card.goldCost} Gold',
                  color: Colors.amber.shade700,
                ),
              if (card.manaCost > 0)
                _pill(
                  icon: Icons.auto_awesome,
                  label: '${card.manaCost} Mana',
                  color: Colors.lightBlueAccent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (card.description.isNotEmpty) ...[
            Text(
              card.description,
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (card.isUnit && card.unitStats != null)
            _statsSection(
              title: 'Unit Stats',
              items: [
                _statItem(Icons.flash_on, 'Attack', '${card.unitStats!.attack}', Colors.redAccent),
                _statItem(Icons.favorite, 'Health', '${card.unitStats!.health}', Colors.greenAccent),
                _statItem(Icons.shield, 'Armor', '${card.unitStats!.armor}', Colors.blueAccent),
                _statItem(Icons.speed, 'Speed', '${card.unitStats!.speed}', Colors.yellowAccent),
                _statItem(Icons.straighten, 'Range', '${card.unitStats!.range}', Colors.purpleAccent),
              ],
            ),
          if (card.isBuilding && card.buildingStats != null)
            _statsSection(
              title: 'Building Stats',
              items: [
                _statItem(Icons.favorite, 'Health', '${card.buildingStats!.health}', Colors.greenAccent),
                _statItem(Icons.shield, 'Armor', '${card.buildingStats!.armor}', Colors.blueAccent),
                if (card.buildingStats!.attack != null)
                  _statItem(Icons.flash_on, 'Attack', '${card.buildingStats!.attack}', Colors.redAccent),
                if (card.buildingStats!.range != null)
                  _statItem(Icons.straighten, 'Range', '${card.buildingStats!.range}', Colors.purpleAccent),
              ],
            ),
          if (card.isHero && card.heroStats != null)
            _statsSection(
              title: 'Hero Stats',
              items: [
                _statItem(Icons.flash_on, 'Attack', '${card.heroStats!.attack}', Colors.redAccent),
                _statItem(Icons.favorite, 'Health', '${card.heroStats!.health}', Colors.greenAccent),
                _statItem(Icons.shield, 'Armor', '${card.heroStats!.armor}', Colors.blueAccent),
                _statItem(Icons.speed, 'Speed', '${card.heroStats!.speed}', Colors.yellowAccent),
                _statItem(Icons.straighten, 'Range', '${card.heroStats!.range}', Colors.purpleAccent),
                _statItem(Icons.timer, 'Cooldown', '${card.heroStats!.cooldown}', Colors.orangeAccent),
              ],
            ),
          if (card.abilities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Abilities',
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.abilities
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          a,
                          style: textTheme.bodySmall?.copyWith(
                            color: onSurface.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (card.flavorText != null && card.flavorText!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '“${card.flavorText}”',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (onPlay != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade400,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text(
                  'Play This Card',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statsSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForCardColor(CardColor color) {
    switch (color) {
      case CardColor.red:
        return Colors.redAccent;
      case CardColor.orange:
        return Colors.orangeAccent;
      case CardColor.yellow:
        return Colors.amberAccent;
      case CardColor.green:
        return Colors.lightGreenAccent;
      case CardColor.blue:
        return Colors.lightBlueAccent;
      case CardColor.purple:
        return Colors.purpleAccent;
    }
  }
}
