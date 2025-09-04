/// Represents different visual variations of a card
enum CardVariation {
  standard('Standard', 'standard'),
  alternateArt('Alternate Art', 'alternate'),
  borderless('Borderless', 'borderless'),
  frameBreak('Frame Break', 'framebreak'),
  holographic('Holographic', 'holo'),
  foilEtched('Foil Etched', 'foil_etched'),
  extendedArt('Extended Art', 'extended'),
  showcase('Showcase', 'showcase'),
  retro('Retro Frame', 'retro'),
  fullArt('Full Art', 'fullart');

  const CardVariation(this.displayName, this.assetSuffix);
  final String displayName;
  final String assetSuffix;
}

/// Represents the rarity of a card which affects visual presentation
enum CardRarity {
  common('Common', 1),
  uncommon('Uncommon', 2),
  rare('Rare', 3),
  epic('Epic', 4),
  legendary('Legendary', 5),
  mythic('Mythic', 6);

  const CardRarity(this.displayName, this.tier);
  final String displayName;
  final int tier;

  /// Returns the glow color for this rarity
  List<int> get glowColors {
    switch (this) {
      case CardRarity.common:
        return [0xFF9E9E9E, 0xFF757575]; // Grey
      case CardRarity.uncommon:
        return [0xFF4CAF50, 0xFF2E7D32]; // Green
      case CardRarity.rare:
        return [0xFF2196F3, 0xFF1565C0]; // Blue
      case CardRarity.epic:
        return [0xFF9C27B0, 0xFF6A1B9A]; // Purple
      case CardRarity.legendary:
        return [0xFFFF9800, 0xFFE65100]; // Orange
      case CardRarity.mythic:
        return [0xFFFF5252, 0xFFC62828]; // Red
    }
  }
}

/// Extended card model with visual variation support
class CardVisualData {
  final String cardId;
  final CardVariation variation;
  final CardRarity rarity;
  final String? artistName;
  final String? setCode;
  final int? collectorNumber;
  final bool isPremium;
  final bool isPromo;
  final String? flavorText;
  final Map<String, String>? artAssets; // Different resolution art assets

  const CardVisualData({
    required this.cardId,
    this.variation = CardVariation.standard,
    this.rarity = CardRarity.common,
    this.artistName,
    this.setCode,
    this.collectorNumber,
    this.isPremium = false,
    this.isPromo = false,
    this.flavorText,
    this.artAssets,
  });

  /// Get the art asset path for a specific resolution
  String getArtAssetPath({String resolution = 'medium'}) {
    // Priority: custom assets > generated path
    if (artAssets != null && artAssets!.containsKey(resolution)) {
      return artAssets![resolution]!;
    }
    
    // Generate default path based on card ID and variation
    final basePath = 'assets/cards/art';
    final variationPath = variation == CardVariation.standard 
        ? '' 
        : '_${variation.assetSuffix}';
    final premiumPath = isPremium ? '_premium' : '';
    
    return '$basePath/${cardId}${variationPath}${premiumPath}_$resolution.webp';
  }

  /// Get the frame asset path based on variation and rarity
  String getFrameAssetPath() {
    final basePath = 'assets/cards/frames';
    final rarityName = rarity.name;
    final variationName = variation.assetSuffix;
    
    return '$basePath/${variationName}_${rarityName}.png';
  }

  /// Get overlay effects for special variations
  List<String> getOverlayAssets() {
    final overlays = <String>[];
    
    if (variation == CardVariation.holographic) {
      overlays.add('assets/cards/overlays/holographic_pattern.webp');
    }
    
    if (variation == CardVariation.foilEtched) {
      overlays.add('assets/cards/overlays/foil_etched_texture.webp');
    }
    
    if (isPremium) {
      overlays.add('assets/cards/overlays/premium_shine.webp');
    }
    
    if (isPromo) {
      overlays.add('assets/cards/overlays/promo_stamp.png');
    }
    
    return overlays;
  }

  CardVisualData copyWith({
    String? cardId,
    CardVariation? variation,
    CardRarity? rarity,
    String? artistName,
    String? setCode,
    int? collectorNumber,
    bool? isPremium,
    bool? isPromo,
    String? flavorText,
    Map<String, String>? artAssets,
  }) {
    return CardVisualData(
      cardId: cardId ?? this.cardId,
      variation: variation ?? this.variation,
      rarity: rarity ?? this.rarity,
      artistName: artistName ?? this.artistName,
      setCode: setCode ?? this.setCode,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      isPremium: isPremium ?? this.isPremium,
      isPromo: isPromo ?? this.isPromo,
      flavorText: flavorText ?? this.flavorText,
      artAssets: artAssets ?? this.artAssets,
    );
  }
}