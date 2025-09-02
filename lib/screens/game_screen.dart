import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/kitbash_game.dart';

class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Game $gameId')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Opponent deck area (left)
                const SizedBox(
                  width: 110,
                  child: const _DeckPanel(title: 'Opponent Deck', count: 30),
                ),
                // Game area with Flame GameWidget in the middle
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: GameWidget.controlled(
                      gameFactory: () => KitbashGame(gameId: gameId),
                    ),
                  ),
                ),
                // Player deck area (right)
                const SizedBox(
                  width: 110,
                  child: const _DeckPanel(title: 'Your Deck', count: 30),
                ),
              ],
            ),
          ),
          // Player hand at the bottom
          const _HandBar(),
        ],
      ),
    );
  }
}

class _DeckPanel extends StatelessWidget {
  final String title;
  final int count;

  const _DeckPanel({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.layers, size: 32),
                  const SizedBox(height: 6),
                  Text('$count cards', style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandBar extends StatelessWidget {
  const _HandBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, -2), color: Colors.black26),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return AspectRatio(
            aspectRatio: 63 / 88,
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D2F36), Color(0xFF404556)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Card ${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
