import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/kitbash_game.dart';
import '../models/card.dart';
import '../models/card_instance.dart';

/// A wrapper widget that adds drag-and-drop functionality to the game widget
class GameWithDragDrop extends StatefulWidget {
  final KitbashGame game;
  
  const GameWithDragDrop({
    super.key,
    required this.game,
  });

  @override
  State<GameWithDragDrop> createState() => _GameWithDragDropState();
}

class _GameWithDragDropState extends State<GameWithDragDrop> {
  bool _isDragHovering = false;
  GameCard? _draggedCard;
  CardInstance? _draggedInstance;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (details) {
        // Check if we can accept this drag
        final data = details.data;
        if (data['card'] is GameCard) {
          setState(() {
            _isDragHovering = true;
            _draggedCard = data['card'] as GameCard;
            _draggedInstance = data['instance'] as CardInstance?;
          });
          
          // Update grid hover state
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);
          widget.game._grid?.handleDragHover(
            Offset(localPosition.dx, localPosition.dy),
            _draggedCard,
          );
          
          return true;
        }
        return false;
      },
      onAcceptWithDetails: (details) {
        // Handle the drop
        final data = details.data;
        final card = data['card'] as GameCard;
        final instance = data['instance'] as CardInstance?;
        
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        
        // Try to place the card on the grid
        final success = widget.game._grid?.handleCardDrop(
          Offset(localPosition.dx, localPosition.dy),
          card,
        ) ?? false;
        
        if (success) {
          // Show success animation
          _showCardPlacementAnimation(localPosition);
          
          // Play sound effect (if you have audio)
          // AudioManager.playCardPlace();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Played ${card.name}!'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green.shade700,
            ),
          );
        } else {
          // Show error feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot place card here'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        
        setState(() {
          _isDragHovering = false;
          _draggedCard = null;
          _draggedInstance = null;
        });
      },
      onLeave: (_) {
        setState(() {
          _isDragHovering = false;
          _draggedCard = null;
          _draggedInstance = null;
        });
        widget.game._grid?.clearDragHover();
      },
      onMove: (details) {
        if (_isDragHovering && _draggedCard != null) {
          // Update hover position as the drag moves
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);
          widget.game._grid?.handleDragHover(
            Offset(localPosition.dx, localPosition.dy),
            _draggedCard,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            // The game widget
            GameWidget(game: widget.game),
            
            // Drag hover overlay
            if (_isDragHovering)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCardPlacementAnimation(Offset position) {
    // Create an overlay entry for the animation
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _CardPlacementAnimation(
        position: position,
      ),
    );
    
    overlay.insert(entry);
    
    // Remove after animation completes
    Future.delayed(const Duration(milliseconds: 800), () {
      entry.remove();
    });
  }
}

/// Animation widget shown when a card is successfully placed
class _CardPlacementAnimation extends StatefulWidget {
  final Offset position;
  
  const _CardPlacementAnimation({
    required this.position,
  });

  @override
  State<_CardPlacementAnimation> createState() => _CardPlacementAnimationState();
}

class _CardPlacementAnimationState extends State<_CardPlacementAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 50,
      top: widget.position.dy - 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.6),
                      Colors.green.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}