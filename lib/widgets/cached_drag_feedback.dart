import 'package:flutter/material.dart';
import '../models/card.dart';
import 'advanced_card_display.dart';

/// Manages cached drag feedback widgets to avoid creating them during drag
class CachedDragFeedback extends StatefulWidget {
  final GameCard card;
  final double width;
  final double height;
  final Widget child;

  const CachedDragFeedback({
    super.key,
    required this.card,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  State<CachedDragFeedback> createState() => _CachedDragFeedbackState();
}

class _CachedDragFeedbackState extends State<CachedDragFeedback> {
  late Widget _cachedFeedback;
  GameCard? _lastCard;

  @override
  void initState() {
    super.initState();
    _buildFeedback();
  }

  @override
  void didUpdateWidget(CachedDragFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild feedback if card changed
    if (widget.card.id != _lastCard?.id) {
      _buildFeedback();
    }
  }

  void _buildFeedback() {
    _lastCard = widget.card;
    // Pre-build the feedback widget once
    _cachedFeedback = _DragFeedbackWidget(
      card: widget.card,
      width: widget.width * 1.1,
      height: widget.height * 1.1,
    );
  }

  Widget getFeedback() => _cachedFeedback;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Lightweight feedback widget that's pre-built and cached
class _DragFeedbackWidget extends StatelessWidget {
  final GameCard card;
  final double width;
  final double height;

  const _DragFeedbackWidget({
    required this.card,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // This is built once and cached, not during drag
    return Opacity(
      opacity: 0.9,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          child: AdvancedCardDisplay(
            card: card,
            width: width,
            height: height,
            enableParallax: false,
            enableGlow: true,
            enableShadow: true,
            enableInteraction: false, // Disable interaction for feedback
          ),
        ),
      ),
    );
  }
}

/// Global cache for drag feedback widgets
class DragFeedbackCache {
  static final Map<String, Widget> _cache = {};
  static const int _maxCacheSize = 20; // Limit cache size

  static Widget getFeedback({
    required GameCard card,
    required double width,
    required double height,
  }) {
    final key = '${card.id}_${width}_$height';

    // Return cached widget if available
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // Create and cache new feedback widget
    final feedback = _DragFeedbackWidget(
      card: card,
      width: width * 1.1,
      height: height * 1.1,
    );

    // Manage cache size
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry (simple FIFO)
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = feedback;
    return feedback;
  }

  static void clearCache() {
    _cache.clear();
  }

  static void removeFeedback(String cardId) {
    _cache.removeWhere((key, _) => key.startsWith(cardId));
  }
}
