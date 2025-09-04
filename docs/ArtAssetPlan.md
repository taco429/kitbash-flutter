### Card Art Asset Production Plan

This plan outlines how to create and organize art assets to support multiple card variants: standard, alternate art, borderless, frame break, and holographic.

#### 1) Art Direction and Specs
- **Target size**: Master art at 2048x3072 PNG (or PSD) to allow high-DPI scaling
- **Safe area**: Design with a central safe area (80% width/height) for key subject
- **Composition**: Leave background bleed for borderless; keep the focal subject centered for frame break scaling
- **Color profile**: sRGB; avoid extreme saturation clipping
- **File format**: PNG with alpha; keep a layered working file (PSD/Krita/XCF)

#### 2) Variants per card
- **Standard**: `standard.png` — clean composition with framing margins
- **Alternate Art**: `alt.png` — stylistic or pose variation; must share silhouette readability
- **Borderless**: reuse `standard.png` but ensure full-bleed background is extended; avoid hard edges at borders
- **Frame Break**: reuse `standard.png`; ensure subject has head/weapon/element that looks good when slightly scaled and cropped (top 8–12%)
- **Holographic**: no unique art required; the shader overlay is applied at runtime

#### 3) File structure
```
assets/
  images/
    cards/
      celestial_vanguard/
        standard.png
        alt.png
      ember_mage/
        standard.png
        alt.png
```

#### 4) Naming and slugs
- Use lowercase snake_case slugs for directories: `celestial_vanguard`
- Map game data `GameCard.id` -> slug via your content pipeline (or store explicit art paths if preferred)

#### 5) Export guidelines
- Export PNG at 2048x3072
- Also export a medium size 1024x1536 if bandwidth is a concern
- Keep transparent edges minimal; art should reach edges for borderless look

#### 6) Quality checks
- Verify legibility of the subject at 120px width (compact) and 180–220px width (standard)
- Ensure important details remain inside safe area after frame-break scaling
- Check contrast under overlay scrims; text must be readable

#### 7) Pipeline suggestions
- Use a shared template with guides (safe area, bleed) to speed up consistency
- Batch export using Photoshop actions or Krita Python scripts
- Optional: generate webp derivatives for web builds if needed

#### 8) Integration steps
- Place PNGs in `assets/images/cards/<slug>/`
- Ensure `pubspec.yaml` includes `assets/images/` (already configured)
- Reference from code:
  ```dart
  CardDisplay(
    card: card,
    artAsset: 'assets/images/cards/celestial_vanguard/standard.png',
    alternateArtAsset: 'assets/images/cards/celestial_vanguard/alt.png',
  )
  ```

#### 9) Future enhancements
- Add foil patterns using a custom `FragmentProgram` shader for smoother GPU sheen
- Support rarity frames/badges from a sprite atlas
- Add `frameSvgPath` to overlay vector frames at any resolution

