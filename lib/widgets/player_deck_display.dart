import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import 'card_list_modal.dart';

class PlayerDeckDisplay extends StatelessWidget {
  final int remainingCards;
  final String label;
  final Color accentColor;
  final List<GameCard>? deckCards;
  final List<CardInstance>? deckInstances;
  final VoidCallback? onTap;

  const PlayerDeckDisplay({
    super.key,
    required this.remainingCards,
    required this.label,
    this.accentColor = Colors.blue,
    this.deckCards,
    this.deckInstances,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap ?? (deckCards != null ? () {
              CardListModal.show(
                context: context,
                title: '$label Contents',
                cards: deckCards!,
                cardInstances: deckInstances,
                accentColor: accentColor,
                emptyMessage: 'The deck is empty',
              );
            } : null),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.1),
                    accentColor.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Card back design
                  Icon(
                    Icons.style,
                    size: 40,
                    color: accentColor.withValues(alpha: 0.3),
                  ),
                  // Remaining cards count
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$remainingCards',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'cards',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: accentColor.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                  // Click indicator when clickable
                  if (onTap != null || deckCards != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.visibility,
                        size: 16,
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
