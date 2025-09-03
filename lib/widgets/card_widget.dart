import 'package:flutter/material.dart';
import '../models/card.dart';

/// A widget that displays a game card
class CardWidget extends StatelessWidget {
  final GameCard card;
  final bool isCompact;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.card,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Container(
          width: isCompact ? 120 : 180,
          height: isCompact ? 160 : 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getCardColors(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card name and cost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        card.name,
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (card.goldCost > 0) ...[
                            Icon(
                              Icons.monetization_on,
                              size: isCompact ? 10 : 12,
                              color: Colors.amber.shade700,
                            ),
                            Text(
                              '${card.goldCost}',
                              style: TextStyle(
                                fontSize: isCompact ? 10 : 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                          if (card.goldCost > 0 && card.manaCost > 0)
                            const SizedBox(width: 4),
                          if (card.manaCost > 0) ...[
                            Icon(
                              Icons.auto_awesome,
                              size: isCompact ? 10 : 12,
                              color: Colors.blue.shade700,
                            ),
                            Text(
                              '${card.manaCost}',
                              style: TextStyle(
                                fontSize: isCompact ? 10 : 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Card type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.type.displayName,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Description (if not compact)
                if (!isCompact) ...[
                  Text(
                    card.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Attack/Health (for units)
                if (card.isUnit && card.unitStats != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Attack
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flash_on,
                              size: 12,
                              color: Colors.white,
                            ),
                            Text(
                              '${card.unitStats?.attack ?? 0}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Health
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 12,
                              color: Colors.white,
                            ),
                            Text(
                              '${card.unitStats?.health ?? 0}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Abilities (if any)
                if (card.abilities.isNotEmpty && !isCompact) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: card.abilities.take(2).map((ability) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ability,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getCardColors() {
    switch (card.color) {
      case CardColor.red:
        return [Colors.red.shade400, Colors.red.shade800];
      case CardColor.orange:
        return [Colors.orange.shade400, Colors.orange.shade800];
      case CardColor.yellow:
        return [Colors.yellow.shade400, Colors.yellow.shade700];
      case CardColor.green:
        return [Colors.green.shade400, Colors.green.shade800];
      case CardColor.blue:
        return [Colors.blue.shade400, Colors.blue.shade800];
      case CardColor.purple:
        return [Colors.purple.shade400, Colors.purple.shade800];
    }
  }
}