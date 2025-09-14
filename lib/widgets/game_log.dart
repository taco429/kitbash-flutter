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
    final gameService = context.read<GameService>();
    // Listen only to discard log changes, not entire GameService
    return ListenableBuilder(
      listenable: gameService.discardLog,
      builder: (context, child) {
        final entries = gameService.discardLog.discardLog.toList()
          ..sort((a, b) => b.roundNumber.compareTo(a.roundNumber));

        final visible = entries.take(maxRows).toList();

        return Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visible.isEmpty)
                Text(
                  'No events yet',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.greenAccent),
                )
              else
                ...visible.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _formatEntry(s),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.greenAccent),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
