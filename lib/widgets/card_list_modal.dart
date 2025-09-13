import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/card_instance.dart';
import 'advanced_card_display.dart';

/// A modal dialog that displays a list of cards
class CardListModal extends StatelessWidget {
  final String title;
  final List<GameCard> cards;
  final List<CardInstance>? cardInstances;
  final Color accentColor;
  final String emptyMessage;

  const CardListModal({
    super.key,
    required this.title,
    required this.cards,
    this.cardInstances,
    this.accentColor = Colors.blue,
    this.emptyMessage = 'No cards',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 600,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.style,
                    color: accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${cards.length} cards',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: accentColor.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Card list
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_clear,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyMessage,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final instance = cardInstances != null &&
                                  index < cardInstances!.length
                              ? cardInstances![index]
                              : null;

                          return Column(
                            children: [
                              Expanded(
                                child: AdvancedCardDisplay(
                                  card: card,
                                  width: double.infinity,
                                  height: double.infinity,
                                  enableParallax: false,
                                  enableGlow: false,
                                  enableShadow: true,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.name,
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (instance != null &&
                                  instance.instanceId.isNotEmpty)
                                Text(
                                  'ID: ${instance.instanceId.substring(0, 8)}...',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static void show({
    required BuildContext context,
    required String title,
    required List<GameCard> cards,
    List<CardInstance>? cardInstances,
    Color accentColor = Colors.blue,
    String emptyMessage = 'No cards',
  }) {
    showDialog(
      context: context,
      builder: (context) => CardListModal(
        title: title,
        cards: cards,
        cardInstances: cardInstances,
        accentColor: accentColor,
        emptyMessage: emptyMessage,
      ),
    );
  }
}
