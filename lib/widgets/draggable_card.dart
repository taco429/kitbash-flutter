import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import 'advanced_card_display.dart';

/// A wrapper widget that makes a card draggable with beautiful visual feedback
class DraggableCard extends StatefulWidget {
  final GameCard card;
  final CardInstance? cardInstance;
  final double width;
  final double height;
  final bool isDraggable;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final Function(GameCard, CardInstance?)? onDragCompleted;

  const DraggableCard({
    super.key,
    required this.card,
    this.cardInstance,
    this.width = 110,
    this.height = 160,
    this.isDraggable = true,
    this.onDragStarted,
    this.onDragEnd,
    this.onDragCompleted,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDraggable) {
      return _buildCard();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Draggable<Map<String, dynamic>>(
              data: {
                'card': widget.card,
                'instance': widget.cardInstance,
              },
              feedback: _buildDragFeedback(),
              childWhenDragging: _buildDragPlaceholder(),
              onDragStarted: () {
                setState(() {
                  _isDragging = true;
                });
                _controller.forward();
                widget.onDragStarted?.call();
              },
              onDragEnd: (details) {
                setState(() {
                  _isDragging = false;
                });
                _controller.reverse();
                widget.onDragEnd?.call();
              },
              onDragCompleted: () {
                widget.onDragCompleted?.call(widget.card, widget.cardInstance);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                onEnter: (_) {
                  if (!_isDragging) {
                    _controller.forward();
                  }
                },
                onExit: (_) {
                  if (!_isDragging) {
                    _controller.reverse();
                  }
                },
                child: _buildCard(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AdvancedCardDisplay(
        card: widget.card,
        width: widget.width,
        height: widget.height,
        enableParallax: true,
        enableGlow: true,
        enableShadow: true,
      ),
    );
  }

  Widget _buildDragFeedback() {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.15,
        child: Transform.rotate(
          angle: -0.05,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getCardGlowColor().withValues(alpha: 0.6),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                const BoxShadow(
                  color: Colors.black54,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: AdvancedCardDisplay(
              card: widget.card,
              width: widget.width,
              height: widget.height,
              enableParallax: false,
              enableGlow: true,
              enableShadow: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragPlaceholder() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.content_copy,
          size: 32,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Color _getCardGlowColor() {
    switch (widget.card.color) {
      case CardColor.red:
        return Colors.red.shade400;
      case CardColor.orange:
        return Colors.orange.shade400;
      case CardColor.yellow:
        return Colors.yellow.shade400;
      case CardColor.green:
        return Colors.green.shade400;
      case CardColor.blue:
        return Colors.blue.shade400;
      case CardColor.purple:
        return Colors.purple.shade400;
    }
  }
}