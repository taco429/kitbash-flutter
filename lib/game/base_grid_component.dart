import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../models/tile_data.dart';

/// Base interface for grid components used by the game
abstract class BaseGridComponent extends PositionComponent {
  BaseGridComponent({super.children, super.priority, super.key});

  /// Handle a tap in the component's local coordinate space
  void handleTap(Vector2 localPoint);

  /// Handle a hover in the component's local coordinate space
  TileData? handleHover(Vector2 localPoint);

  /// Clear any active hover state
  void clearHover();
}
