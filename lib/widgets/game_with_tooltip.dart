import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flame/game.dart';
import '../game/kitbash_game.dart';
import '../models/tile_data.dart';
import 'game_tooltip.dart';
import '../models/card_drag_payload.dart';

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
  bool _isDragActive = false;

  final GlobalKey _dropOverlayKey = GlobalKey();

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
      return;
    }

    // If already visible, keep it visible and just follow the cursor
    if (_showTooltip) {
      return;
    }

    // If hovering the same tile as before and waiting, don't reset the timer
    if (sameTile) {
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
      },
      onExit: (_) {
        widget.game.clearHover();
        _onTileHover(null, null);
      },
      child: Stack(
        children: [
          // The Flame game
          GameWidget(
            key: ValueKey(widget.game),
            game: widget.game,
          ),
          // Drag-and-drop overlay for playing cards onto the board
          Positioned.fill(
            child: DragTarget<CardDragPayload>(
              builder: (context, candidateData, rejectedData) {
                // Provide an invisible hit area for drag events
                return Container(
                    key: _dropOverlayKey, color: Colors.transparent);
              },
              onWillAcceptWithDetails: (details) {
                _isDragActive = true;
                _tooltipTimer?.cancel();
                _showTooltip = false;

                // Convert global pointer to local coordinates
                final box = _dropOverlayKey.currentContext?.findRenderObject()
                    as RenderBox?;
                if (box == null) return true;
                final local = box.globalToLocal(details.offset);
                final tile = widget.game.resolveHoverAt(local);
                _onTileHover(tile, local);
                return true;
              },
              onMove: (details) {
                final box = _dropOverlayKey.currentContext?.findRenderObject()
                    as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.offset);
                final tile = widget.game.resolveHoverAt(local);
                _onTileHover(tile, local);
              },
              onLeave: (data) {
                _isDragActive = false;
                widget.game.clearHover();
                _onTileHover(null, null);
              },
              onAcceptWithDetails: (details) {
                _isDragActive = false;
                final box = _dropOverlayKey.currentContext?.findRenderObject()
                    as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.offset);

                // Select the tile in the Flame game
                widget.game.selectAt(local);

                // Optionally stage the play action
                final payload = details.data;
                final tile = widget.game.resolveHoverAt(local);
                if (tile != null && payload.instance != null) {
                  widget.game.gameService.stagePlayCard(
                    widget.game.gameId,
                    widget.game.gameService.currentPlayerIndex,
                    payload.instance!.instanceId,
                    tile.row,
                    tile.col,
                  );
                }

                // Ensure tooltip is hidden right after drop
                _onTileHover(null, null);
              },
            ),
          ),
          // Tooltip overlay
          GameTooltip(
            tileData: _hoveredTile,
            position: _hoverPosition,
            isVisible: _showTooltip && !_isDragActive,
          ),
        ],
      ),
    );
  }
}
