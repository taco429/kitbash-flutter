# Kitbash CCG - Meta Features

## Overview

This document outlines all progression and wrapper systems outside of an individual match. It covers collection management, deck building, world map exploration with NPC encounters, and PvP matchmaking and rankings.

## Collection & Progression

### Card Acquisition
- Sources of cards:
  - NPC battles on the world map (first-clear rewards, repeatable drops, and milestone chests)
  - Region-specific card unlocks and blueprints
  - PvP seasonal rewards and ranked chests
  - Quests and limited-time events
  - Shop (cosmetics, guaranteed unlock paths, and pity systems)

### Rarity & Duplication
- Rarities: Common, Uncommon, Rare, Epic, Legendary (tunable)
- Duplicate handling:
  - Convert extra copies into crafting currency (“Essence/Dust”)
  - Hard cap on usable duplicates per card based on deck-building rules
- Pity/progression:
  - Soft pity for high-rarity unlocks via blueprint fragments

### Crafting
- Blueprint fragments drop from NPCs/regions tied to factions/biomes
- Crafting cost scales with rarity; discounts for owning fragments
- Conversion: Duplicates -> Essence; Essence + Fragments -> Target Card

### Collection Browser
- Filters: faction, rarity, cost, type (unit/structure/spell/tactic), owned/not owned
- Sort: alphabetical, rarity, cost, release set, recent
- Tagging: allow custom tags and favorites
- Details: full rules text, art, variants/skins, acquisition source

## Deck Building

### Constraints & Validation
- Deck size: 30–40 cards (tunable)
- Copy limits per rarity/type (e.g., max 2 Legendary)
- Faction or color identity rules if applicable
- Auto-validation with actionable error messages

### UX & Features
- Multi-deck support; name, duplicate, archive, favorite
- Search with smart tokens (e.g., type:unit rarity:epic text:"flying")
- Recommendations: suggest replacements to meet constraints or synergies
- Curve and composition analytics: mana curve, unit/spell ratios, keyword counts
- Side-by-side compare: current deck vs proposed edits
- Export/Import: share codes/links; server-verified on import

### Onboarding
- Starter decks per faction/region
- Guided deck-building tutorial and suggested goals

## World Map & Exploration

### Map Structure
- Overworld composed of regions/biomes; each region contains locations (nodes)
- Nodes: towns (shops/quests), wilds (encounters), dungeons (boss chains), landmarks (events)
- Movement: free travel between discovered nodes; optional energy/stamina for pacing (tunable)

### NPC Enemies & Encounters
- Each location has a pool of NPC opponents themed to the region’s mechanics
- Encounter tiers: Normal, Elite, Boss, Challenge
- Rewards:
  - First-clear: guaranteed card unlocks/blueprints
  - Repeat clears: chance-based drops, currency, crafting fragments
  - Region milestones: clear thresholds unlock region chest and cosmetics
- Difficulty scaling with player progress; optional modifiers (mutators) for extra rewards

### Region Progression & Unlocks
- Region-specific card tables; beating key NPCs unlocks entries in the table
- Reputation with regional factions unlocks vendors, discounts, and unique cosmetics
- Quest chains culminating in boss encounters that unlock signature cards
- Fast travel after clearing anchor nodes

### Events
- Rotating map events: mini-tournaments, time-limited bosses, puzzle nodes
- Event badges and exclusive cosmetic rewards

## PvP Matchmaking & Rankings

### Queues & Modes
- Casual: relaxed MMR, no rank change, good for testing decks
- Ranked: seasonal ladder with divisions and visible ranks
- Limited/Draft (future): curated pools or rotating formats
- Private Match: direct challenges/friends list

### Matchmaking
- Hidden MMR per mode; optional separate MMR per faction/format
- Search expands acceptable MMR delta over time to reduce queue times
- Region and latency-aware server selection
- Party and rematch constraints to prevent abuse; anti-boosting checks

### Rankings & Seasons
- Visible rank tiers (e.g., Bronze → Challenger) with 5 divisions each
- Placement matches to seed initial MMR
- Promotion/demotion rules with safeguards (promotion series optional)
- Decay for high tiers after inactivity; soft floors per season
- Seasonal resets with partial MMR carryover and reward tracks
- Leaderboards: global, regional, friends; filters by season and format

### Rewards & Fair Play
- Ranked chests at tier milestones and season end
- Leaver/AFK penalties: deserter timer, MMR loss, reduced rewards
- Anti-cheat/anti-exploit telemetry; server-side validation of actions

## Technical Notes & Integrations

- Persistent Profile: stores collection, decks, map progress, MMR, cosmetics
- Services:
  - Collection API: inventory, crafting, rewards claims
  - Deck API: CRUD, validation, share/import
  - Map API: node discovery state, encounter seeds, reward rolls
  - Matchmaking API: queue, cancel, match found, ticket handoff to game server
- Telemetry: match outcomes, deck usage, encounter win rates to balance tables
- A/B capabilities for drop rates, matchmaking windows, and reward tuning

## Open Questions

- Energy/stamina requirement for map movement: needed for pacing or optional?
- Ranked protection against frequent dodges at high tiers: dodge tax or lockout?
- Duplicate protection rules in ranked seasonal rewards
- Draft mode timing relative to core launch

