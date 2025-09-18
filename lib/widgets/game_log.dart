import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../services/granular_game_state.dart';
import '../services/card_service.dart';

class GameLog extends StatelessWidget {
  final int maxRows;

  const GameLog({super.key, this.maxRows = 6});

  String _formatDiscard(RoundDiscardSummary summary) {
    final p0 = summary.playerToDiscardCount[0] ?? 0;
    final p1 = summary.playerToDiscardCount[1] ?? 0;
    return 'Round ${summary.roundNumber}: P1 discarded $p0, P2 discarded $p1';
  }

  String _formatPlay(BuildContext context, PlayEventEntry e) {
    final p = e.playerIndex + 1;
    final cardService = context.read<CardService>();
    final cardName = cardService.getCardById(e.cardId)?.name ?? e.cardId;
    return 'Round ${e.round}: P$p played $cardName at (${e.row}, ${e.col})';
  }

  @override
  Widget build(BuildContext context) {
    final gameService = context.read<GameService>();
    // Listen to both discard and play logs
    return ListenableBuilder(
      listenable:
          Listenable.merge([gameService.discardLog, gameService.playLog]),
      builder: (context, child) {
        final discards = gameService.discardLog.discardLog.toList()
          ..sort((a, b) => b.roundNumber.compareTo(a.roundNumber));
        final plays = gameService.playLog.entries.toList()
          ..sort((a, b) => b.round.compareTo(a.round));

        // Interleave by round, show latest first
        final lines = <String>[];
        int di = 0, pi = 0;
        while ((di < discards.length || pi < plays.length) &&
            lines.length < maxRows) {
          final nextDiscardRound =
              di < discards.length ? discards[di].roundNumber : -1;
          final nextPlayRound = pi < plays.length ? plays[pi].round : -1;
          if (nextPlayRound >= nextDiscardRound) {
            lines.add(_formatPlay(context, plays[pi++]));
          } else {
            lines.add(_formatDiscard(discards[di++]));
          }
        }

        return Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lines.isEmpty)
                Text(
                  'No events yet',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.greenAccent),
                )
              else
                ...lines.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      s,
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
