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

class OpponentIndicator extends StatelessWidget {
  final PlayerBattleState? opponentState;

  const OpponentIndicator({super.key, this.opponentState});

  @override
  Widget build(BuildContext context) {
    final cardService = context.watch<CardService>();

    return Consumer<DeckService>(
      builder: (context, deckService, child) {
        GameCard? heroCard;
        if (opponentState?.deckId != null && opponentState!.deckId.isNotEmpty) {
          final deck = deckService.availableDecks.firstWhere(
            (d) => d.id == opponentState!.deckId,
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

        final drawPileCards = (opponentState?.drawPile ?? [])
            .map((instance) => cardService.getCardById(instance.cardId))
            .whereType<GameCard>()
            .toList();

        final discardCards = (opponentState?.discardPile ?? [])
            .map((instance) => cardService.getCardById(instance.cardId))
            .whereType<GameCard>()
            .toList();

        final int remaining = opponentState?.deckCount ?? drawPileCards.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                blurRadius: 6,
                offset: Offset(0, 2),
                color: Colors.black26,
              ),
            ],
          ),
          child: Row(
            children: [
              HeroDisplay(
                heroCard: heroCard,
                playerName: 'Opponent',
                accentColor: Colors.pink,
              ),
              const Spacer(),
              PlayerDeckDisplay(
                remainingCards: remaining,
                label: 'Deck',
                accentColor: Colors.pink,
                deckCards: drawPileCards,
                deckInstances: opponentState?.drawPile,
              ),
              const SizedBox(width: 12),
              DiscardPile(
                discardedCards: discardCards,
                discardInstances: opponentState?.discardPile,
                label: 'Discard',
                accentColor: Colors.pink,
              ),
            ],
          ),
        );
      },
    );
  }
}
