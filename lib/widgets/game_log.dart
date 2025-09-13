import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';

class GameLog extends StatelessWidget {
  final int maxRows;

  const GameLog({super.key, this.maxRows = 6});

  String _formatEntry(RoundDiscardSummary summary) {
    final p0 = summary.playerToDiscardCount[0] ?? 0;
    final p1 = summary.playerToDiscardCount[1] ?? 0;
    return 'Round ${summary.roundNumber}: P1 discarded $p0, P2 discarded $p1';
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.watch<GameService>();
    final entries = gameService.discardLog.toList()
      ..sort((a, b) => b.roundNumber.compareTo(a.roundNumber));

    final visible = entries.take(maxRows).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 16),
              const SizedBox(width: 6),
              Text(
                'Game Log',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (visible.isEmpty)
            Text(
              'No events yet',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...visible.map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  _formatEntry(s),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

