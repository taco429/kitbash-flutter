# Card Asset Creation Guide

## Overview
This guide provides comprehensive instructions for creating card assets that work with the Advanced Card Display component. The system supports multiple card variations, rarities, and special effects.

## Asset Structure

```
assets/
├── cards/
│   ├── art/              # Card artwork
│   ├── frames/            # Card frame overlays
│   ├── overlays/          # Special effect overlays
│   └── backs/             # Card back designs
```

## Card Variations Supported

### 1. **Standard Cards**
- Basic card layout with traditional frame
- Art window: 240x180px (at 300 DPI)
- Full card size: 280x400px

### 2. **Alternate Art**
- Same frame, different artwork
- Naming: `{cardId}_alternate_{resolution}.webp`

### 3. **Borderless**
- Art extends to card edges
- Art size: 280x400px (full bleed)
- No frame overlay needed

### 4. **Frame Break**
- Art elements extend beyond the art window
- Requires transparent PNG with overflow elements
- Base art: 240x180px with overflow areas

### 5. **Holographic**
- Standard art with holographic overlay effect
- Art remains standard size
- System applies animated shader effect

### 6. **Foil Etched**
- Textured metallic appearance
- Standard art size
- System applies etched pattern overlay

### 7. **Extended Art**
- Art extends into text box area
- Art size: 240x280px
- Reduced text area

### 8. **Showcase**
- Special artistic frame treatment
- Custom frame design per set
- Art window varies by frame design

### 9. **Retro Frame**
- Classic card game aesthetic
- Art window: 220x165px
- Thicker borders

### 10. **Full Art**
- Art covers entire card
- Art size: 280x400px
- Text overlaid on art

## Asset Specifications

### Resolution Guidelines

Create assets at multiple resolutions for optimal performance:

| Resolution | Dimensions | Use Case | File Size Target |
|------------|------------|----------|------------------|
| `low` | 140x200px | Thumbnails, collection view | <50KB |
| `medium` | 280x400px | Standard gameplay | <150KB |
| `high` | 560x800px | Zoomed view, showcase | <400KB |
| `ultra` | 840x1200px | Print quality, wallpapers | <1MB |

### File Formats

- **WebP** (Preferred): Best compression, transparency support
- **PNG**: For assets requiring transparency
- **JPG**: Fallback for photographs without transparency

### Naming Convention

```
{cardId}_{variation}_{premium}_{resolution}.{format}

Examples:
- dragon_lord_001_standard_medium.webp
- dragon_lord_001_holo_premium_high.webp
- dragon_lord_001_borderless_medium.webp
```

## Creating Card Artwork

### 1. Base Artwork Creation

**Software Recommendations:**
- Adobe Photoshop / Illustrator
- Procreate (iPad)
- Clip Studio Paint
- Krita (Free)
- GIMP (Free)

**Canvas Setup:**
1. Create at 840x1200px (3x display size)
2. Work in RGB color mode
3. Use 300 DPI for print compatibility
4. Save working file with layers (PSD/KRA)

### 2. Art Guidelines

**Composition:**
- Focus point at center-upper third
- Leave space for UI elements at bottom
- Consider frame cropping for standard variant
- Ensure readability at small sizes

**Color Considerations:**
- Match card's color identity
- Maintain contrast with frame colors
- Test visibility with overlays

### 3. Variation-Specific Guidelines

#### Standard Cards
```
Art Safe Zone: 220x160px (centered)
Bleed Area: 10px on all sides
Text Safe Zone: Bottom 120px
```

#### Borderless/Full Art
```
Full Bleed: 280x400px
Critical Elements: Avoid outer 20px
Text Overlay Areas: Bottom 100px, semi-transparent backing
```

#### Frame Break
```
Base Art: Standard size
Break Elements: Extend 20-40px beyond frame
Transparency: Required for overflow
File Format: PNG with alpha channel
```

## Creating Frame Assets

### Frame Components

1. **Outer Border**: 15-20px width
2. **Inner Border**: 5-8px width
3. **Decorative Elements**: Corners, sides
4. **Rarity Indicators**: Gem slots, foil stamps

### Rarity-Specific Frames

```scss
// Color schemes for each rarity
Common: #9E9E9E (Grey)
Uncommon: #4CAF50 (Green)
Rare: #2196F3 (Blue)
Epic: #9C27B0 (Purple)
Legendary: #FF9800 (Orange)
Mythic: #FF5252 (Red)
```

### Frame Creation Process

1. **Create Base Template** (Photoshop/Illustrator)
   ```
   - Size: 280x400px
   - Transparent background
   - Vector shapes preferred
   ```

2. **Add Rarity Elements**
   - Gradient overlays matching rarity colors
   - Metallic textures for higher rarities
   - Glow effects for legendary/mythic

3. **Export Guidelines**
   - Save as PNG with transparency
   - Optimize file size (<100KB)
   - Test overlay on various backgrounds

## Special Effect Overlays

### Holographic Pattern
```
File: holographic_pattern.webp
Size: 280x400px
Type: Tileable, semi-transparent
Animation: Handled by shader in-app
```

Create using:
1. Prismatic gradient (rainbow)
2. 30-50% opacity
3. Diagonal light streaks
4. Subtle geometric patterns

### Foil Etched Texture
```
File: foil_etched_texture.webp
Size: 512x512px (tileable)
Type: Grayscale height map
```

Create using:
1. Metallic brush textures
2. Etched line patterns
3. Convert to grayscale
4. Apply as normal map in-app

### Premium Shine
```
File: premium_shine.webp
Size: 280x400px
Type: Radial gradient, animated in-app
```

### Promo Stamp
```
File: promo_stamp.png
Size: 80x80px
Type: Gold/silver metallic stamp
Position: Lower-right, 20px margin
```

## Card Back Designs

### Requirements
- Size: 280x400px
- Must be symmetrical or pattern-based
- Include game logo/symbol
- Rarity-specific variants optional

### Design Elements
1. **Central Symbol**: 100x100px
2. **Border Pattern**: Geometric or ornamental
3. **Background**: Gradient or texture
4. **Security Pattern**: Fine details to prevent counterfeiting

## Optimization Guidelines

### File Size Optimization

1. **WebP Conversion**
   ```bash
   # Using cwebp tool
   cwebp -q 85 input.png -o output.webp
   
   # Batch conversion
   for file in *.png; do
     cwebp -q 85 "$file" -o "${file%.png}.webp"
   done
   ```

2. **PNG Optimization**
   ```bash
   # Using optipng
   optipng -o5 *.png
   
   # Using pngquant for lossy compression
   pngquant --quality=85-95 *.png
   ```

### Performance Considerations

1. **Lazy Loading**: Implement for collection views
2. **Progressive Loading**: Low → Medium → High resolution
3. **Caching Strategy**: Store frequently used cards
4. **CDN Delivery**: Use for production deployment

## Asset Production Pipeline

### 1. Concept Phase
- Sketch thumbnails
- Get approval on composition
- Define variation requirements

### 2. Production Phase
- Create high-res artwork
- Apply to card template
- Test in-game appearance

### 3. Variation Creation
- Generate required variations
- Apply special effects
- Create resolution variants

### 4. Optimization Phase
- Compress files
- Test loading performance
- Validate naming conventions

### 5. Integration Phase
- Upload to asset directory
- Update card database
- Test in showcase mode

## Batch Processing Scripts

### ImageMagick Commands

```bash
# Resize to multiple resolutions
convert input.png -resize 140x200 output_low.webp
convert input.png -resize 280x400 output_medium.webp
convert input.png -resize 560x800 output_high.webp

# Add frame overlay
composite -gravity center frame.png art.png framed_card.png

# Create holographic effect (basic)
convert input.png -modulate 100,150,100 \
  -colorspace HSL -channel Lightness \
  -level 20%,80% +channel -colorspace sRGB \
  holographic.png
```

### Photoshop Actions

Create actions for:
1. Resize to standard resolutions
2. Apply frame overlays
3. Add rarity glow effects
4. Export to multiple formats

## Quality Checklist

### Before Integration
- [ ] All resolutions created
- [ ] File sizes within targets
- [ ] Naming convention followed
- [ ] Transparency preserved (where needed)
- [ ] Colors accurate to original
- [ ] Text remains readable
- [ ] Special effects visible
- [ ] Card back included
- [ ] Tested at small sizes
- [ ] Performance acceptable

### Testing in App
- [ ] Loads without errors
- [ ] Animations smooth
- [ ] Parallax effect works
- [ ] Flip animation correct
- [ ] Glow effects visible
- [ ] Frame overlays align
- [ ] Text overlays readable
- [ ] Memory usage acceptable
- [ ] Cache working properly
- [ ] Showcase mode displays correctly

## Asset Delivery Structure

```json
{
  "cardId": "dragon_lord_001",
  "assets": {
    "standard": {
      "low": "assets/cards/art/dragon_lord_001_standard_low.webp",
      "medium": "assets/cards/art/dragon_lord_001_standard_medium.webp",
      "high": "assets/cards/art/dragon_lord_001_standard_high.webp"
    },
    "alternate": {
      "low": "assets/cards/art/dragon_lord_001_alternate_low.webp",
      "medium": "assets/cards/art/dragon_lord_001_alternate_medium.webp",
      "high": "assets/cards/art/dragon_lord_001_alternate_high.webp"
    },
    "borderless": {
      "medium": "assets/cards/art/dragon_lord_001_borderless_medium.webp",
      "high": "assets/cards/art/dragon_lord_001_borderless_high.webp"
    }
  },
  "frames": {
    "standard": "assets/cards/frames/standard_epic.png",
    "showcase": "assets/cards/frames/showcase_epic.png",
    "retro": "assets/cards/frames/retro_epic.png"
  },
  "back": "assets/cards/backs/default_back.webp"
}
```

## Placeholder Assets

While creating final assets, use these placeholder generators:

### Gradient Placeholder
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [color1, color2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
)
```

### Pattern Placeholder
Use SVG patterns or procedural generation for temporary cards.

## Resources

### Free Asset Resources
- **Unsplash**: High-quality photos
- **Pixabay**: Free illustrations
- **OpenGameArt**: Game-specific assets
- **Freepik**: Vectors and illustrations

### AI Art Generation
- **Midjourney**: High-quality card art
- **Stable Diffusion**: Open-source option
- **DALL-E**: Quick iterations
- **Leonardo.ai**: Game art focused

### Prompt Template for AI:
```
"Fantasy [creature/spell/location] card art, 
digital painting, highly detailed, 
[color] color palette, 
magic the gathering style, 
artstation quality, 
centered composition, 
dramatic lighting"
```

## Conclusion

This guide provides the foundation for creating professional card assets. Remember to:
1. Maintain consistency across variations
2. Optimize for performance
3. Test at all resolutions
4. Follow naming conventions
5. Document any custom requirements

For questions or updates to this guide, please refer to the project documentation or contact the development team.