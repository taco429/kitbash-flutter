import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/kitbash_game.dart';
import '../models/tile_data.dart';
import 'game_tooltip.dart';
import '../models/card_drag_payload.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import 'package:flutter/services.dart';
import 'card_preview_panel.dart';

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
  final FocusNode _placeFocusNode = FocusNode();

  static const Duration _tooltipDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _placeFocusNode.dispose();
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
          // Right-side card preview panel that doesn't cover the game canvas
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 320,
            child: Consumer<GameService>(
              builder: (context, gs, _) {
                final preview = gs.previewPayload;
                if (preview == null) return const SizedBox.shrink();
                return CardPreviewPanel(payload: preview);
              },
            ),
          ),
          // Tap-to-place overlay when a card is staged via preview
          Positioned.fill(
            child: Consumer<GameService>(
              builder: (context, gameService, child) {
                final pending = gameService.pendingPlacement;
                if (pending == null) return const SizedBox.shrink();
                // Ensure we can catch ESC
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _placeFocusNode.requestFocus();
                  }
                });
                return MouseRegion(
                  onHover: (event) {
                    final tile =
                        widget.game.resolveHoverAt(event.localPosition);
                    _onTileHover(tile, event.localPosition);
                  },
                  onExit: (_) {
                    widget.game.clearHover();
                    _onTileHover(null, null);
                  },
                  child: Focus(
                    focusNode: _placeFocusNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        gameService.clearCardPlacement();
                        widget.game.clearHover();
                        _onTileHover(null, null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Placement canceled'),
                            duration: Duration(milliseconds: 800),
                          ),
                        );
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onSecondaryTap: () {
                        gameService.clearCardPlacement();
                        widget.game.clearHover();
                        _onTileHover(null, null);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Placement canceled'),
                            duration: Duration(milliseconds: 800),
                          ),
                        );
                      },
                      onTapDown: (details) {
                        final local = details.localPosition;
                        final tile = widget.game.resolveHoverAt(local);
                        if (tile != null && pending.instance != null) {
                          widget.game.selectAt(local);
                          widget.game.gameService.stagePlayCard(
                            widget.game.gameId,
                            widget.game.gameService.currentPlayerIndex,
                            pending.instance!.instanceId,
                            tile.row,
                            tile.col,
                          );
                          gameService.clearCardPlacement();
                          _onTileHover(null, null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Played ${pending.card.name} at (${tile.row}, ${tile.col})'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: IgnorePointer(
                        ignoring: false,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.02),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Drag-and-drop overlay for playing cards onto the board
          Positioned.fill(
            child: DragTarget<CardDragPayload>(
              builder: (context, candidateData, rejectedData) {
                // Provide an invisible hit area for drag events
                return SizedBox.expand(key: _dropOverlayKey);
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
