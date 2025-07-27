# Kitbash CCG - Game Design Document

## Game Overview

**Title**: Kitbash CCG  
**Genre**: Online Multiplayer Collectible Card Game  
**Platform**: Cross-platform (Mobile, Desktop, Web)  
**Target Audience**: CCG enthusiasts, strategy gamers  

## Core Gameplay

### Objective
Players build decks from their collection and battle opponents in strategic turn-based matches. The goal is to reduce the opponent's life points to zero using creatures, spells, and tactics.

### Game Flow
1. **Deck Building**: Players construct 30-40 card decks
2. **Matchmaking**: Find opponents via REST API
3. **Battle**: Real-time multiplayer via WebSocket
4. **Victory**: First to reduce opponent to 0 life wins

## Game Mechanics

### Basic Rules
- **Starting Life**: 20 points
- **Hand Size**: 7 cards (max 10)
- **Deck Size**: 30-40 cards
- **Turn Time**: 90 seconds
- **Mana System**: Progressive (1 per turn, max 10)

### Turn Structure
1. **Draw Phase**: Draw 1 card
2. **Main Phase 1**: Play cards, activate abilities
3. **Combat Phase**: Attack with creatures
4. **Main Phase 2**: Play additional cards
5. **End Phase**: Cleanup, discard to hand limit

### Card Types

#### 1. Creatures
- Have Attack/Defense values
- Can attack opponents or defend
- May have special abilities
- Remain on battlefield until destroyed

#### 2. Spells
- One-time effects
- Instant or sorcery speed
- Go to graveyard after use

#### 3. Artifacts
- Permanent effects
- Remain on battlefield
- Can be destroyed by specific cards

#### 4. Enchantments
- Buff/debuff effects
- Can target creatures or players
- Persistent until removed

### Resource System
- **Mana**: Primary resource for playing cards
- **Card Draw**: Limited to maintain balance
- **Special Resources**: Faction-specific mechanics

## Card Design

### Rarity Tiers
1. **Common** (Gray) - Basic cards, high drop rate
2. **Uncommon** (Green) - Slightly better, moderate drop rate
3. **Rare** (Blue) - Powerful cards, low drop rate
4. **Epic** (Purple) - Very powerful, very low drop rate
5. **Legendary** (Gold) - Unique effects, extremely rare

### Card Anatomy
```
┌─────────────────────┐
│ [Mana Cost]    [3]  │
│                     │
│  [Card Art]         │
│                     │
├─────────────────────┤
│ Card Name           │
│ Type - Subtype      │
├─────────────────────┤
│ Card Text           │
│ Abilities           │
├─────────────────────┤
│ ATK/DEF        3/4  │
└─────────────────────┘
```

### Keywords/Abilities
- **Haste**: Can attack immediately
- **Flying**: Can only be blocked by flying
- **Lifelink**: Damage dealt gains life
- **Deathtouch**: Destroys any creature it damages
- **Ward X**: Costs X more to target
- **Draw X**: Draw X cards
- **Taunt**: Must be attacked first

## Factions/Colors

### 1. Order (White)
- **Theme**: Protection, healing, small creatures
- **Mechanics**: Lifegain, damage prevention
- **Playstyle**: Defensive, board control

### 2. Wisdom (Blue)
- **Theme**: Spells, card draw, control
- **Mechanics**: Counterspells, card advantage
- **Playstyle**: Reactive, combo-oriented

### 3. Death (Black)
- **Theme**: Destruction, graveyard, sacrifice
- **Mechanics**: Removal, recursion
- **Playstyle**: Aggressive removal

### 4. Chaos (Red)
- **Theme**: Direct damage, aggressive creatures
- **Mechanics**: Burn spells, haste
- **Playstyle**: Fast, aggressive

### 5. Nature (Green)
- **Theme**: Big creatures, mana ramp
- **Mechanics**: Mana acceleration, buffs
- **Playstyle**: Midrange, creature-focused

## Game Modes

### 1. Ranked Play
- Competitive ladder system
- Seasonal rankings
- Rewards based on rank

### 2. Casual Play
- Unranked matches
- Experimental decks
- No rank impact

### 3. Draft Mode (Future)
- Build deck from random cards
- Tournament structure
- Entry fee and prizes

### 4. Campaign (Future)
- Single-player story mode
- AI opponents
- Unlock cards and lore

### 5. Daily Challenges
- Special rules/restrictions
- Bonus rewards
- Rotates daily

## Progression System

### Player Level
- XP gained from matches
- Unlock features and modes
- Cosmetic rewards

### Collection Building
- Cards earned through:
  - Victory rewards
  - Daily quests
  - Booster packs
  - Crafting system

### Crafting System
- Dust from duplicate cards
- Craft specific cards
- Rarity-based costs

## Monetization (Future)

### Free-to-Play Model
- Core game free
- Earn cards through play
- No pay-to-win mechanics

### Premium Options
- Cosmetic card backs
- Alternate art cards
- Battle pass system
- Booster pack bundles

## UI/UX Design

### Main Menu
- Play button (prominent)
- Collection manager
- Deck builder
- Store
- Profile/Stats
- Settings

### In-Game UI
```
┌─────────────────────────────────────┐
│ Opponent Hand (5 cards)             │
├─────────────────────────────────────┤
│                                     │
│     Opponent Battlefield            │
│                                     │
├─────────────────────────────────────┤
│                                     │
│     Player Battlefield              │
│                                     │
├─────────────────────────────────────┤
│ Player Hand (7 cards)               │
└─────────────────────────────────────┘
```

### Visual Style
- Clean, modern interface
- Readable card text
- Clear status indicators
- Smooth animations
- Particle effects for abilities

## Audio Design

### Sound Effects
- Card draw
- Card play
- Attack/damage
- Ability activation
- Victory/defeat

### Music
- Menu theme
- Battle themes (per faction)
- Victory fanfare
- Ambient battlefield

## Technical Considerations

### Performance
- 60 FPS target
- Optimized for mobile
- Efficient asset loading
- Minimal battery drain

### Network
- Low latency critical
- Graceful disconnection handling
- Reconnection support
- Anti-cheat measures

## Competitive Design

### Balance Philosophy
- No dominant strategy
- Multiple viable archetypes
- Regular balance updates
- Community feedback

### Ranking System
- Bronze → Silver → Gold → Platinum → Diamond → Master
- Monthly seasons
- Placement matches
- Rank protection

## Social Features

### Friends List
- Add friends
- Challenge to matches
- Spectate games
- Chat functionality

### Guilds/Clans (Future)
- Guild battles
- Shared rewards
- Guild chat
- Tournaments

## Content Roadmap

### Launch (MVP)
- Core gameplay
- 100+ cards
- Basic progression
- Ranked play

### Month 1-3
- New card set (50+ cards)
- Draft mode
- Daily challenges
- Balance patches

### Month 4-6
- Campaign mode
- Guild system
- Tournament mode
- Mobile optimization

### Year 1
- 4 expansion sets
- New game modes
- Esports features
- Cross-platform play 