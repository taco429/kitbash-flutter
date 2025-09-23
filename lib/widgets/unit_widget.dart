import 'package:flutter/material.dart';
import '../models/unit.dart';

/// Widget to display a unit on the game board
class UnitWidget extends StatelessWidget {
  final GameUnit unit;
  final double tileSize;
  final bool isCurrentPlayer;
  final VoidCallback? onTap;

  const UnitWidget({
    super.key,
    required this.unit,
    required this.tileSize,
    required this.isCurrentPlayer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: tileSize,
        height: tileSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Unit sprite
            _buildUnitSprite(),

            // Health bar
            if (unit.isAlive) _buildHealthBar(),

            // Attack/Defense indicators
            _buildStatIndicators(),

            // Direction indicator (subtle)
            if (unit.isAlive) _buildDirectionIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitSprite() {
    // For now, use a colored circle with the unit's first letter
    // In production, this would load the actual sprite based on unit.getSpriteAsset()
    final color = isCurrentPlayer ? Colors.blue : Colors.red;
    final letter = unit.cardId.contains('goblin')
        ? 'G'
        : unit.cardId.contains('ghoul')
            ? 'Z'
            : 'U';

    return Container(
      width: tileSize * 0.8,
      height: tileSize * 0.8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.8),
        border: Border.all(
          color: color,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: tileSize * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHealthBar() {
    final barWidth = tileSize * 0.6;
    const barHeight = 6.0;

    return Positioned(
      bottom: 4,
      child: Container(
        width: barWidth,
        height: barHeight,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(barHeight / 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: Stack(
            children: [
              Container(
                width: barWidth * unit.healthPercentage,
                height: barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getHealthColors(),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getHealthColors() {
    final percentage = unit.healthPercentage;
    if (percentage > 0.6) {
      return [Colors.green.shade400, Colors.green.shade600];
    } else if (percentage > 0.3) {
      return [Colors.yellow.shade600, Colors.orange.shade600];
    } else {
      return [Colors.red.shade400, Colors.red.shade600];
    }
  }

  Widget _buildStatIndicators() {
    return Positioned(
      top: 2,
      right: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attack
            const Icon(
              Icons.local_fire_department,
              size: 10,
              color: Colors.orange,
            ),
            const SizedBox(width: 2),
            Text(
              '${unit.attack}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            // Health
            const Icon(
              Icons.favorite,
              size: 10,
              color: Colors.red,
            ),
            const SizedBox(width: 2),
            Text(
              '${unit.health}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionIndicator() {
    // Small arrow showing movement direction
    IconData arrowIcon;
    double rotation = 0;

    switch (unit.direction) {
      case UnitDirection.north:
        arrowIcon = Icons.arrow_upward;
        break;
      case UnitDirection.northEast:
        arrowIcon = Icons.arrow_upward;
        rotation = 45 * (3.14159 / 180);
        break;
      case UnitDirection.east:
        arrowIcon = Icons.arrow_forward;
        break;
      case UnitDirection.southEast:
        arrowIcon = Icons.arrow_downward;
        rotation = -45 * (3.14159 / 180);
        break;
      case UnitDirection.south:
        arrowIcon = Icons.arrow_downward;
        break;
      case UnitDirection.southWest:
        arrowIcon = Icons.arrow_downward;
        rotation = 45 * (3.14159 / 180);
        break;
      case UnitDirection.west:
        arrowIcon = Icons.arrow_back;
        break;
      case UnitDirection.northWest:
        arrowIcon = Icons.arrow_upward;
        rotation = -45 * (3.14159 / 180);
        break;
    }

    return Positioned(
      top: 2,
      left: 2,
      child: Transform.rotate(
        angle: rotation,
        child: Icon(
          arrowIcon,
          size: 12,
          color: Colors.white70,
        ),
      ),
    );
  }
}
