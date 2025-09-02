import 'package:flutter/material.dart';

class LockInButton extends StatefulWidget {
  final bool isLocked;
  final bool isOpponentLocked;
  final VoidCallback onLockIn;
  final int playerIndex;

  const LockInButton({
    super.key,
    required this.isLocked,
    required this.isOpponentLocked,
    required this.onLockIn,
    required this.playerIndex,
  });

  @override
  State<LockInButton> createState() => _LockInButtonState();
}

class _LockInButtonState extends State<LockInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isLocked) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      widget.onLockIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = widget.isLocked
        ? Colors.grey
        : (widget.playerIndex == 0 ? Colors.green : Colors.pink);

    final Color borderColor = widget.isLocked
        ? Colors.grey.shade600
        : (widget.playerIndex == 0 ? Colors.green.shade700 : Colors.pink.shade700);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.isLocked
                  ? []
                  : [
                      BoxShadow(
                        color: buttonColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isLocked
                          ? [Colors.grey.shade600, Colors.grey.shade700]
                          : [buttonColor, buttonColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isLocked ? Icons.lock : Icons.lock_open,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isLocked ? 'Locked In' : 'Lock In Choice',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WaitingIndicator extends StatefulWidget {
  final bool isWaiting;
  final String waitingText;

  const WaitingIndicator({
    super.key,
    required this.isWaiting,
    this.waitingText = 'Waiting for opponent...',
  });

  @override
  State<WaitingIndicator> createState() => _WaitingIndicatorState();
}

class _WaitingIndicatorState extends State<WaitingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isWaiting) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaitingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWaiting && !oldWidget.isWaiting) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isWaiting && oldWidget.isWaiting) {
      _animationController.stop();
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isWaiting) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.orange.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.waitingText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}