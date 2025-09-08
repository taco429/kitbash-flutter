import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/card_drag_payload.dart';
import '../services/game_service.dart';
import 'advanced_card_display.dart';

class CardPreviewPanel extends StatelessWidget {
  final CardDragPayload payload;

  const CardPreviewPanel({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    final GameCard card = payload.card;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double cardWidth = (width - 24).clamp(180.0, 280.0);
        // Maintain the same aspect ratio as hand cards (approx 160/110)
        final double aspectRatio = 160.0 / 110.0;
        final double cardHeight = cardWidth * aspectRatio;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(left: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(-2, 0)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with title and close
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.12), width: 1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Card Preview',
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<GameService>().clearCardPreview();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Card on top
                      Center(
                        child: AdvancedCardDisplay(
                          card: card,
                          width: cardWidth,
                          height: cardHeight,
                          enableParallax: true,
                          enableGlow: true,
                          enableShadow: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Details below
                      _DetailsSection(card: card),
                    ],
                  ),
                ),
              ),
              // Play button
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final gs = context.read<GameService>();
                      gs.beginCardPlacement(payload);
                      gs.clearCardPreview();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Select a tile on the board to play this card'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play This Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade400,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final GameCard card;

  const _DetailsSection({required this.card});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.name,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(icon: Icons.category, label: card.type.displayName, color: Colors.blueAccent),
              _pill(icon: Icons.palette, label: card.color.displayName, color: _colorForCardColor(card.color)),
              if (card.goldCost > 0)
                _pill(icon: Icons.monetization_on, label: '${card.goldCost} Gold', color: Colors.amber.shade700),
              if (card.manaCost > 0)
                _pill(icon: Icons.auto_awesome, label: '${card.manaCost} Mana', color: Colors.lightBlueAccent),
            ],
          ),
          const SizedBox(height: 10),
          if (card.description.isNotEmpty)
            Text(
              card.description,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9), height: 1.3),
            ),
          if (card.description.isNotEmpty) const SizedBox(height: 10),
          if (card.isUnit && card.unitStats != null)
            _statsSection(title: 'Unit Stats', items: [
              _statItem(Icons.flash_on, 'Attack', '${card.unitStats!.attack}', Colors.redAccent),
              _statItem(Icons.favorite, 'Health', '${card.unitStats!.health}', Colors.greenAccent),
              _statItem(Icons.shield, 'Armor', '${card.unitStats!.armor}', Colors.blueAccent),
              _statItem(Icons.speed, 'Speed', '${card.unitStats!.speed}', Colors.yellowAccent),
              _statItem(Icons.straighten, 'Range', '${card.unitStats!.range}', Colors.purpleAccent),
            ]),
          if (card.isBuilding && card.buildingStats != null)
            _statsSection(title: 'Building Stats', items: [
              _statItem(Icons.favorite, 'Health', '${card.buildingStats!.health}', Colors.greenAccent),
              _statItem(Icons.shield, 'Armor', '${card.buildingStats!.armor}', Colors.blueAccent),
              if (card.buildingStats!.attack != null)
                _statItem(Icons.flash_on, 'Attack', '${card.buildingStats!.attack}', Colors.redAccent),
              if (card.buildingStats!.range != null)
                _statItem(Icons.straighten, 'Range', '${card.buildingStats!.range}', Colors.purpleAccent),
            ]),
          if (card.isHero && card.heroStats != null)
            _statsSection(title: 'Hero Stats', items: [
              _statItem(Icons.flash_on, 'Attack', '${card.heroStats!.attack}', Colors.redAccent),
              _statItem(Icons.favorite, 'Health', '${card.heroStats!.health}', Colors.greenAccent),
              _statItem(Icons.shield, 'Armor', '${card.heroStats!.armor}', Colors.blueAccent),
              _statItem(Icons.speed, 'Speed', '${card.heroStats!.speed}', Colors.yellowAccent),
              _statItem(Icons.straighten, 'Range', '${card.heroStats!.range}', Colors.purpleAccent),
              _statItem(Icons.timer, 'Cooldown', '${card.heroStats!.cooldown}', Colors.orangeAccent),
            ]),
          if (card.abilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Abilities', style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.abilities
                  .map((a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                        ),
                        child: Text(
                          a,
                          style: textTheme.bodySmall?.copyWith(
                            color: onSurface.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (card.flavorText != null && card.flavorText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${card.flavorText}”',
              style: textTheme.bodySmall?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statsSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(spacing: 10, runSpacing: 10, children: items),
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
            child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _colorForCardColor(CardColor color) {
    switch (color) {
      case CardColor.red:
        return Colors.redAccent;
      case CardColor.orange:
        return Colors.orangeAccent;
      case CardColor.yellow:
        return Colors.amberAccent;
      case CardColor.green:
        return Colors.lightGreenAccent;
      case CardColor.blue:
        return Colors.lightBlueAccent;
      case CardColor.purple:
        return Colors.purpleAccent;
    }
  }
}

