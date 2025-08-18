# Kitbash CCG - Game Design Document

## Game Overview

**Title**: Kitbash CCG  
**Genre**: Online Multiplayer Collectible Card Game  
**Platform**: Cross-platform (Mobile, Desktop, Web)  
**Target Audience**: CCG enthusiasts, strategy gamers  

## Core Gameplay

### Objective
Players build decks from their collection and battle opponents on a tactical grid with simultaneous order resolution. The goal is to destroy the opponent's Command Center by deploying units, casting spells, and executing tactics.

### Game Flow
1. **Deck Building**: Players construct 30-40 card decks
2. **Matchmaking**: Find opponents via REST API
3. **Battle**: Simultaneous planning (orders lock-in) and server-resolved rounds over WebSocket
4. **Victory**: Destroy the opponent's Command Center

## Game Mechanics

### Basic Rules
- **Command Center Health**: 30 (tunable)
- **Hand Size**: 7 cards (max 10)
- **Deck Size**: 30-40 cards
- **Round Timing**: Planning phase 30s (tunable) with lock-in; resolution phase ~3s
- **Mana System**: Progressive (1 per round, max 10)

### Round Structure (Simultaneous Orders)
1. **Draw & Income**: Draw 1 card; gain 1 mana (up to 10).
2. **Planning Phase**: Both sides simultaneously choose actions: play unit/structure cards into their deployment zone, queue spells/tactics, and assign unit abilities/targets as allowed. Players press Lock-In to commit.
3. **Reveal & Resolve**:
   - Spells/tactics resolve in priority order (see Simultaneous Resolution Rules).
   - Summoned units and built structures enter the board.
   - Start-of-round triggers fire.
   - Units automatically move based on their movement stat and rules.
   - Combat resolves (ranged and melee) with simultaneous damage application.
4. **Cleanup**: End-of-round triggers, resolve deaths, apply status durations, discard to hand limit.

### Board and Grid
- **Grid**: Default 7 columns × 9 rows (tunable). Bottom is Player A's side; top is Player B's side.
- **Coordinates**: (column, row) with row 0 as Player A back row; row 8 as Player B back row.
- **Command Centers (CC)**: Each player has a CC occupying 1 tile in the center of their back row. Destroying the enemy CC wins the match.
- **Zones**:
  - **Deployment Zone**: The two back rows on each side (rows 0–1 for Player A, rows 7–8 for Player B) unless a card states otherwise.
  - **Neutral Zone**: Middle rows (2–6 by default) where engagements occur.

### Deployment Rules
- Play unit cards into empty tiles in your deployment zone, respecting any placement restrictions on the card.
- Structures (e.g., turrets, walls) are placed on your side and occupy tiles until destroyed.
- The Command Center's position is fixed; it cannot be moved or redeployed.

### Unit Movement
- **Speed (SPD)**: Units have a movement speed stat indicating tiles moved per round during the Resolve step (default 1 forward tile toward the enemy CC).
- **Default Pathing**: Units maintain their spawn column and advance toward the enemy unless their card specifies alternate behavior.
- **Blocking & Zones of Control (ZOC)**: Units cannot move through enemy-occupied tiles. If an enemy is adjacent in the direction of travel, the moving unit stops and may attack if in range. Units with Taunt project ZOC, preventing enemies from moving past adjacent tiles.
- **Lateral Movement**: Unless a unit has a keyword (e.g., Agile/Pathfinder), units do not sidestep. Special abilities may allow diagonal or lateral moves.
- **Flying**: Flying units ignore terrain and non-flying ZOC for movement but still respect engagement rules when ending movement.
- **Collisions**: If opposing units would enter the same tile during the same round, neither enters; both remain in their original tiles and proceed to combat if in range.

### Combat Resolution
- **Ranges**: Units have an attack range (RNG). Melee units have RNG 1 (adjacent); ranged units have higher RNG.
- **Order**: After movement, all attacks resolve simultaneously. Damage is applied concurrently; units reduced to 0 HP are destroyed even if their damage would also kill the attacker.
- **Targeting**: By default, units target the closest enemy unit in range along their lane; if none, they target the enemy CC when it is within range.
- **Structures**: Structures may attack or provide effects if specified. The Command Center may have passive defenses (tunable).

### Simultaneous Resolution Rules
- **Action Lock-In**: During Planning, each player (or team) submits orders. Once both lock in or the timer expires, orders are frozen for that round.
- **Priority for Non-Unit Effects**:
  1. Global effects and state-based cleanups
  2. Spells/Tactics (sorted by card-defined priority; ties alternate by round priority token)
  3. Summons/Structures enter play
  4. Start-of-round triggers
  5. Movement (see Collisions)
  6. On-move triggers (e.g., traps, auras)
  7. Combat (simultaneous damage)
  8. Death resolution and end-of-round triggers
- **Round Priority Token**: To ensure determinism, one side holds a priority token that alternates each round; it breaks remaining ties (e.g., same-cost spells, equal-speed interactions). Final ties break by server-seeded unit IDs.

### Card Types

#### 1. Units (formerly Creatures)
- Have Attack/Health values, plus Range (RNG) and Speed (SPD)
- Occupy grid tiles and auto-move each round during resolution
- Cannot be manually moved except by card effects
- May have special abilities and keywords that modify movement, targeting, or combat

#### 2. Spells / Tactics
- One-time effects declared in Planning, resolved in Reveal & Resolve per priority
- May target units, structures, tiles, or global state
- Go to graveyard after use

#### 3. Structures (includes Command Center)
- Permanent effects that occupy tiles (e.g., walls, turrets, generators)
- Remain on battlefield until destroyed
- Command Centers are unique structures that define victory; they cannot be moved

#### 4. Auras / Attachments (formerly Enchantments)
- Buff/debuff effects attached to units, structures, or tiles
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
│ [Mana Cost]  RNG 2  │
│             SPD 1   │
│                     │
│  [Card Art]         │
│                     │
├─────────────────────┤
│ Card Name           │
│ Unit - Subtype      │
├─────────────────────┤
│ Card Text           │
│ Abilities           │
├─────────────────────┤
│ ATK/HP        3/4   │
└─────────────────────┘
```

### Keywords/Abilities
- **Haste**: Can move/attack on the round it is deployed
- **Flying**: Ignores terrain and non-flying ZOC when moving; can be targeted by effects that hit flying
- **Lifelink**: Damage dealt heals controller's Command Center by the same amount (tunable)
- **Deathtouch**: Destroys any unit it damages
- **Ward X**: Costs X more to target
- **Draw X**: Draw X cards
- **Taunt**: Projects ZOC; adjacent enemies must target this or cannot move past
- **Range X**: Sets attack distance
- **Speed X**: Tiles moved during movement step
- **Knockback**: Pushes targets backward on hit
- **Charge**: Extra forward movement before attacking
- **Overwatch**: Performs a reaction attack when an enemy enters range during movement

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
┌─────────────────────────────────────────────┐
│ Opponent Hand                               │
├─────────────────────────────────────────────┤
│                 [Opp CC]                    │
│  □ □ □ □ □ □ □   (row 8)                    │
│  □ □ □ □ □ □ □   (row 7)  ← Opp Deployment  │
│  □ □ □ □ □ □ □   (row 6)                    │
│  □ □ □ □ □ □ □   (row 5)                    │
│  □ □ □ □ □ □ □   (row 4)                    │
│  □ □ □ □ □ □ □   (row 3)                    │
│  □ □ □ □ □ □ □   (row 2)                    │
│  □ □ □ □ □ □ □   (row 1)  ← Player Deploy   │
│        [Player CC] (row 0)                  │
├─────────────────────────────────────────────┤
│ Player Hand                                 │
└─────────────────────────────────────────────┘
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
- Server-authoritative, lock-step simulation per round
- Orders are committed client-side and validated server-side; server resolves with a deterministic seed
- Alternating round priority token to break ties consistently

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