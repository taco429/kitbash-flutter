import 'package:flutter/material.dart';
import '../models/tile_data.dart';

/// A custom tooltip widget for displaying tile information in the game
class GameTooltip extends StatefulWidget {
  final TileData? tileData;
  final Offset? position;
  final bool isVisible;

  const GameTooltip({
    super.key,
    this.tileData,
    this.position,
    required this.isVisible,
  });

  @override
  State<GameTooltip> createState() => _GameTooltipState();
}

class _GameTooltipState extends State<GameTooltip> {
  // Animations removed for performance - tooltip now appears instantly

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible ||
        widget.tileData == null ||
        widget.position == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: widget.position!.dx + 10, // Slight offset from cursor
      top: widget.position!.dy - 60, // Above the cursor
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: Colors.black87,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 200,
            minWidth: 120,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTooltipContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTooltipContent() {
    final tileData = widget.tileData!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tile coordinates
        Text(
          'Tile (${tileData.row}, ${tileData.col})',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),

        // Terrain information
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTerrainIcon(tileData.terrain),
              size: 16,
              color: _getTerrainColor(tileData.terrain),
            ),
            const SizedBox(width: 6),
            Text(
              tileData.terrain.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Building information
        if (tileData.building != null) ...[
          const SizedBox(height: 6),
          _buildEntityInfo(
            icon: Icons.business,
            name: tileData.building!.name,
            playerIndex: tileData.building!.playerIndex,
            health: tileData.building!.health,
            maxHealth: tileData.building!.maxHealth,
          ),
        ],

        // Unit information
        if (tileData.unit != null) ...[
          const SizedBox(height: 6),
          _buildEntityInfo(
            icon: _getUnitIcon(tileData.unit!.type),
            name: tileData.unit!.name,
            playerIndex: tileData.unit!.playerIndex,
            health: tileData.unit!.health,
            maxHealth: tileData.unit!.maxHealth,
          ),
        ],
      ],
    );
  }

  Widget _buildEntityInfo({
    required IconData icon,
    required String name,
    required int playerIndex,
    required int health,
    required int maxHealth,
  }) {
    final healthPercentage = maxHealth > 0 ? health / maxHealth : 0.0;
    final playerColor = playerIndex == 0 ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: playerColor,
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: playerColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 18), // Align with icon
            Text(
              'Player ${playerIndex + 1}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 18), // Align with icon
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: healthPercentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: healthPercentage > 0.3 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$health/$maxHealth',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getTerrainIcon(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.grass:
        return Icons.grass;
      case TerrainType.stone:
        return Icons.terrain;
      case TerrainType.water:
        return Icons.water;
      case TerrainType.desert:
        return Icons.wb_sunny;
      case TerrainType.forest:
        return Icons.park;
      case TerrainType.mountain:
        return Icons.landscape;
    }
  }

  Color _getTerrainColor(TerrainType terrain) {
    switch (terrain) {
      case TerrainType.grass:
        return Colors.green;
      case TerrainType.stone:
        return Colors.grey;
      case TerrainType.water:
        return Colors.blue;
      case TerrainType.desert:
        return Colors.orange;
      case TerrainType.forest:
        return Colors.green.shade700;
      case TerrainType.mountain:
        return Colors.brown;
    }
  }

  IconData _getUnitIcon(UnitType type) {
    switch (type) {
      case UnitType.infantry:
        return Icons.person;
      case UnitType.cavalry:
        return Icons.directions_run;
      case UnitType.archer:
        return Icons.my_location;
      case UnitType.mage:
        return Icons.auto_fix_high;
    }
  }
}
