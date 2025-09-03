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
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${card.cost}',
                        style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.bold,
                          color: _getCardColors().first,
                        ),
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
                    color: Colors.white.withOpacity(0.8),
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
                
                // Attack/Health (for creatures)
                if (card.isCreature) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Attack
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
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
                              '${card.attack ?? 0}',
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
                          color: Colors.green.withOpacity(0.8),
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
                              '${card.health ?? 0}',
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
                          color: Colors.white.withOpacity(0.7),
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
      case CardColor.purple:
        return [Colors.purple.shade400, Colors.purple.shade800];
      case CardColor.blue:
        return [Colors.blue.shade400, Colors.blue.shade800];
      case CardColor.green:
        return [Colors.green.shade400, Colors.green.shade800];
      case CardColor.white:
        return [Colors.grey.shade200, Colors.grey.shade500];
      case CardColor.black:
        return [Colors.grey.shade700, Colors.black];
      case CardColor.neutral:
        return [Colors.grey.shade400, Colors.grey.shade700];
    }
  }
}