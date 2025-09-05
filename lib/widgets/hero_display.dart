import 'package:flutter/material.dart';
import '../models/card.dart';
import 'advanced_card_display.dart';

class HeroDisplay extends StatelessWidget {
  final GameCard? heroCard;
  final String playerName;
  final Color accentColor;

  const HeroDisplay({
    super.key,
    this.heroCard,
    required this.playerName,
    this.accentColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playerName,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 90,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: heroCard == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 40,
                        color: accentColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No Hero',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AdvancedCardDisplay(
                    card: heroCard!,
                    width: 86,
                    height: 116,
                    enableParallax: false,
                    enableGlow: true,
                    enableShadow: false,
                  ),
                ),
        ),
        // Show hero stats if available
        if (heroCard != null && heroCard!.heroStats != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatBadge(
                  icon: Icons.flash_on,
                  value: heroCard!.heroStats!.attack,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  icon: Icons.favorite,
                  value: heroCard!.heroStats!.health,
                  color: Colors.green,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
