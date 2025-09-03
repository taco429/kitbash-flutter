import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';

class DeckSelector extends StatelessWidget {
  const DeckSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeckService>(
      builder: (context, deckService, child) {
        if (deckService.isLoading) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Deck',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        if (deckService.error != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Your Deck',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deckService.error ?? 'Failed to load decks',
                        style: TextStyle(color: Colors.red.shade700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => deckService.loadDecks(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Your Deck',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (deckService.availableDecks.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    const Text('No decks available'),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => deckService.loadDecks(),
                      child: const Text('Reload'),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: deckService.availableDecks.length,
                  itemBuilder: (context, index) {
                    final deck = deckService.availableDecks[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: DeckCard(
                        deck: deck,
                        isSelected: deckService.isDeckSelected(deck),
                        onTap: () => deckService.selectDeck(deck),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            if (deckService.selectedDeck != null)
              Text(
                'Selected: ${deckService.selectedDeck!.name}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        );
      },
    );
  }
}

class DeckCard extends StatelessWidget {
  final Deck deck;
  final bool isSelected;
  final VoidCallback onTap;

  const DeckCard({
    super.key,
    required this.deck,
    required this.isSelected,
    required this.onTap,
  });

  Color _getDeckColor() {
    switch (deck.color.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckColor = _getDeckColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              deckColor.withValues(alpha: 0.8),
              deckColor.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: deckColor.withValues(alpha: 0.3),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getDeckIcon(),
                    color: Colors.white,
                    size: 20,
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                deck.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${deck.cardCount} cards',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeckIcon() {
    switch (deck.color.toLowerCase()) {
      case 'red':
        return Icons.local_fire_department;
      case 'purple':
        return Icons.auto_awesome;
      case 'blue':
        return Icons.water_drop;
      case 'green':
        return Icons.eco;
      case 'yellow':
        return Icons.wb_sunny;
      default:
        return Icons.style;
    }
  }
}
