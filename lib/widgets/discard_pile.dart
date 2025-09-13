import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import 'advanced_card_display.dart';
import 'card_list_modal.dart';

class DiscardPile extends StatelessWidget {
  final List<GameCard> discardedCards;
  final List<CardInstance>? discardInstances;
  final String label;
  final Color accentColor;
  final VoidCallback? onTap;

  const DiscardPile({
    super.key,
    required this.discardedCards,
    this.discardInstances,
    required this.label,
    this.accentColor = Colors.grey,
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
            onTap: onTap ??
                () {
                  CardListModal.show(
                    context: context,
                    title: '$label Pile',
                    cards: discardedCards,
                    cardInstances: discardInstances,
                    accentColor: accentColor,
                    emptyMessage: 'The discard pile is empty',
                  );
                },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  if (discardedCards.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_clear,
                            size: 32,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Empty',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.3),
                                    ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Show top card of discard pile
                    Center(
                      child: AdvancedCardDisplay(
                        card: discardedCards.last,
                        width: 70,
                        height: 100,
                        enableParallax: false,
                        enableGlow: false,
                        enableShadow: true,
                      ),
                    ),
                    // Badge showing count
                    if (discardedCards.length > 1)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${discardedCards.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                  // Click indicator
                  Positioned(
                    bottom: 4,
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
