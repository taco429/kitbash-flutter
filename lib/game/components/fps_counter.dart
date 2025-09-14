import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A component that displays the current FPS (frames per second) on screen.
class FpsCounter extends PositionComponent with HasGameRef {
  late TextComponent _fpsText;
  double _elapsedTime = 0;
  int _frameCount = 0;
  double _currentFps = 0;
  
  // Update interval in seconds
  static const double _updateInterval = 0.5;
  
  FpsCounter({
    super.position,
    super.anchor = Anchor.topRight,
  });

  @override
  Future<void> onLoad() async {
    // Create the text component with styling
    _fpsText = TextComponent(
      text: 'FPS: 0',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black87,
            ),
          ],
        ),
      ),
      anchor: anchor,
    );
    
    // Add background for better visibility
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    add(
      RectangleComponent(
        size: Vector2(80, 25),
        paint: backgroundPaint,
        anchor: anchor,
        children: [_fpsText],
      ),
    );
    
    // Position the text with some padding
    _fpsText.position = Vector2(5, 3);
    _fpsText.anchor = Anchor.topLeft;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _elapsedTime += dt;
    _frameCount++;
    
    // Update FPS display at intervals
    if (_elapsedTime >= _updateInterval) {
      _currentFps = _frameCount / _elapsedTime;
      _fpsText.text = 'FPS: ${_currentFps.toStringAsFixed(1)}';
      
      // Reset counters
      _elapsedTime = 0;
      _frameCount = 0;
      
      // Change color based on FPS performance
      _updateFpsColor();
    }
  }
  
  void _updateFpsColor() {
    Color fpsColor;
    if (_currentFps >= 55) {
      fpsColor = Colors.greenAccent; // Good performance
    } else if (_currentFps >= 30) {
      fpsColor = Colors.yellowAccent; // Acceptable performance
    } else {
      fpsColor = Colors.redAccent; // Poor performance
    }
    
    _fpsText.textRenderer = TextPaint(
      style: TextStyle(
        color: fpsColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 2,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}