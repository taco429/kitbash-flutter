import 'package:flutter/material.dart';
import 'dart:async';

enum GamePhase {
  drawIncome('Draw & Income', 'draw_income'),
  planning('Planning', 'planning'),
  revealResolve('Reveal & Resolve', 'reveal_resolve'),
  cleanup('Cleanup', 'cleanup');

  final String displayName;
  final String value;

  const GamePhase(this.displayName, this.value);

  static GamePhase fromString(String value) {
    return GamePhase.values.firstWhere(
      (phase) => phase.value == value,
      orElse: () => GamePhase.drawIncome,
    );
  }
}

class PhaseIndicator extends StatefulWidget {
  final String currentPhase;
  final DateTime? phaseStartTime;
  final VoidCallback? onTimerExpired;

  const PhaseIndicator({
    super.key,
    required this.currentPhase,
    this.phaseStartTime,
    this.onTimerExpired,
  });

  @override
  State<PhaseIndicator> createState() => _PhaseIndicatorState();
}

class _PhaseIndicatorState extends State<PhaseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  GamePhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
    _updatePhase();
  }

  @override
  void didUpdateWidget(PhaseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPhase != widget.currentPhase ||
        oldWidget.phaseStartTime != widget.phaseStartTime) {
      _updatePhase();
    }
  }

  void _updatePhase() {
    final phase = GamePhase.fromString(widget.currentPhase);

    // Trigger phase change animation
    if (_lastPhase != null && _lastPhase != phase) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
    _lastPhase = phase;

    // Cancel existing timer
    _countdownTimer?.cancel();

    // Start countdown for Planning phase
    if (phase == GamePhase.planning && widget.phaseStartTime != null) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    const planningDuration = 30; // seconds

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsed =
          DateTime.now().difference(widget.phaseStartTime!).inSeconds;
      final remaining = planningDuration - elapsed;

      setState(() {
        _remainingSeconds = remaining > 0 ? remaining : 0;
      });

      if (remaining <= 0) {
        timer.cancel();
        widget.onTimerExpired?.call();
      }
    });

    // Initial calculation
    final elapsed = DateTime.now().difference(widget.phaseStartTime!).inSeconds;
    _remainingSeconds = (planningDuration - elapsed).clamp(0, planningDuration);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Color _getPhaseColor(GamePhase phase) {
    switch (phase) {
      case GamePhase.drawIncome:
        return Colors.blue;
      case GamePhase.planning:
        return Colors.orange;
      case GamePhase.revealResolve:
        return Colors.purple;
      case GamePhase.cleanup:
        return Colors.green;
    }
  }

  IconData _getPhaseIcon(GamePhase phase) {
    switch (phase) {
      case GamePhase.drawIncome:
        return Icons.style; // Card draw icon
      case GamePhase.planning:
        return Icons.timer;
      case GamePhase.revealResolve:
        return Icons.visibility;
      case GamePhase.cleanup:
        return Icons.cleaning_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = GamePhase.fromString(widget.currentPhase);
    final phaseColor = _getPhaseColor(phase);
    final phaseIcon = _getPhaseIcon(phase);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: phase == GamePhase.planning ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  phaseColor.withValues(alpha: 0.8),
                  phaseColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: phaseColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  phaseIcon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phase',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                    ),
                    Text(
                      phase.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (phase == GamePhase.planning && _remainingSeconds > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSeconds <= 5
                          ? Colors.red
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_remainingSeconds}s',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
