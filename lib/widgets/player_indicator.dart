import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_service.dart';
import '../services/deck_service.dart';
import '../services/card_service.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../widgets/hero_display.dart';
import '../widgets/player_deck_display.dart';
import '../widgets/discard_pile.dart';
import '../widgets/resource_display.dart';
import '../models/resources.dart';

/// A reusable player indicator widget that displays player information
/// including hero, deck, discard pile, and resources.
/// Can be used for both the current player and opponents.
class PlayerIndicator extends StatelessWidget {
  final PlayerBattleState? playerState;
  final String playerName;
  final Color accentColor;
  final bool isCurrentPlayer;
  final bool showResources;
  final bool compact;
  final double? maxWidth;

  const PlayerIndicator({
    super.key,
    required this.playerState,
    required this.playerName,
    required this.accentColor,
    this.isCurrentPlayer = false,
    this.showResources = true,
    this.compact = true,
    this.maxWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    final cardService = context.watch<CardService>();

    return Consumer<DeckService>(
      builder: (context, deckService, child) {
        GameCard? heroCard;
        if (playerState?.deckId != null && playerState!.deckId.isNotEmpty) {
          final deck = deckService.availableDecks.firstWhere(
            (d) => d.id == playerState!.deckId,
            orElse: () =>
                deckService.selectedDeck ??
                (deckService.availableDecks.isNotEmpty
                    ? deckService.availableDecks.first
                    : Deck(
                        id: '',
                        name: '',
                        color: '',
                        description: '',
                      )),
          );
          if (deck.heroCardId != null) {
            heroCard = cardService.getCardById(deck.heroCardId!);
          }
        }

        final drawPileCards = (playerState?.drawPile ?? [])
            .map((instance) => cardService.getCardById(instance.cardId))
            .whereType<GameCard>()
            .toList();

        final discardCards = (playerState?.discardPile ?? [])
            .map((instance) => cardService.getCardById(instance.cardId))
            .whereType<GameCard>()
            .toList();

        final int remaining = playerState?.deckCount ?? drawPileCards.length;

        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeroDisplay(
                  heroCard: heroCard,
                  playerName: playerName,
                  accentColor: accentColor,
                ),
                const SizedBox(width: 12),
                PlayerDeckDisplay(
                  remainingCards: remaining,
                  label: 'Deck',
                  accentColor: accentColor,
                  deckCards: drawPileCards,
                  deckInstances: playerState?.drawPile,
                ),
                const SizedBox(width: 12),
                DiscardPile(
                  discardedCards: discardCards,
                  discardInstances: playerState?.discardPile,
                  label: 'Discard',
                  accentColor: accentColor,
                ),
              ],
            ),
            if (showResources) ...[
              const SizedBox(height: 8),
              ResourceDisplay(
                resources: playerState?.resources ??
                    const Resources(gold: 0, mana: 0),
                income: playerState?.resourceIncome,
                isCurrentPlayer: isCurrentPlayer,
                compact: compact,
              ),
            ],
          ],
        );

        // If not compact or no maxWidth constraint, return content directly
        if (!compact && maxWidth == null) {
          return content;
        }

        // Otherwise, wrap in a styled container
        Widget wrappedContent = Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 6,
                  offset: Offset(0, 2),
                  color: Colors.black26,
                ),
              ],
            ),
            child: content,
          ),
        );

        // Apply max width constraint if specified
        if (maxWidth != null) {
          wrappedContent = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth!),
            child: wrappedContent,
          );
        }

        return wrappedContent;
      },
    );
  }
}