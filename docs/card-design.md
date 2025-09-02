# Kitbash CCG - Card Design Guide

## Purpose

This document defines the card design principles, color identities, and practical guidelines used to create clear, interesting, and balanced cards for Kitbash CCG. It complements `docs/game-design.md` by translating high-level rules into a consistent card design language.

## Design Principles

1. **Clarity before Cleverness**
   - Card text must be concise, unambiguous, and use established keywords.
   - Resolve intent at a glance: name, cost, type, and major effect should be instantly legible.

2. **Counterplay and Windows of Interaction**
   - Strong effects need timing windows, positional constraints, or resource gates.
   - Every proactive strategy should expose a predictable weakness (speed, range, fragility, setup time, or resource intensity).

3. **Tactical Board Expression**
   - Favor effects that leverage the grid (lanes, ranges, zones, tiles) and simultaneous resolution rules.
   - Prefer multi-turn lines (setup → payoff) over single-turn blowouts.

4. **Thematic Cohesion**
   - Each color’s mechanics should express its fantasy consistently (see Color Profiles).
   - Card names, VO, VFX/SFX, and visuals follow the color’s tone and mechanical identity.

5. **Costing and Power Budget**
   - Costs can include Mana, Gold, and board-position requirements.
   - When combining effects, allocate a power budget across stats (ATK/HP/RNG/SPD), keywords, and text effects. If a card violates a color’s weakness, increase cost or add a drawback.

6. **Rarity Maps to Complexity**
   - Common: single keyword or simple stat line; teaches color fundamentals.
   - Rare: 2–3 interacting elements; introduces combo potential.
   - Epic/Legendary: novel build-arounds or rule-benders with explicit guardrails.

7. **Sensible Variance**
   - Use controlled randomness (top X cards, choose among tiles in a lane, summon from a curated pool) to keep games fresh without undermining planning.

8. **Template and Keyword Discipline**
   - Reuse standard phrases; avoid bespoke wording when a keyword exists.
   - Keep triggered timing explicit: Start of Round, On Summon, On Move, On Death, End of Round.

9. **Onboarding First**
   - Early set cards reinforce core rules. Advanced interactions unlock in later sets or higher rarities.

---

## Color Profiles

Each color defines a strategic identity expressed through units, spells/tactics, and structures. Identities are designed to be complementary and support multi-color decks.

Structure per color:
- **Fantasy**: The narrative tone of the color.
- **Strategic Identity**: How the color tends to win.
- **Mechanical Themes**: Common keywords and effects.
- **Resource & Stat Tendencies**: Typical costs and stat profiles.
- **Constraints**: Intended weaknesses and tradeoffs.
- **Archetypes**: Example deck patterns.
- **Example Cards**: Flavorful samples to anchor the identity.

### Red

- **Fantasy**: Volatile ordnance and reckless vanguards.
- **Strategic Identity**: Pressure through burst damage, decisive lane breaks, and structure demolition.
- **Mechanical Themes**:
  - Glass cannon units with high ATK, low HP
  - Siege and building breakers (e.g., Siege X, Pierce X)
  - Charge, Knockback, temporary self-buffs, overheat-style drawbacks
  - Direct damage and burn over areas or lanes
- **Resource & Stat Tendencies**:
  - Lower Gold setup, moderate Mana spikes
  - Above-rate ATK, below-rate HP; average SPD; RNG 1–3
- **Constraints**:
  - Minimal sustain and poor long fights; vulnerable to slows and stuns
  - Limited cheap defensive tools; weak to swarms that survive initial burst
 - **Faction Guidelines**:
   - Fantasy Archetype: Orcs and Goblins
   - Vibes: Chaotic, scrappy, explosive
   - Mechanics: Main — Swarm; Shared — High damage, Orders
   - Pawn: Goblin

### Orange

- **Fantasy**: Siege engines, titans, and precision artillery.
- **Strategic Identity**: Methodical board control using big, slow units and long-range pressure.
- **Mechanical Themes**:
  - Big units with high cost and high staying power
  - Ranged units and artillery; Overwatch, Suppress, and Zone Control
  - Set-up payoffs: deploy shields, spotters, or calibrate for improved accuracy
- **Resource & Stat Tendencies**:
  - Higher Gold requirements; steady Mana curves
  - Above-rate HP and RNG; below-rate SPD
- **Constraints**:
  - Telegraphed plays susceptible to displacement or speed punish
  - Weak early skirmishers; can be outflanked without support
 - **Faction Guidelines**:
   - Fantasy Archetype: Dragons and Ogres
   - Vibes: Imposing, heavy, deliberate
   - Mechanics: Main — Elite units; Shared — Orders, Siege
   - Pawn: Dragon Whelp

### Yellow

- **Fantasy**: Fortifications, logistics, and unyielding defenders.
- **Strategic Identity**: Win through positional advantage, structure value, and attrition.
- **Mechanical Themes**:
  - Buildings/structures, repairs, and auras
  - Taunt, Armor X, Protector, and counterfire turrets
  - Economy tools: Gold generation, resource conversion, and stall
- **Resource & Stat Tendencies**:
  - Reliable Gold generation; conservative Mana curves
  - Tanky slow units with Armor; structures with defensive stats
- **Constraints**:
  - Limited burst damage and mobility; weak closing speed if behind
  - Vulnerable to true damage effects and siege focus
 - **Faction Guidelines**:
   - Fantasy Archetype: Dwarves
   - Vibes: Sturdy, methodical, stubborn
   - Mechanics: Main — Defense; Shared — Buildings, Siege
   - Pawn: Dwarf

### Green

- **Fantasy**: Bio-mechanics, growth, and self-repair.
- **Strategic Identity**: Outlast and overwhelm via regeneration and scaling buffs.
- **Mechanical Themes**:
  - Regenerate X, Heal/Repair, Grow at end of round
  - Ramp-style effects (convert Gold → Mana, or delayed payoffs)
  - Token sprouts that evolve over time
- **Resource & Stat Tendencies**:
  - Mid-range costs that spike later; prefers longer games
  - Balanced ATK/HP with regeneration access; moderate SPD
- **Constraints**:
  - Slow to start; vulnerable to burst and hard disables
  - Reliant on board presence to realize scaling
 - **Faction Guidelines**:
   - Fantasy Archetype: Elves and Nature Spirits
   - Vibes: Organic, patient, restorative
   - Mechanics: Main — Growth (gain power over time); Shared — Buildings, Healing
   - Pawn: Treant

### Blue

- **Fantasy**: Tactics, spellcraft, and battlefield manipulation.
- **Strategic Identity**: Low unit counts with high spell density; control the pace and position of combat.
- **Mechanical Themes**:
  - Spells/Tactics, card draw (Draw X), stuns, roots, teleports
  - Summoned constructs or illusions with utility over raw stats
  - Priority and timing manipulation within simultaneous resolution guardrails
- **Resource & Stat Tendencies**:
  - Mana-centric costs; leans on ephemeral resource spikes
  - Understated units; overperforming spells
- **Constraints**:
  - Lacks sustained damage and sturdy frontlines without pairing
  - Vulnerable once out of cards; must manage hand size and timing
 - **Faction Guidelines**:
   - Fantasy Archetype: Knights and Humans
   - Vibes: Disciplined, tactical, honorable
   - Mechanics: Main — Combined arms; Shared — Spells, Healing
   - Pawn: Human Soldier

### Purple

- **Fantasy**: Dark conjury, swarms, and disposable power.
- **Strategic Identity**: Overwhelm with summoned units and relentless attrition at the cost of fragility.
- **Mechanical Themes**:
  - High unit counts, token generation, and On-Death triggers
  - Sacrifice outlets, Lifesteal X, and glass-cannon payoffs
  - Summoned units entering beyond base under certain restrictions
- **Resource & Stat Tendencies**:
  - Many cheap plays; spikes when multiple deaths convert to value
  - Low HP profiles; occasional burst windows via buffs
- **Constraints**:
  - Vulnerable to sweepers and area denial
  - Struggles against heavy Armor without support
 - **Faction Guidelines**:
   - Fantasy Archetype: Undead and Wizards
   - Vibes: Grim, relentless, sacrificial
   - Mechanics: Main — Summons; Shared — Spells, High damage
   - Pawn: Ghoul

---

## Pawns (First Iteration)

- Red — Goblin
  - Stats: 2/2/1, SPD 1
  - Keywords: Armor 0

- Orange — Dragon Whelp
  - Stats: 2/1/1, SPD 1
  - Keywords: Armor 0, Flying

- Yellow — Dwarf
  - Stats: 1/2/1, SPD 1
  - Keywords: Armor 1

- Green — Treant
  - Stats: 1/2/1, SPD 1
  - Keywords: Armor 0, Regenerate 1

- Blue — Human Soldier
  - Stats: 2/3/1, SPD 1
  - Keywords: Armor 0

- Purple — Ghoul
  - Stats: 1/2/1, SPD 1
  - Keywords: Armor 0, Rekindle

## Cross-Color Synergies

- **Red + Yellow**: Fast demolition backed by durable structures. Win by opening a breach then protecting it with walls or turrets.
- **Red + Blue**: Burst windows created by displacement and stuns; set up lethal volleys with precise timing.
- **Orange + Yellow**: Entomb lanes with armor and overwatch while artillery grinds opponents down.
- **Orange + Blue**: Spotters, accuracy, and control combine for surgical strikes at long range.
- **Green + Purple**: Tokens that return or grow; sacrifice loops that keep the board sticky.
- **Green + Yellow**: Repair engines and long-game resource advantages.

---

## Templating Guidelines

- **Costs**: "Cost: X Mana Y Gold" or inline as "[X Mana, Y Gold]". If only one resource, omit the other.
- **Stats**: Units list "ATK/HP/RNG [optional], SPD [optional]" in that order.
- **Timing**: Use exact triggers — "Start of Round", "On Summon", "On Move", "On Death", "End of Round".
- **Placement**: Explicitly reference tiles, lanes, columns, or zones; avoid ambiguous terms.
- **Summon Rules**: If a summon may break base rules, include its exception text (e.g., "may be placed in Neutral Zone").

---

## Visual Language (Non-binding but Recommended)

- **Red**: Angular silhouettes, glowing vents, brief intense VFX; percussive hits.
- **Orange**: Heavy frames, stabilizers, muzzle flashes; mechanical hums and artillery thumps.
- **Yellow**: Geometric shields, hazard striping, beam turrets; resonant shield impacts.
- **Green**: Organic overlays, vines and bio-lights; soft regenerative chimes.
- **Blue**: Clean lines, holograms, refraction; airy spell sizzles.
- **Purple**: Wisps, shadow motes, spectral chains; whispery summons and brittle shatters.

---

## Checklist for New Cards

1. Does the color identity and constraint hold?
2. Is the power budget fair across stats, keywords, and text?
3. Is the timing unambiguous and compatible with simultaneous resolution?
4. Is there clear counterplay (positioning, timing, resource, or removal)?
5. Is the name/theme aligned with the color’s fantasy and visuals?

