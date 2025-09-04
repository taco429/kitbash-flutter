import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/card.dart';

/// Visual style effects that can be applied to a card's presentation.
enum CardStyleEffect {
  alternateArt,
  borderless,
  frameBreak,
  holographic,
}

/// A reusable, performant card display widget with variant effects.
///
/// This focuses on high-quality art presentation while keeping UI overlays
/// readable. It gracefully degrades when assets are missing.
class CardDisplay extends StatefulWidget {
  final GameCard card;

  /// Effects to apply to the visual presentation. Can be combined.
  final Set<CardStyleEffect> effects;

  /// Primary art asset path. Example: 'assets/images/cards/warrior/standard.png'
  final String? artAsset;

  /// Alternate art asset path. Used when [CardStyleEffect.alternateArt] is active.
  final String? alternateArtAsset;

  /// The width of the card. Height is derived by [aspectRatio].
  final double width;

  /// Card aspect ratio (width : height). Typical TCG is close to 63x88mm (~0.716),
  /// but many digital cards use ~0.66-0.72. Default here is 0.75 for readability.
  final double aspectRatio;

  /// Whether to show name/cost/type/stats overlays.
  final bool showOverlays;

  /// Tap handler.
  final VoidCallback? onTap;

  const CardDisplay({
    super.key,
    required this.card,
    this.effects = const {},
    this.artAsset,
    this.alternateArtAsset,
    this.width = 180,
    this.aspectRatio = 0.75,
    this.showOverlays = true,
    this.onTap,
  });

  @override
  State<CardDisplay> createState() => _CardDisplayState();
}

class _CardDisplayState extends State<CardDisplay> with SingleTickerProviderStateMixin {
  late final AnimationController _holoController;

  @override
  void initState() {
    super.initState();
    _holoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (_hasEffect(CardStyleEffect.holographic)) {
      _holoController.repeat();
    }
  }

  @override
  void didUpdateWidget(CardDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hadHolo = oldWidget.effects.contains(CardStyleEffect.holographic);
    final hasHolo = widget.effects.contains(CardStyleEffect.holographic);
    if (hasHolo && !hadHolo) {
      _holoController.repeat();
    } else if (!hasHolo && hadHolo) {
      _holoController.stop();
      _holoController.reset();
    }
  }

  @override
  void dispose() {
    _holoController.dispose();
    super.dispose();
  }

  bool _hasEffect(CardStyleEffect effect) => widget.effects.contains(effect);

  @override
  Widget build(BuildContext context) {
    final double width = widget.width;
    final double height = width / widget.aspectRatio;
    final bool isBorderless = _hasEffect(CardStyleEffect.borderless);
    final BorderRadius borderRadius = isBorderless ? BorderRadius.zero : BorderRadius.circular(12);

    final String? chosenArt = _hasEffect(CardStyleEffect.alternateArt)
        ? (widget.alternateArtAsset ?? widget.artAsset)
        : widget.artAsset;

    final Widget cardCore = RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getCardColors(widget.card),
          ),
          boxShadow: isBorderless
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        clipBehavior: isBorderless ? Clip.none : Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Art layer
            Positioned.fill(
              child: _buildArtLayer(chosenArt, isBorderless, width, height),
            ),

            // Holographic overlay
            if (_hasEffect(CardStyleEffect.holographic)) Positioned.fill(child: _buildHolographicOverlay()),

            // Foreground overlays
            if (widget.showOverlays) _buildForegroundOverlays(width, height),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: isBorderless
          ? cardCore
          : Card(
              elevation: 6,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              child: cardCore,
            ),
    );
  }

  Widget _buildArtLayer(String? assetPath, bool isBorderless, double width, double height) {
    final bool isFrameBreak = _hasEffect(CardStyleEffect.frameBreak);
    final double overflowOffset = isFrameBreak ? -height * 0.08 : 0;
    final double scale = isFrameBreak ? 1.06 : 1.0;

    Widget image;
    if (assetPath == null || assetPath.isEmpty) {
      image = _buildFallbackArt();
    } else {
      image = Image.asset(
        assetPath,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _buildFallbackArt(),
      );
    }

    final Widget art = Transform.translate(
      offset: Offset(0, overflowOffset),
      child: Transform.scale(
        scale: scale,
        child: image,
      ),
    );

    if (isBorderless) {
      return art; // allow bleed to the very edge
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: art,
    );
  }

  Widget _buildFallbackArt() {
    // A vibrant gradient placeholder for when art is missing
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A237E),
            Color(0xFF6A1B9A),
            Color(0xFFD32F2F),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 40,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildHolographicOverlay() {
    return AnimatedBuilder(
      animation: _holoController,
      builder: (context, child) {
        final double t = _holoController.value; // 0..1
        final double angle = (t * 2 * math.pi);
        final Alignment begin = Alignment(
          -1.5 + (3.0 * t),
          math.sin(angle) * 0.3,
        );
        final Alignment end = Alignment(
          1.5 - (3.0 * t),
          -math.sin(angle) * 0.3,
        );
        return ShaderMask(
          shaderCallback: (Rect rect) {
            return LinearGradient(
              begin: begin,
              end: end,
              colors: [
                Colors.transparent,
                const Color(0xFF00E5FF).withValues(alpha: 0.35),
                const Color(0xFFFFEA00).withValues(alpha: 0.35),
                const Color(0xFFFF00E5).withValues(alpha: 0.35),
                Colors.transparent,
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: Container(color: Colors.white),
        );
      },
    );
  }

  Widget _buildForegroundOverlays(double width, double height) {
    final bool compact = width < 160;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and cost
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.card.name,
                    style: TextStyle(
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.card.goldCost > 0) ...[
                      Icon(
                        Icons.monetization_on,
                        size: compact ? 10 : 12,
                        color: Colors.amber.shade700,
                      ),
                      Text(
                        '${widget.card.goldCost}',
                        style: TextStyle(
                          fontSize: compact ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                    if (widget.card.goldCost > 0 && widget.card.manaCost > 0)
                      const SizedBox(width: 4),
                    if (widget.card.manaCost > 0) ...[
                      Icon(
                        Icons.auto_awesome,
                        size: compact ? 10 : 12,
                        color: Colors.blue.shade700,
                      ),
                      Text(
                        '${widget.card.manaCost}',
                        style: TextStyle(
                          fontSize: compact ? 10 : 12,
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

          const Spacer(),

          // Type tag
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.card.type.displayName,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Bottom row: stats or abilities (compact)
          if (widget.card.isUnit && widget.card.unitStats != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, size: 12, color: Colors.white),
                      Text(
                        '${widget.card.unitStats?.attack ?? 0}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, size: 12, color: Colors.white),
                      Text(
                        '${widget.card.unitStats?.health ?? 0}',
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
            )
          else if (widget.card.abilities.isNotEmpty)
            Wrap(
              spacing: 4,
              children: widget.card.abilities.take(2).map((ability) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ability,
                    style: const TextStyle(fontSize: 9, color: Colors.black87),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  List<Color> _getCardColors(GameCard card) {
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

