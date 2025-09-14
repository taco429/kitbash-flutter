import 'package:flutter/material.dart';
import 'phase_indicator.dart';

class TurnIndicator extends StatefulWidget {
  final int turnNumber;
  final bool player1Locked;
  final bool player2Locked;
  final String currentPhase;
  final DateTime? phaseStartTime;

  const TurnIndicator({
    super.key,
    required this.turnNumber,
    required this.player1Locked,
    required this.player2Locked,
    required this.currentPhase,
    this.phaseStartTime,
  });

  @override
  State<TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<TurnIndicator> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Turn number above phase icons
          Text(
            'Turn ${widget.turnNumber}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Phase icons row
          PhaseIndicator(
            currentPhase: widget.currentPhase,
            phaseStartTime: widget.phaseStartTime,
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
