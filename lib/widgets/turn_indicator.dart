import 'package:flutter/material.dart';

class TurnIndicator extends StatefulWidget {
  final int turnNumber;
  final bool player1Locked;
  final bool player2Locked;

  const TurnIndicator({
    super.key,
    required this.turnNumber,
    required this.player1Locked,
    required this.player2Locked,
  });

  @override
  State<TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<TurnIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _lastTurnNumber = 0;

  @override
  void initState() {
    super.initState();
    _lastTurnNumber = widget.turnNumber;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(TurnIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.turnNumber != _lastTurnNumber) {
      _lastTurnNumber = widget.turnNumber;
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Turn number display
                Text(
                  'Turn ${widget.turnNumber}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                // Player lock status indicators
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PlayerLockIndicator(
                      playerName: 'Player 1',
                      isLocked: widget.player1Locked,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _PlayerLockIndicator(
                      playerName: 'Player 2',
                      isLocked: widget.player2Locked,
                      color: Colors.pink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerLockIndicator extends StatelessWidget {
  final String playerName;
  final bool isLocked;
  final Color color;

  const _PlayerLockIndicator({
    required this.playerName,
    required this.isLocked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playerName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Icon(
          isLocked ? Icons.lock : Icons.lock_open,
          size: 20,
          color: isLocked ? color : Colors.grey,
        ),
      ],
    );
  }
}