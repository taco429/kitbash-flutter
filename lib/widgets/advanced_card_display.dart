import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card.dart';
import '../models/card_variation.dart';

/// Advanced card display widget with support for various visual variations
class AdvancedCardDisplay extends StatefulWidget {
  final GameCard card;
  final CardVisualData? visualData;
  final double width;
  final double height;
  final bool enableInteraction;
  final bool enableParallax;
  final bool enableGlow;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(DragUpdateDetails)? onPanUpdate;
  final bool showBackside;
  final double borderRadius;
  final bool enableShadow;
  
  const AdvancedCardDisplay({
    super.key,
    required this.card,
    this.visualData,
    this.width = 250,
    this.height = 350,
    this.enableInteraction = true,
    this.enableParallax = true,
    this.enableGlow = true,
    this.onTap,
    this.onDoubleTap,
    this.onPanUpdate,
    this.showBackside = false,
    this.borderRadius = 16,
    this.enableShadow = true,
  });

  @override
  State<AdvancedCardDisplay> createState() => _AdvancedCardDisplayState();
}

class _AdvancedCardDisplayState extends State<AdvancedCardDisplay>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _glowController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  bool _isHovering = false;
  bool _isFlipped = false;
  
  // Touch position for parallax effect
  Offset _localPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _glowController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.enableInteraction || !widget.enableParallax) return;
    
    setState(() {
      _localPosition = details.localPosition;
      
      // Calculate rotation based on mouse position
      final centerX = widget.width / 2;
      final centerY = widget.height / 2;
      
      _rotateY = (_localPosition.dx - centerX) / centerX * 15; // Max 15 degrees
      _rotateX = -(_localPosition.dy - centerY) / centerY * 15; // Max 15 degrees
    });
    
    widget.onPanUpdate?.call(details);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!widget.enableInteraction || !widget.enableParallax) return;
    
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visualData = widget.visualData ?? CardVisualData(
      cardId: widget.card.id,
      rarity: CardRarity.common,
      variation: CardVariation.standard,
    );

    return MouseRegion(
      onEnter: (_) {
        if (widget.enableInteraction) {
          setState(() => _isHovering = true);
          _hoverController.forward();
        }
      },
      onExit: (_) {
        if (widget.enableInteraction) {
          setState(() {
            _isHovering = false;
            _rotateX = 0;
            _rotateY = 0;
          });
          _hoverController.reverse();
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: () {
          if (widget.onDoubleTap != null) {
            widget.onDoubleTap!();
          } else if (widget.enableInteraction) {
            // Default double tap flips the card
            setState(() => _isFlipped = !_isFlipped);
            if (_isFlipped) {
              _flipController.forward();
            } else {
              _flipController.reverse();
            }
          }
        },
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hoverController,
            _glowController,
            _flipAnimation,
          ]),
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateX(_rotateX * (math.pi / 180))
                ..rotateY(_rotateY * (math.pi / 180))
                ..rotateY(_flipAnimation.value * math.pi)
                ..scale(
                  _isHovering ? 1.05 : 1.0,
                  _isHovering ? 1.05 : 1.0,
                ),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: widget.enableShadow
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: widget.enableGlow && visualData.rarity.tier >= 3
                                ? Color(visualData.rarity.glowColors[0])
                                    .withValues(alpha: 0.3 + _glowController.value * 0.2)
                                : Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20 + (_isHovering ? 10 : 0),
                            spreadRadius: _isHovering ? 5 : 0,
                          ),
                        ],
                      )
                    : null,
                child: _flipAnimation.value < 0.5
                    ? _buildCardFront(visualData)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _buildCardBack(visualData),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardFront(CardVisualData visualData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Stack(
        children: [
          // Base card background
          _buildCardBackground(visualData),
          
          // Card art layer
          _buildCardArt(visualData),
          
          // Frame overlay
          _buildFrameOverlay(visualData),
          
          // Special effects overlays
          if (visualData.variation == CardVariation.holographic)
            _buildHolographicOverlay(),
          
          if (visualData.variation == CardVariation.foilEtched)
            _buildFoilEtchedOverlay(),
          
          if (visualData.isPremium)
            _buildPremiumShineOverlay(),
          
          // Card information overlay
          _buildCardInfo(visualData),
          
          // Promo stamp if applicable
          if (visualData.isPromo)
            _buildPromoStamp(),
        ],
      ),
    );
  }

  Widget _buildCardBack(CardVisualData visualData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(visualData.rarity.glowColors[0]),
              Color(visualData.rarity.glowColors[1]),
              Colors.black,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Card back pattern
            CustomPaint(
              size: Size(widget.width, widget.height),
              painter: CardBackPatternPainter(
                primaryColor: Color(visualData.rarity.glowColors[0]),
                secondaryColor: Color(visualData.rarity.glowColors[1]),
              ),
            ),
            
            // Game logo or symbol
            Center(
              child: Icon(
                Icons.shield_outlined,
                size: widget.width * 0.4,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBackground(CardVisualData visualData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCardColors(),
        ),
      ),
    );
  }

  Widget _buildCardArt(CardVisualData visualData) {
    // Placeholder for actual card art
    // In production, this would load the actual art asset
    return Positioned(
      top: widget.height * 0.05,
      left: widget.width * 0.05,
      right: widget.width * 0.05,
      height: widget.height * 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.black26,
          image: DecorationImage(
            image: AssetImage('assets/placeholder_card_art.jpg'),
            fit: visualData.variation == CardVariation.fullArt ||
                 visualData.variation == CardVariation.extendedArt
                ? BoxFit.cover
                : BoxFit.contain,
            onError: (exception, stackTrace) {
              // Fallback to gradient if image fails to load
            },
          ),
        ),
        child: visualData.variation == CardVariation.frameBreak
            ? CustomPaint(
                painter: FrameBreakPainter(),
              )
            : null,
      ),
    );
  }

  Widget _buildFrameOverlay(CardVisualData visualData) {
    if (visualData.variation == CardVariation.borderless ||
        visualData.variation == CardVariation.fullArt) {
      return const SizedBox.shrink();
    }
    
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: CardFramePainter(
        rarity: visualData.rarity,
        variation: visualData.variation,
        cardType: widget.card.type,
      ),
    );
  }

  Widget _buildHolographicOverlay() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return ui.Gradient.linear(
              Offset(
                bounds.width * _glowController.value,
                0,
              ),
              Offset(
                bounds.width * (_glowController.value + 0.3),
                bounds.height,
              ),
              [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.3),
                Colors.cyan.withValues(alpha: 0.2),
                Colors.purple.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              [0.0, 0.25, 0.5, 0.75, 1.0],
            );
          },
          blendMode: BlendMode.plus,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoilEtchedOverlay() {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: FoilEtchedPatternPainter(
        animationValue: _glowController.value,
      ),
    );
  }

  Widget _buildPremiumShineOverlay() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                -1 + 2 * _glowController.value,
                -1 + 2 * _glowController.value,
              ),
              radius: 0.5,
              colors: [
                Colors.white.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardInfo(CardVisualData visualData) {
    final fontSize = widget.width / 15;
    final smallFontSize = widget.width / 20;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(widget.width * 0.04),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card name and cost
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.card.name,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildCostIndicator(),
              ],
            ),
            
            SizedBox(height: widget.height * 0.01),
            
            // Card type and rarity
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.width * 0.02,
                    vertical: widget.height * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.card.type.displayName,
                    style: TextStyle(
                      fontSize: smallFontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: widget.width * 0.02),
                _buildRarityIndicator(visualData.rarity),
              ],
            ),
            
            // Stats for units
            if (widget.card.isUnit && widget.card.unitStats != null) ...[
              SizedBox(height: widget.height * 0.02),
              _buildStatsBar(),
            ],
            
            // Artist credit
            if (visualData.artistName != null) ...[
              SizedBox(height: widget.height * 0.01),
              Text(
                'Art by ${visualData.artistName}',
                style: TextStyle(
                  fontSize: smallFontSize * 0.7,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostIndicator() {
    return Container(
      padding: EdgeInsets.all(widget.width * 0.02),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.amber.shade300,
            Colors.amber.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '${widget.card.totalCost}',
        style: TextStyle(
          fontSize: widget.width / 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 2,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityIndicator(CardRarity rarity) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.width * 0.02,
        vertical: widget.height * 0.005,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(rarity.glowColors[0]),
            Color(rarity.glowColors[1]),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rarity.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: widget.width / 25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final stats = widget.card.unitStats!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatIcon(Icons.flash_on, stats.attack, Colors.red),
        _buildStatIcon(Icons.favorite, stats.health, Colors.green),
        if (stats.armor > 0)
          _buildStatIcon(Icons.shield, stats.armor, Colors.blue),
        if (stats.speed > 1)
          _buildStatIcon(Icons.speed, stats.speed, Colors.yellow),
      ],
    );
  }

  Widget _buildStatIcon(IconData icon, int value, Color color) {
    return Container(
      padding: EdgeInsets.all(widget.width * 0.015),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: widget.width / 15,
            color: Colors.white,
          ),
          SizedBox(width: widget.width * 0.01),
          Text(
            '$value',
            style: TextStyle(
              fontSize: widget.width / 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoStamp() {
    return Positioned(
      bottom: widget.height * 0.15,
      right: widget.width * 0.05,
      child: Container(
        padding: EdgeInsets.all(widget.width * 0.02),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.gold,
              Colors.amber.shade800,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.gold.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.star,
          size: widget.width / 10,
          color: Colors.white,
        ),
      ),
    );
  }

  List<Color> _getCardColors() {
    switch (widget.card.color) {
      case CardColor.red:
        return [Colors.red.shade300, Colors.red.shade700];
      case CardColor.orange:
        return [Colors.orange.shade300, Colors.orange.shade700];
      case CardColor.yellow:
        return [Colors.yellow.shade300, Colors.yellow.shade600];
      case CardColor.green:
        return [Colors.green.shade300, Colors.green.shade700];
      case CardColor.blue:
        return [Colors.blue.shade300, Colors.blue.shade700];
      case CardColor.purple:
        return [Colors.purple.shade300, Colors.purple.shade700];
    }
  }
}

/// Custom painter for card frame
class CardFramePainter extends CustomPainter {
  final CardRarity rarity;
  final CardVariation variation;
  final CardType cardType;

  CardFramePainter({
    required this.rarity,
    required this.variation,
    required this.cardType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [
          Color(rarity.glowColors[0]),
          Color(rarity.glowColors[1]),
        ],
      );

    final path = Path();
    final cornerRadius = size.width * 0.06;

    // Draw ornate frame based on variation
    if (variation == CardVariation.retro) {
      // Retro frame with double border
      final outerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      );
      final innerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.02,
          size.height * 0.02,
          size.width * 0.96,
          size.height * 0.96,
        ),
        Radius.circular(cornerRadius * 0.8),
      );
      
      canvas.drawRRect(outerRect, paint);
      canvas.drawRRect(innerRect, paint..strokeWidth = size.width * 0.008);
    } else if (variation == CardVariation.showcase) {
      // Showcase frame with decorative corners
      _drawShowcaseFrame(canvas, size, paint);
    } else {
      // Standard frame
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(cornerRadius),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  void _drawShowcaseFrame(Canvas canvas, Size size, Paint paint) {
    final cornerSize = size.width * 0.15;
    
    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerSize)
        ..lineTo(0, 0)
        ..lineTo(cornerSize, 0),
      paint,
    );
    
    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerSize, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerSize),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerSize)
        ..lineTo(0, size.height)
        ..lineTo(cornerSize, size.height),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerSize, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for frame break effect
class FrameBreakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.5);

    // Draw breaking frame effect
    final path = Path();
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (int i = 0; i < 5; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + (random.nextDouble() - 0.5) * 50;
      final endY = startY + (random.nextDouble() - 0.5) * 50;
      
      path.moveTo(startX, startY);
      path.lineTo(endX, endY);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for foil etched pattern
class FoilEtchedPatternPainter extends CustomPainter {
  final double animationValue;

  FoilEtchedPatternPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw etched pattern
    final spacing = size.width / 10;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final offset = Offset(
          x + math.sin(animationValue * 2 * math.pi) * 5,
          y + math.cos(animationValue * 2 * math.pi) * 5,
        );
        canvas.drawCircle(offset, 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FoilEtchedPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Custom painter for card back pattern
class CardBackPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  CardBackPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = primaryColor.withValues(alpha: 0.3);

    // Draw geometric pattern
    final cellSize = size.width / 8;
    
    for (double x = 0; x < size.width; x += cellSize) {
      for (double y = 0; y < size.height; y += cellSize) {
        // Draw diamond pattern
        final path = Path()
          ..moveTo(x + cellSize / 2, y)
          ..lineTo(x + cellSize, y + cellSize / 2)
          ..lineTo(x + cellSize / 2, y + cellSize)
          ..lineTo(x, y + cellSize / 2)
          ..close();
        
        canvas.drawPath(path, paint);
        
        // Draw center circle
        canvas.drawCircle(
          Offset(x + cellSize / 2, y + cellSize / 2),
          cellSize / 4,
          paint..color = secondaryColor.withValues(alpha: 0.2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}