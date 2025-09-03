import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/kitbash_game.dart';
import '../models/tile_data.dart';
import 'game_tooltip.dart';

/// A widget that wraps the KitbashGame with tooltip functionality
class GameWithTooltip extends StatefulWidget {
  final KitbashGame game;

  const GameWithTooltip({
    super.key,
    required this.game,
  });

  @override
  State<GameWithTooltip> createState() => _GameWithTooltipState();
}

class _GameWithTooltipState extends State<GameWithTooltip> {
  TileData? _hoveredTile;
  Offset? _hoverPosition;
  Timer? _tooltipTimer;
  bool _showTooltip = false;

  static const Duration _tooltipDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    // Set up the hover callback for the game
    widget.game.setTileHoverCallback(_onTileHover);
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _onTileHover(TileData? tileData, Offset? position) {
    setState(() {
      _hoveredTile = tileData;
      _hoverPosition = position;
    });

    // Cancel existing timer
    _tooltipTimer?.cancel();

    if (tileData != null && position != null) {
      // Start new timer for showing tooltip
      _tooltipTimer = Timer(_tooltipDelay, () {
        if (mounted && _hoveredTile == tileData) {
          setState(() {
            _showTooltip = true;
          });
        }
      });
    } else {
      // Hide tooltip immediately when not hovering
      setState(() {
        _showTooltip = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The Flame game
        GameWidget.controlled(
          gameFactory: () => widget.game,
        ),
        // Tooltip overlay
        GameTooltip(
          tileData: _hoveredTile,
          position: _hoverPosition,
          isVisible: _showTooltip,
        ),
      ],
    );
  }
}
