import 'package:flutter/material.dart';
import 'game_lobby_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitbash CCG'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Kitbash CCG Title',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement deck builder
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deck Builder coming soon!')),
                );
              },
              child: const Text('Deck Builder'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GameLobbyScreen(),
                  ),
                );
              },
              child: const Text('Find Games'),
            ),
          ],
        ),
      ),
    );
  }
}
