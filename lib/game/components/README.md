# Game Components

This directory contains Flame game components for the Kitbash CCG.

## Drag and Drop in Flame

The drag detection system in Flame has evolved across versions. Here's how it works in Flame 1.13.0:

### Basic Setup

1. **Add the mixins to your game class:**
   ```dart
   class MyGame extends FlameGame with TapCallbacks, DragCallbacks {
     // ...
   }
   ```

2. **Add the mixins to draggable components:**
   ```dart
   class DraggableComponent extends PositionComponent with DragCallbacks {
     // ...
   }
   ```

### Event Handlers

The main drag events are:
- `onDragStart(DragStartEvent event)` - Called when drag begins
- `onDragUpdate(DragUpdateEvent event)` - Called during drag movement
- `onDragEnd(DragEndEvent event)` - Called when drag ends

### Common Patterns

1. **Track drag offset:**
   ```dart
   Vector2? _dragOffset;
   
   @override
   void onDragStart(DragStartEvent event) {
     _dragOffset = event.localPosition - position;
   }
   ```

2. **Bring component to front:**
   ```dart
   priority = 1000; // Higher priority renders on top
   ```

3. **Add visual feedback:**
   ```dart
   add(ScaleEffect.to(
     Vector2.all(1.1),
     EffectController(duration: 0.1),
   ));
   ```

### Position Access

Different event types provide different position information:
- `TapDownEvent`: Has `localPosition` and `canvasPosition`
- `DragStartEvent`: Has `localPosition` 
- `DragUpdateEvent`: Position tracking varies by version
- `DragEndEvent`: May not have position data

### Tips

1. Always call `super` in event handlers
2. Use `containsLocalPoint()` to define hit areas
3. Consider using `priority` for z-ordering
4. Add visual feedback for better UX
5. Test on different devices for touch sensitivity

## Example Components

- `card_component.dart` - Basic draggable card implementation
- More components to be added as the game develops

## Resources

- [Flame Documentation](https://docs.flame-engine.org/)
- [Flame Examples](https://github.com/flame-engine/flame/tree/main/examples) 