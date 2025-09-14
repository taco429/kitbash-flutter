import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Weather effects system for enhanced atmosphere
class WeatherEffects extends PositionComponent {
  final double screenWidth;
  final double screenHeight;
  final List<SnowParticle> snowParticles = [];
  final List<FogLayer> fogLayers = [];
  double _time = 0.0;

  WeatherEffects({required this.screenWidth, required this.screenHeight}) {
    _initializeFog();
    _initializeSnow();
  }

  void _initializeFog() {
    // Create multiple fog layers for depth
    fogLayers.add(FogLayer(
      speed: 10.0,
      opacity: 0.15,
      scale: 1.5,
      offset: 0.0,
    ));
    fogLayers.add(FogLayer(
      speed: 15.0,
      opacity: 0.1,
      scale: 2.0,
      offset: 100.0,
    ));
    fogLayers.add(FogLayer(
      speed: 5.0,
      opacity: 0.2,
      scale: 1.0,
      offset: 200.0,
    ));
  }

  void _initializeSnow() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      snowParticles.add(SnowParticle(
        position: Vector2(
          random.nextDouble() * screenWidth,
          random.nextDouble() * screenHeight,
        ),
        velocity: Vector2(
          (random.nextDouble() - 0.5) * 20,
          20 + random.nextDouble() * 30,
        ),
        size: 1 + random.nextDouble() * 3,
        opacity: 0.3 + random.nextDouble() * 0.4,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update snow particles
    for (final particle in snowParticles) {
      particle.update(dt, screenWidth, screenHeight);
    }

    // Update fog layers
    for (final fog in fogLayers) {
      fog.update(dt);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Render fog layers (back to front)
    for (final fog in fogLayers) {
      fog.render(canvas, screenWidth, screenHeight, _time);
    }

    // Render snow particles
    for (final particle in snowParticles) {
      particle.render(canvas);
    }
  }
}

class SnowParticle {
  Vector2 position;
  Vector2 velocity;
  double size;
  double opacity;
  double swayAmount = 0.0;
  double swaySpeed = 0.0;

  SnowParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
  }) {
    final random = math.Random();
    swayAmount = 10 + random.nextDouble() * 20;
    swaySpeed = 1 + random.nextDouble() * 2;
  }

  void update(double dt, double screenWidth, double screenHeight) {
    // Apply gravity and wind
    position.y += velocity.y * dt;
    position.x += velocity.x * dt +
        math.sin(position.y * 0.01 * swaySpeed) * swayAmount * dt;

    // Wrap around screen
    if (position.y > screenHeight) {
      position.y = -size;
      position.x = math.Random().nextDouble() * screenWidth;
    }
    if (position.x < -size) {
      position.x = screenWidth + size;
    } else if (position.x > screenWidth + size) {
      position.x = -size;
    }
  }

  void render(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, size * 0.5);

    canvas.drawCircle(
      ui.Offset(position.x, position.y),
      size,
      paint,
    );
  }
}

class FogLayer {
  final double speed;
  final double opacity;
  final double scale;
  double offset;

  FogLayer({
    required this.speed,
    required this.opacity,
    required this.scale,
    required this.offset,
  });

  void update(double dt) {
    offset += speed * dt;
  }

  void render(ui.Canvas canvas, double width, double height, double time) {
    final paint = ui.Paint()
      ..color = const Color(0xFF8E9AAF).withValues(alpha: opacity)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 20 * scale);

    // Create flowing fog effect with sine waves
    final path = ui.Path();
    path.moveTo(0, height * 0.6);

    for (double x = 0; x <= width; x += 10) {
      final y = height * 0.6 +
          math.sin((x + offset) * 0.01) * 30 * scale +
          math.sin((x + offset) * 0.005 + time) * 20 * scale;
      path.lineTo(x, y);
    }

    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    canvas.drawPath(path, paint);
  }
}

/// Lighting effects for enhanced atmosphere
class LightingEffects extends PositionComponent {
  final double screenWidth;
  final double screenHeight;
  double _time = 0.0;
  final List<LightSource> lights = [];

  LightingEffects({required this.screenWidth, required this.screenHeight}) {
    _initializeLights();
  }

  void _initializeLights() {
    // Add some ambient light sources
    lights.add(LightSource(
      position: Vector2(screenWidth * 0.2, screenHeight * 0.3),
      color: const Color(0xFFFFE082),
      radius: 100,
      intensity: 0.5,
      flicker: true,
    ));

    lights.add(LightSource(
      position: Vector2(screenWidth * 0.8, screenHeight * 0.4),
      color: const Color(0xFF81C784),
      radius: 80,
      intensity: 0.4,
      flicker: false,
    ));
  }

  void addCommandCenterLight(Vector2 position, Color color) {
    lights.add(LightSource(
      position: position,
      color: color,
      radius: 60,
      intensity: 0.6,
      flicker: false,
      pulse: true,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    for (final light in lights) {
      light.update(dt, _time);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    // Create a subtle vignette effect
    final vignettePaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(screenWidth / 2, screenHeight / 2),
        screenWidth * 0.7,
        [
          Colors.transparent,
          const Color(0x20000000),
          const Color(0x40000000),
        ],
        [0.0, 0.7, 1.0],
      );

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, screenWidth, screenHeight),
      vignettePaint,
    );

    // Render light sources
    for (final light in lights) {
      light.render(canvas);
    }
  }
}

class LightSource {
  Vector2 position;
  Color color;
  double radius;
  double intensity;
  bool flicker;
  bool pulse;
  double currentIntensity;
  double flickerSpeed;

  LightSource({
    required this.position,
    required this.color,
    required this.radius,
    required this.intensity,
    this.flicker = false,
    this.pulse = false,
  })  : currentIntensity = intensity,
        flickerSpeed = 5 + math.Random().nextDouble() * 10;

  void update(double dt, double time) {
    if (flicker) {
      currentIntensity = intensity +
          math.sin(time * flickerSpeed) * 0.1 +
          math.sin(time * flickerSpeed * 2.3) * 0.05;
    } else if (pulse) {
      currentIntensity = intensity + math.sin(time * 2) * 0.2;
    } else {
      currentIntensity = intensity;
    }
  }

  void render(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(position.x, position.y),
        radius,
        [
          color.withValues(alpha: currentIntensity),
          color.withValues(alpha: currentIntensity * 0.5),
          color.withValues(alpha: 0),
        ],
        [0.0, 0.5, 1.0],
      )
      ..blendMode = ui.BlendMode.screen;

    canvas.drawCircle(
      ui.Offset(position.x, position.y),
      radius,
      paint,
    );
  }
}

/// Special effects for combat and interactions
class CombatEffects {
  static void renderExplosion(
      ui.Canvas canvas, Vector2 position, double progress) {
    final radius = 20 + progress * 30;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Outer shockwave
    final shockwavePaint = ui.Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: opacity * 0.3)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      ui.Offset(position.x, position.y),
      radius * 1.5,
      shockwavePaint,
    );

    // Inner explosion
    final explosionPaint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset(position.x, position.y),
        radius,
        [
          const Color(0xFFFFEB3B).withValues(alpha: opacity),
          const Color(0xFFFF9800).withValues(alpha: opacity * 0.7),
          const Color(0xFFD84315).withValues(alpha: opacity * 0.3),
          Colors.transparent,
        ],
        [0.0, 0.3, 0.7, 1.0],
      );

    canvas.drawCircle(
      ui.Offset(position.x, position.y),
      radius,
      explosionPaint,
    );

    // Sparks
    final sparkPaint = ui.Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: opacity);

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final sparkDistance = radius + progress * 20;
      final sparkX = position.x + math.cos(angle) * sparkDistance;
      final sparkY = position.y + math.sin(angle) * sparkDistance * 0.5;

      canvas.drawCircle(
        ui.Offset(sparkX, sparkY),
        2,
        sparkPaint,
      );
    }
  }

  static void renderLaserBeam(ui.Canvas canvas, Vector2 start, Vector2 end,
      Color color, double progress) {
    final opacity = math.sin(progress * math.pi).clamp(0.0, 1.0);

    // Core beam
    final beamPaint = ui.Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 3
      ..strokeCap = ui.StrokeCap.round;

    canvas.drawLine(
      ui.Offset(start.x, start.y),
      ui.Offset(end.x, end.y),
      beamPaint,
    );

    // Glow effect
    final glowPaint = ui.Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..strokeWidth = 10
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5)
      ..strokeCap = ui.StrokeCap.round;

    canvas.drawLine(
      ui.Offset(start.x, start.y),
      ui.Offset(end.x, end.y),
      glowPaint,
    );

    // Impact point
    if (progress > 0.5) {
      final impactPaint = ui.Paint()
        ..color = color.withValues(alpha: opacity * 0.8)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

      canvas.drawCircle(
        ui.Offset(end.x, end.y),
        5 + math.sin(progress * math.pi * 4) * 3,
        impactPaint,
      );
    }
  }

  static void renderShieldHit(ui.Canvas canvas, Vector2 position, double radius,
      Color color, double progress) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    // Hexagonal ripple effect
    final rippleRadius = radius + progress * 20;
    final path = ui.Path();

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - math.pi / 6;
      final x = position.x + math.cos(angle) * rippleRadius;
      final y = position.y + math.sin(angle) * rippleRadius * 0.5;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final ripplePaint = ui.Paint()
      ..color = color.withValues(alpha: opacity * 0.5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, ripplePaint);

    // Energy discharge
    final dischargePaint = ui.Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

    canvas.drawPath(path, dischargePaint);
  }
}
