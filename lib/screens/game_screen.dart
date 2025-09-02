import 'package:flutter/material.dart';
// Removed Flame GameWidget for now; simple text placeholder

class GameScreen extends StatelessWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('In Game')),
      body: Center(
        child: Text(
          'game $gameId',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
