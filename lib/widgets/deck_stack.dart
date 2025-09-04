import 'package:flutter/material.dart';

/// A compact deck visual rendered as a stack of card backs.
/// Shows remaining card count in a tooltip on hover.
class DeckStack extends StatelessWidget {
  final String label;
  final int remainingCount;
  final Color accentColor;
  final int layers;

  const DeckStack({
    super.key,
    required this.label,
    required this.remainingCount,
    required this.accentColor,
    this.layers = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Tooltip(
                message: '$remainingCount cards left',
                waitDuration: const Duration(milliseconds: 300),
                showDuration: const Duration(seconds: 2),
                preferBelow: false,
                child: _StackedCards(
                  accentColor: accentColor,
                  layers: layers,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedCards extends StatelessWidget {
  final Color accentColor;
  final int layers;

  const _StackedCards({
    required this.accentColor,
    this.layers = 5,
  });

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 64;
    const double cardHeight = 88;
    const double offsetX = 8;
    const double offsetY = 6;

    final double totalWidth = cardWidth + (layers - 1) * offsetX;
    final double totalHeight = cardHeight + (layers - 1) * offsetY;

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(layers, (index) {
          final double dx = (layers - 1 - index) * offsetX;
          final double dy = (layers - 1 - index) * offsetY;
          final double alpha = 0.8 - (index * 0.08);
          return Positioned(
            left: dx,
            top: dy,
            child: _CardBack(
              width: cardWidth,
              height: cardHeight,
              accentColor: accentColor.withValues(alpha: alpha.clamp(0.4, 0.9)),
            ),
          );
        }),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final double width;
  final double height;
  final Color accentColor;

  const _CardBack({
    required this.width,
    required this.height,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.9),
            accentColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 8,
          margin: const EdgeInsets.only(top: 10, left: 12, right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

