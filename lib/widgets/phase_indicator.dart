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

class _PhaseIndicatorState extends State<PhaseIndicator> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
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
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = GamePhase.fromString(widget.currentPhase);
    // Render four phase icons and highlight the active one
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPhaseIcon(GamePhase.drawIncome, phase == GamePhase.drawIncome),
          const SizedBox(width: 8),
          _buildPhaseIcon(
            GamePhase.planning,
            phase == GamePhase.planning,
            seconds: phase == GamePhase.planning && _remainingSeconds > 0
                ? _remainingSeconds
                : null,
          ),
          const SizedBox(width: 8),
          _buildPhaseIcon(
            GamePhase.revealResolve,
            phase == GamePhase.revealResolve,
          ),
          const SizedBox(width: 8),
          _buildPhaseIcon(GamePhase.cleanup, phase == GamePhase.cleanup),
        ],
      ),
    );
  }
}

Widget _buildPhaseIcon(
  GamePhase phaseType,
  bool isActive, {
  int? seconds,
}) {
  final Color color;
  final IconData icon;
  switch (phaseType) {
    case GamePhase.drawIncome:
      color = Colors.blue;
      icon = Icons.style;
      break;
    case GamePhase.planning:
      color = Colors.orange;
      icon = Icons.timer;
      break;
    case GamePhase.revealResolve:
      color = Colors.purple;
      icon = Icons.visibility;
      break;
    case GamePhase.cleanup:
      color = Colors.green;
      icon = Icons.cleaning_services;
      break;
  }

  return Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.9)
                : color.withValues(alpha: 0.4),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : Colors.black87,
        ),
      ),
      if (seconds != null)
        Positioned(
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              '${seconds}s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
    ],
  );
}
