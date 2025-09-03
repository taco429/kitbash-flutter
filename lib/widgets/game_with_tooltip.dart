import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:logging/logging.dart';
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
  final Logger _log = Logger('UI.GameWithTooltip');
  TileData? _hoveredTile;
  Offset? _hoverPosition;
  Timer? _tooltipTimer;
  bool _showTooltip = false;

  static const Duration _tooltipDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _onTileHover(TileData? tileData, Offset? position) {
    _log.info(
      'onTileHover: tile='
      '${tileData != null ? 'r=${tileData.row},c=${tileData.col},terrain=${tileData.terrain},building=${tileData.building?.type}' : 'null'}'
      ', pos=${position?.toString() ?? 'null'}',
    );
    final bool sameTile = _isSameTile(_hoveredTile, tileData);

    // Always update current hover snapshot
    setState(() {
      _hoveredTile = tileData;
      _hoverPosition = position;
    });

    // If cursor left the board or position is invalid -> hide immediately
    if (tileData == null || position == null) {
      _tooltipTimer?.cancel();
      if (_showTooltip) {
        setState(() {
          _showTooltip = false;
        });
      }
      _log.info('onTileHover: cleared (out of bounds or null)');
      return;
    }

    // If already visible, keep it visible and just follow the cursor
    if (_showTooltip) {
      _log.info('onTileHover: tooltip visible, updating position only');
      return;
    }

    // If hovering the same tile as before and waiting, don't reset the timer
    if (sameTile) {
      _log.info('onTileHover: same tile, timer retained');
      return;
    }

    // Tile changed: restart timer and ensure hidden until delay elapses
    _tooltipTimer?.cancel();
    _showTooltip = false;
    _tooltipTimer = Timer(_tooltipDelay, () {
      if (!mounted) return;
      if (_isSameTile(_hoveredTile, tileData)) {
        setState(() {
          _showTooltip = true;
        });
        _log.info(
            'onTileHover: tooltip shown after delay for tile r=${tileData.row},c=${tileData.col}');
      }
    });
  }

  bool _isSameTile(TileData? a, TileData? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.row == b.row && a.col == b.col;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (PointerHoverEvent event) {
        // Convert hover position to tile using the game's grid and update tooltip
        final tile = widget.game.resolveHoverAt(event.localPosition);
        _onTileHover(tile, event.localPosition);
        _log.info('onHover: pos=${event.localPosition}, '
            'tile=${tile != null ? 'r=${tile.row},c=${tile.col}' : 'null'}');
      },
      onExit: (_) {
        widget.game.clearHover();
        _onTileHover(null, null);
        _log.info('onExit: hover cleared');
      },
      child: Stack(
        children: [
          // The Flame game
          GameWidget(
            game: widget.game,
          ),
          // Tooltip overlay
          GameTooltip(
            tileData: _hoveredTile,
            position: _hoverPosition,
            isVisible: _showTooltip,
          ),
        ],
      ),
    );
  }
}
