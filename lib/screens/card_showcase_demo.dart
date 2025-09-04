import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/card_variation.dart';
import '../widgets/advanced_card_display.dart';

/// Demo screen showcasing all card variations and visual effects
class CardShowcaseDemo extends StatefulWidget {
  const CardShowcaseDemo({super.key});

  @override
  State<CardShowcaseDemo> createState() => _CardShowcaseDemoState();
}

class _CardShowcaseDemoState extends State<CardShowcaseDemo> {
  // Current selected variation
  CardVariation _selectedVariation = CardVariation.standard;
  CardRarity _selectedRarity = CardRarity.rare;
  bool _isPremium = false;
  bool _isPromo = false;
  bool _enableParallax = true;
  bool _enableGlow = true;
  double _cardScale = 1.0;

  // Sample cards for demonstration
  final List<GameCard> _sampleCards = [
    GameCard(
      id: 'demo_dragon_001',
      name: 'Ancient Dragon Lord',
      description: 'Flying, Trample. When Ancient Dragon Lord enters the battlefield, deal 3 damage to any target.',
      goldCost: 3,
      manaCost: 5,
      type: CardType.unit,
      color: CardColor.red,
      unitStats: const UnitStats(
        attack: 8,
        health: 8,
        armor: 2,
        speed: 3,
        range: 2,
      ),
      abilities: ['Flying', 'Trample', 'Firebreath'],
      flavorText: 'The skies burn with ancient fury.',
    ),
    GameCard(
      id: 'demo_spell_001',
      name: 'Lightning Storm',
      description: 'Deal 4 damage to all enemy units. Draw a card.',
      goldCost: 2,
      manaCost: 3,
      type: CardType.spell,
      color: CardColor.blue,
      spellEffect: const SpellEffect(
        targetType: 'all_enemies',
        effect: 'damage_4_draw_1',
      ),
      abilities: ['Instant'],
      flavorText: 'Thunder echoes through the battlefield.',
    ),
    GameCard(
      id: 'demo_hero_001',
      name: 'Valeria, Storm Knight',
      description: 'Charge, Vigilance. Other knights you control get +1/+1.',
      goldCost: 4,
      manaCost: 2,
      type: CardType.hero,
      color: CardColor.purple,
      heroStats: const HeroStats(
        attack: 5,
        health: 6,
        armor: 3,
        speed: 2,
        range: 1,
        cooldown: 2,
      ),
      abilities: ['Charge', 'Vigilance', 'Knight Lord'],
      flavorText: 'Leader of the Storm Legion.',
    ),
    GameCard(
      id: 'demo_building_001',
      name: 'Mystic Tower',
      description: 'At the beginning of your turn, gain 2 mana.',
      goldCost: 3,
      manaCost: 0,
      type: CardType.building,
      color: CardColor.green,
      buildingStats: const BuildingStats(
        health: 10,
        armor: 5,
        attack: null,
        range: null,
      ),
      abilities: ['Mana Generation'],
      flavorText: 'Where magic flows eternal.',
    ),
  ];

  int _currentCardIndex = 0;

  GameCard get _currentCard => _sampleCards[_currentCardIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Advanced Card Display Showcase'),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Row(
        children: [
          // Control Panel
          Container(
            width: 350,
            color: Colors.black54,
            child: _buildControlPanel(),
          ),
          
          // Card Display Area
          Expanded(
            child: _buildCardDisplayArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Card Selection'),
        _buildCardSelector(),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Variation'),
        _buildVariationSelector(),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Rarity'),
        _buildRaritySelector(),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Special Effects'),
        _buildEffectsControls(),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Display Options'),
        _buildDisplayControls(),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Card Info'),
        _buildCardInfo(),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardSelector() {
    return Column(
      children: _sampleCards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        return RadioListTile<int>(
          value: index,
          groupValue: _currentCardIndex,
          onChanged: (value) {
            setState(() {
              _currentCardIndex = value!;
            });
          },
          title: Text(
            card.name,
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            '${card.type.displayName} - ${card.color.displayName}',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          activeColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildVariationSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CardVariation.values.map((variation) {
        return ChoiceChip(
          label: Text(variation.displayName),
          selected: _selectedVariation == variation,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedVariation = variation;
              });
            }
          },
          selectedColor: Theme.of(context).primaryColor,
        );
      }).toList(),
    );
  }

  Widget _buildRaritySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CardRarity.values.map((rarity) {
        return ChoiceChip(
          label: Text(rarity.displayName),
          selected: _selectedRarity == rarity,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedRarity = rarity;
              });
            }
          },
          selectedColor: Color(rarity.glowColors[0]),
        );
      }).toList(),
    );
  }

  Widget _buildEffectsControls() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Premium', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            'Adds premium shine effect',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          value: _isPremium,
          onChanged: (value) {
            setState(() {
              _isPremium = value;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        SwitchListTile(
          title: const Text('Promo', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            'Adds promo stamp',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          value: _isPromo,
          onChanged: (value) {
            setState(() {
              _isPromo = value;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        SwitchListTile(
          title: const Text('Parallax', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            'Enable 3D parallax effect',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          value: _enableParallax,
          onChanged: (value) {
            setState(() {
              _enableParallax = value;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
        SwitchListTile(
          title: const Text('Glow', style: TextStyle(color: Colors.white)),
          subtitle: Text(
            'Enable rarity glow',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          value: _enableGlow,
          onChanged: (value) {
            setState(() {
              _enableGlow = value;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildDisplayControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Scale: ${_cardScale.toStringAsFixed(1)}x',
          style: const TextStyle(color: Colors.white),
        ),
        Slider(
          value: _cardScale,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) {
            setState(() {
              _cardScale = value;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildCardInfo() {
    final visualData = CardVisualData(
      cardId: _currentCard.id,
      variation: _selectedVariation,
      rarity: _selectedRarity,
      isPremium: _isPremium,
      isPromo: _isPromo,
      artistName: 'Demo Artist',
      setCode: 'DEMO',
      collectorNumber: 1,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Card ID:', _currentCard.id),
          _buildInfoRow('Variation:', visualData.variation.displayName),
          _buildInfoRow('Rarity:', visualData.rarity.displayName),
          _buildInfoRow('Premium:', visualData.isPremium ? 'Yes' : 'No'),
          _buildInfoRow('Promo:', visualData.isPromo ? 'Yes' : 'No'),
          const SizedBox(height: 8),
          Text(
            'Asset Path:',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          Text(
            visualData.getArtAssetPath(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDisplayArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
          radius: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main card display
            Transform.scale(
              scale: _cardScale,
              child: AdvancedCardDisplay(
                card: _currentCard,
                visualData: CardVisualData(
                  cardId: _currentCard.id,
                  variation: _selectedVariation,
                  rarity: _selectedRarity,
                  isPremium: _isPremium,
                  isPromo: _isPromo,
                  artistName: 'Demo Artist',
                  setCode: 'DEMO',
                  collectorNumber: 1,
                ),
                width: 280,
                height: 400,
                enableParallax: _enableParallax,
                enableGlow: _enableGlow,
                onDoubleTap: () {
                  // Card will flip on double tap
                },
              ),
            ),
            const SizedBox(height: 40),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Interactive Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Hover over card for zoom effect\n'
                    '• Move mouse over card for parallax (if enabled)\n'
                    '• Double-click to flip card\n'
                    '• Use controls on the left to customize',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}