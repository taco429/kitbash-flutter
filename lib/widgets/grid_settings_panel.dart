import 'package:flutter/material.dart';
import '../game/enhanced_grid_component.dart';

/// A settings panel widget to control the visual effects of the enhanced grid
class GridSettingsPanel extends StatefulWidget {
  final EnhancedIsometricGridComponent? gridComponent;
  
  const GridSettingsPanel({Key? key, this.gridComponent}) : super(key: key);
  
  @override
  State<GridSettingsPanel> createState() => _GridSettingsPanelState();
}

class _GridSettingsPanelState extends State<GridSettingsPanel> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    final grid = widget.gridComponent;
    if (grid == null) return const SizedBox.shrink();
    
    return Positioned(
      top: 10,
      right: 10,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: _isExpanded ? 280 : 50,
        height: _isExpanded ? 320 : 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isExpanded ? _buildExpandedContent(grid) : _buildCollapsedContent(),
      ),
    );
  }
  
  Widget _buildCollapsedContent() {
    return IconButton(
      icon: const Icon(
        Icons.settings,
        color: Colors.cyan,
        size: 28,
      ),
      onPressed: () {
        setState(() {
          _isExpanded = true;
        });
      },
    );
  }
  
  Widget _buildExpandedContent(EnhancedIsometricGridComponent grid) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.cyan.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grid Visual Settings',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.cyan,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Settings
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildSettingTile(
                '3D Effects',
                'Elevation and depth rendering',
                Icons.view_in_ar,
                grid.enable3DEffect,
                (value) {
                  setState(() {
                    grid.enable3DEffect = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildSettingTile(
                'Shadows',
                'Dynamic shadow rendering',
                Icons.brightness_3,
                grid.enableShadows,
                (value) {
                  setState(() {
                    grid.enableShadows = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildSettingTile(
                'Animations',
                'Water waves and vegetation sway',
                Icons.animation,
                grid.enableAnimations,
                (value) {
                  setState(() {
                    grid.enableAnimations = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildSettingTile(
                'Particles',
                'Atmospheric particle effects',
                Icons.blur_on,
                grid.enableParticles,
                (value) {
                  setState(() {
                    grid.enableParticles = value;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Footer info
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.cyan.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Text(
            'Enhanced 2.5D/3D Grid Engine',
            style: TextStyle(
              color: Colors.cyan.withOpacity(0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? Colors.cyan.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? Colors.cyan : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: value ? Colors.white : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: value ? Colors.cyan.withOpacity(0.7) : Colors.grey.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.cyan,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}