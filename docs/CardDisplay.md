### CardDisplay widget

The `CardDisplay` widget is a reusable, performant card renderer focused on showcasing exciting art while keeping overlays readable. It supports multiple visual effects: alternate art, borderless, frame break, and holographic.

#### Location
- File: `lib/widgets/card_display.dart`
- Demo: `lib/screens/card_showcase_screen.dart` (linked from `MenuScreen` via "Card Showcase")

#### API
- `CardDisplay({
    required GameCard card,
    Set<CardStyleEffect> effects = const {},
    String? artAsset,
    String? alternateArtAsset,
    double width = 180,
    double aspectRatio = 0.75,
    bool showOverlays = true,
    VoidCallback? onTap,
  })`

- `CardStyleEffect` values:
  - `alternateArt`: Use `alternateArtAsset` when provided
  - `borderless`: Remove rounded frame and bleed art to the edge
  - `frameBreak`: Scale/offset art to break the frame subtly
  - `holographic`: Animated iridescent sheen overlay

#### Usage examples

Standard card:
```dart
CardDisplay(
  card: myCard,
  artAsset: 'assets/images/cards/celestial_vanguard/standard.png',
  width: 180,
)
```

Alternate art:
```dart
CardDisplay(
  card: myCard,
  effects: const {CardStyleEffect.alternateArt},
  artAsset: 'assets/images/cards/celestial_vanguard/standard.png',
  alternateArtAsset: 'assets/images/cards/celestial_vanguard/alt.png',
)
```

Borderless + holographic:
```dart
CardDisplay(
  card: myCard,
  effects: const {CardStyleEffect.borderless, CardStyleEffect.holographic},
)
```

Frame break:
```dart
CardDisplay(
  card: myCard,
  effects: const {CardStyleEffect.frameBreak},
)
```

#### Asset paths
- Art images should be placed under `assets/images/cards/<card_slug>/...`
- `pubspec.yaml` already includes `assets/images/`
- Use `Image.asset` paths like `assets/images/cards/<slug>/standard.png`

#### Performance notes
- Uses `RepaintBoundary` to isolate rendering
- Holographic sheen animates with a single `AnimationController`
- `filterQuality: FilterQuality.medium` to balance clarity and performance
- Fallback gradient placeholder renders when assets are missing

#### Styling choices
- Default aspect ratio: `0.75` for readability on mobile; adjust via `aspectRatio`
- Overlays prioritize legibility with subtle background scrims
- Effects are composable; combine them via the `effects` set

