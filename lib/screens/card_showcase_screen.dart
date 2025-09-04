import 'package:flutter/material.dart';
import '../models/card.dart';
import '../widgets/card_display.dart';

class CardShowcaseScreen extends StatelessWidget {
  const CardShowcaseScreen({super.key});

  GameCard _sampleCard() {
    return GameCard(
      id: 'sample_001',
      name: 'Celestial Vanguard',
      description: 'A stalwart guardian clad in radiant armor. Inspires allies and shatters foes.',
      goldCost: 3,
      manaCost: 2,
      type: CardType.unit,
      color: CardColor.blue,
      unitStats: const UnitStats(attack: 3, health: 4, armor: 1, speed: 2, range: 1),
      abilities: const ['Inspire', 'Aegis'],
      flavorText: 'The night sky is their banner.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final GameCard card = _sampleCard();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Showcase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildTitledCard(
                title: 'Standard',
                child: CardDisplay(
                  card: card,
                  artAsset: null, // no assets yet; shows vibrant placeholder
                  width: 180,
                ),
              ),
              _buildTitledCard(
                title: 'Alternate Art',
                child: CardDisplay(
                  card: card,
                  effects: const {CardStyleEffect.alternateArt},
                  artAsset: null,
                  alternateArtAsset: null,
                  width: 180,
                ),
              ),
              _buildTitledCard(
                title: 'Borderless',
                child: CardDisplay(
                  card: card,
                  effects: const {CardStyleEffect.borderless},
                  width: 180,
                ),
              ),
              _buildTitledCard(
                title: 'Frame Break',
                child: CardDisplay(
                  card: card,
                  effects: const {CardStyleEffect.frameBreak},
                  width: 180,
                ),
              ),
              _buildTitledCard(
                title: 'Holographic',
                child: CardDisplay(
                  card: card,
                  effects: const {CardStyleEffect.holographic},
                  width: 180,
                ),
              ),
              _buildTitledCard(
                title: 'Borderless + Holo',
                child: CardDisplay(
                  card: card,
                  effects: const {CardStyleEffect.borderless, CardStyleEffect.holographic},
                  width: 180,
                ),
              ),
              _buildTitledCard(
                title: 'Frame Break + Holo',
                child: CardDisplay(
                  card: card,
                  effects: const {CardStyleEffect.frameBreak, CardStyleEffect.holographic},
                  width: 180,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitledCard({required String title, required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

