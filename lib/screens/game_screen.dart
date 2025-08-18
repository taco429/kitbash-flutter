import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/kitbash_game.dart';

class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: KitbashGame(gameId: gameId),
      ),
    );
  }
}
