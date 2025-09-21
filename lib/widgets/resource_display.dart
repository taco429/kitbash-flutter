import 'package:flutter/material.dart';
import '../models/resources.dart';

/// Widget to display player resources (gold and mana)
class ResourceDisplay extends StatelessWidget {
  final Resources resources;
  final ResourceGeneration? income;
  final bool isCurrentPlayer;
  final bool compact;

  const ResourceDisplay({
    Key? key,
    required this.resources,
    this.income,
    this.isCurrentPlayer = false,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactDisplay(context);
    }
    return _buildFullDisplay(context);
  }

  Widget _buildCompactDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentPlayer
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentPlayer
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildResourceIcon(
            icon: Icons.monetization_on,
            color: Colors.amber,
            value: resources.gold,
            income: income?.gold,
          ),
          const SizedBox(width: 16),
          _buildResourceIcon(
            icon: Icons.water_drop,
            color: Colors.blue,
            value: resources.mana,
            income: income?.mana,
          ),
        ],
      ),
    );
  }

  Widget _buildFullDisplay(BuildContext context) {
    return Card(
      elevation: isCurrentPlayer ? 4 : 2,
      color: isCurrentPlayer
          ? Theme.of(context).primaryColor.withOpacity(0.05)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Resources',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrentPlayer
                        ? Theme.of(context).primaryColor
                        : null,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildResourceTile(
                    context: context,
                    icon: Icons.monetization_on,
                    color: Colors.amber,
                    label: 'Gold',
                    value: resources.gold,
                    income: income?.gold,
                    tooltip: 'Gold accumulates each turn',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildResourceTile(
                    context: context,
                    icon: Icons.water_drop,
                    color: Colors.blue,
                    label: 'Mana',
                    value: resources.mana,
                    income: income?.mana,
                    tooltip: 'Mana resets each turn',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceIcon({
    required IconData icon,
    required Color color,
    required int value,
    int? income,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (income != null && income > 0) ...[
          const SizedBox(width: 2),
          Text(
            '(+$income)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResourceTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required int value,
    int? income,
    String? tooltip,
  }) {
    final tile = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
          if (income != null && income > 0)
            Text(
              '+$income/turn',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: tile,
      );
    }
    return tile;
  }
}

/// Widget to display resource cost for cards
class ResourceCost extends StatelessWidget {
  final int? goldCost;
  final int? manaCost;
  final bool canAfford;
  final bool compact;

  const ResourceCost({
    Key? key,
    this.goldCost,
    this.manaCost,
    this.canAfford = true,
    this.compact = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (goldCost == null && manaCost == null) {
      return const SizedBox.shrink();
    }

    final opacity = canAfford ? 1.0 : 0.5;
    final costs = <Widget>[];

    if (goldCost != null && goldCost! > 0) {
      costs.add(_buildCostBadge(
        icon: Icons.monetization_on,
        color: Colors.amber.withOpacity(opacity),
        value: goldCost!,
        canAfford: canAfford,
      ));
    }

    if (manaCost != null && manaCost! > 0) {
      if (costs.isNotEmpty) costs.add(const SizedBox(width: 4));
      costs.add(_buildCostBadge(
        icon: Icons.water_drop,
        color: Colors.blue.withOpacity(opacity),
        value: manaCost!,
        canAfford: canAfford,
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: costs,
    );
  }

  Widget _buildCostBadge({
    required IconData icon,
    required Color color,
    required int value,
    required bool canAfford,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: canAfford ? color : Colors.red.shade400,
          ),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: canAfford ? Colors.black87 : Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}