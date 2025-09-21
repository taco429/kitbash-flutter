import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/kitbash_game.dart';
import '../models/tile_data.dart';
import '../models/resources.dart';
import 'game_tooltip.dart';
import '../models/card_drag_payload.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import 'package:flutter/services.dart';
import 'card_preview_panel.dart';
import 'turn_indicator.dart';
import 'opponent_indicator.dart';

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
  Timer? _tooltipTimer;
  bool _showTooltip = false;
  bool _isDragActive = false;
  bool _isZoomedIn = false;

  final GlobalKey _dropOverlayKey = GlobalKey();
  final FocusNode _placeFocusNode = FocusNode();

  int? _lastValidatedRow;
  int? _lastValidatedCol;
  DateTime _lastValidationAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const Duration _tooltipDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _isZoomedIn = widget.game.isZoomedIn;
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _placeFocusNode.dispose();
    super.dispose();
  }

  void _onTileHover(TileData? tileData) {
    final bool sameTile = _isSameTile(_hoveredTile, tileData);

    // Always update current hover snapshot
    setState(() {
      _hoveredTile = tileData;
    });

    // While dragging a card, request backend validation for dynamic feedback
    if (_isDragActive && tileData != null) {
      final now = DateTime.now();
      // Throttle to every 50ms and avoid duplicate tile validations
      if (_lastValidatedRow == tileData.row &&
          _lastValidatedCol == tileData.col &&
          now.difference(_lastValidationAt).inMilliseconds < 50) {
        return;
      }
      _lastValidatedRow = tileData.row;
      _lastValidatedCol = tileData.col;
      _lastValidationAt = now;

      final gs = context.read<GameService>();
      final payload = gs.cardPreview.value ?? gs.pendingPlacement;
      if (payload != null && payload.instance != null) {
        gs.validateTarget(
          playerIndex: gs.currentPlayerIndex,
          cardInstanceId: payload.instance!.instanceId,
          row: tileData.row,
          col: tileData.col,
          cardId: payload.card.id,
        );
      }
    }

    // If cursor left the board or position is invalid -> hide immediately
    if (tileData == null) {
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
        final tile = widget.game.resolveHoverAt(event.localPosition);
        _onTileHover(tile);
      },
      onExit: (_) {
        widget.game.clearHover();
        _onTileHover(null);
      },
      child: Stack(
        children: [
          // The Flame game
          GameWidget(
            key: ValueKey(widget.game),
            game: widget.game,
          ),
          // Right-side card preview panel moved to floating overlay at top-right
          // Tap-to-place overlay when a card is staged via preview
          Positioned.fill(
            child: Consumer<GameService>(
              builder: (context, gameService, child) {
                // Use ValueListenableBuilder for granular updates
                return ValueListenableBuilder<CardDragPayload?>(
                  valueListenable: gameService.cardPlacement,
                  builder: (context, pending, child) {
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
                        _onTileHover(tile);
                      },
                      onExit: (_) {
                        widget.game.clearHover();
                        _onTileHover(null);
                      },
                      child: Focus(
                        focusNode: _placeFocusNode,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.escape) {
                            gameService.clearCardPlacement();
                            widget.game.clearHover();
                            _onTileHover(null);
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Reserve bottom area for the player controls so the overlay doesn't block it.
                            const double controlHeight = 260.0;
                            final double overlayHeight =
                                (constraints.maxHeight - controlHeight)
                                    .clamp(0, constraints.maxHeight);

                            return Column(
                              children: [
                                SizedBox(
                                  height: overlayHeight,
                                  width: double.infinity,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onSecondaryTap: () {
                                      gameService.clearCardPlacement();
                                      widget.game.clearHover();
                                      _onTileHover(null);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Placement canceled'),
                                          duration: Duration(milliseconds: 800),
                                        ),
                                      );
                                    },
                                    onTapDown: (details) {
                                      final local = details.localPosition;
                                      final tile =
                                          widget.game.resolveHoverAt(local);
                                      if (tile != null &&
                                          pending.instance != null) {
                                        widget.game.selectAt(local);
                                        widget.game.gameService.stagePlayCard(
                                          widget.game.gameId,
                                          widget.game.gameService
                                              .currentPlayerIndex,
                                          pending.instance!.instanceId,
                                          tile.row,
                                          tile.col,
                                        );
                                        gameService.clearCardPlacement();
                                        _onTileHover(null);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Played ${pending.card.name} at (${tile.row}, ${tile.col})'),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      color:
                                          Colors.black.withValues(alpha: 0.02),
                                    ),
                                  ),
                                ),
                                // Bottom spacer: let events pass through to controls/hand.
                                const Expanded(
                                  child: IgnorePointer(
                                    ignoring: true,
                                    child: SizedBox.expand(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
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
                _onTileHover(tile);
                return true;
              },
              onMove: (details) {
                final box = _dropOverlayKey.currentContext?.findRenderObject()
                    as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.offset);
                final tile = widget.game.resolveHoverAt(local);
                _onTileHover(tile);
              },
              onLeave: (data) {
                _isDragActive = false;
                widget.game.clearHover();
                _onTileHover(null);
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
                _onTileHover(null);
              },
            ),
          ),
          // Anchored info view (bottom-right, offset left of right panel)
          Positioned(
            right: 332, // 320px panel width + 12px margin
            bottom: 12,
            child: SafeArea(
              child: IgnorePointer(
                ignoring: true,
                child: GameTooltip(
                  tileData: _hoveredTile,
                  isVisible: _showTooltip && !_isDragActive,
                ),
              ),
            ),
          ),
          // Top-left overlay: Turn indicator above zoom button
          Positioned(
            left: 12,
            top: 12,
            child: SafeArea(
              child: Consumer<GameService>(
                builder: (context, gs, _) {
                  final state = gs.gameState;
                  if (state == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TurnIndicator(
                        turnNumber: state.currentTurn,
                        player1Locked: state.isPlayerLocked(0),
                        player2Locked: state.isPlayerLocked(1),
                        currentPhase: state.currentPhase,
                        phaseStartTime: state.phaseStartTime,
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_toggle',
                        tooltip: _isZoomedIn ? 'Zoom out' : 'Zoom in',
                        onPressed: () {
                          setState(() {
                            _isZoomedIn = !_isZoomedIn;
                          });
                          widget.game.setZoomLevel(_isZoomedIn);
                        },
                        child:
                            Icon(_isZoomedIn ? Icons.zoom_out : Icons.zoom_in),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Top-right overlay: Opponent indicator above FPS (FPS drawn by Flame is positioned lower)
          Positioned(
            right: 12,
            top: 12,
            child: SafeArea(
              child: Consumer<GameService>(
                builder: (context, gs, _) {
                  final state = gs.gameState;
                  if (state == null) return const SizedBox.shrink();
                  final int myIndex = gs.currentPlayerIndex;
                  final int oppIndex = 1 - myIndex;
                  final opponentState = state.playerStates.firstWhere(
                    (ps) => ps.playerIndex == oppIndex,
                    orElse: () => PlayerBattleState(
                      playerIndex: oppIndex,
                      deckId: '',
                      hand: const [],
                      deckCount: 0,
                      resources: const Resources(gold: 0, mana: 0),
                      resourceIncome:
                          const ResourceGeneration(gold: 0, mana: 0),
                    ),
                  );
                  return OpponentIndicator(opponentState: opponentState);
                },
              ),
            ),
          ),
          // Floating card preview overlay (rendered above opponent indicator)
          Positioned(
            right: 12,
            top: 12,
            child: SafeArea(
              child: Consumer<GameService>(
                builder: (context, gs, _) {
                  return ValueListenableBuilder<CardDragPayload?>(
                    valueListenable: gs.cardPreview,
                    builder: (context, preview, _) {
                      if (preview == null) return const SizedBox.shrink();
                      return ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 380,
                          maxHeight: 640,
                        ),
                        child: SizedBox(
                          width: 360,
                          child: CardPreviewPanel(payload: preview),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
