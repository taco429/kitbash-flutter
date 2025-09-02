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

 - **Fantasy**: Orcs and Goblins warbands; reckless raiders and ingenious tinkerers.
 - **Strategic Identity**: Overwhelm with swarms that hit hard; chain decisive strikes using Orders.
 - **Mechanical Themes**:
   - Swarm, token generation, extra deploys, and cheap bodies
   - Orders that coordinate movement and attacks (e.g., Rally, Charge)
   - High damage bursts, on-attack triggers, temporary self-buffs
 - **Resource & Stat Tendencies**:
   - Low Gold costs enabling multiple plays per round
   - Above-rate ATK, below-rate HP; mostly melee (RNG 1); average-to-high SPD
 - **Constraints**:
   - Fragile to area damage, roots, and stuns
   - Reliant on sequencing; loses pressure if Orders are disrupted
 - **Faction Guidelines**:
   - Fantasy Archetype: Orcs and Goblins
   - Vibes: Chaotic, scrappy, explosive
   - Mechanics: Main — Swarm; Shared — High damage, Orders
   - Pawn: Goblin

### Orange

 - **Fantasy**: Dragons and Ogres; towering elites and siege-minded brutes.
 - **Strategic Identity**: Win through elite units that dominate lanes; use Orders and Siege to crack defenses.
 - **Mechanical Themes**:
   - Elite, high-cost units with staying power and impactful attacks
   - Orders for formation play and focused fire
   - Siege and structure pressure; suppression and zone control when set up
 - **Resource & Stat Tendencies**:
   - High Gold/Mana costs; low deployment frequency, high impact
   - Above-rate HP/ATK; below-rate SPD; select units with extended RNG
 - **Constraints**:
   - Telegraphed development, vulnerable to displacement or being outflanked
   - Limited early swarming; needs support to cover multiple lanes
 - **Faction Guidelines**:
   - Fantasy Archetype: Dragons and Ogres
   - Vibes: Imposing, heavy, deliberate
   - Mechanics: Main — Elite units; Shared — Orders, Siege
   - Pawn: Dragon Whelp

### Yellow

 - **Fantasy**: Dwarves; master builders and stalwart guardians.
 - **Strategic Identity**: Fortify and grind; win by holding ground with defenses and structures.
 - **Mechanical Themes**:
   - Buildings/structures, repairs, auras, and protective formations
   - Armor X, Taunt, Protector; siege support from emplacements
 - **Resource & Stat Tendencies**:
   - Reliable Gold economy; conservative Mana curve
   - High Armor/HP; low SPD; structures with defensive statlines
 - **Constraints**:
   - Limited burst damage and mobility; slow to close out without siege
   - Vulnerable to true damage and displacement that bypasses walls
 - **Faction Guidelines**:
   - Fantasy Archetype: Dwarves
   - Vibes: Sturdy, methodical, stubborn
   - Mechanics: Main — Defense; Shared — Buildings, Siege
   - Pawn: Dwarf

### Green

 - **Fantasy**: Elves and Nature Spirits; patient stewards of living power.
 - **Strategic Identity**: Grow stronger over time; sustain and scale into inevitability.
 - **Mechanical Themes**:
   - Regenerate X, Heal, end-of-round growth buffs
   - Tokens that sprout and evolve; structures that accelerate growth
 - **Resource & Stat Tendencies**:
   - Mid-range costs with later spikes; prefers longer games
   - Balanced ATK/HP with access to sustain; moderate SPD
 - **Constraints**:
   - Slow early turns; weak to burst removal and hard disables
   - Needs board presence/time to realize scaling
 - **Faction Guidelines**:
   - Fantasy Archetype: Elves and Nature Spirits
   - Vibes: Organic, patient, restorative
   - Mechanics: Main — Growth (gain power over time); Shared — Buildings, Healing
   - Pawn: Treant

### Blue

 - **Fantasy**: Knights and Humans; disciplined commanders and versatile troops.
 - **Strategic Identity**: Combined arms; coordinate units with potent spells and battlefield medicine.
 - **Mechanical Themes**:
   - Spells/Tactics, control tools (stuns, roots, reposition), shields
   - Healing and support to keep lines intact; synergy between roles
 - **Resource & Stat Tendencies**:
   - Mana-centric costs; flexible curves via tactics
   - Balanced but slightly understated units offset by spell quality
 - **Constraints**:
   - Requires coordination and hand resources; vulnerable when card-poor
   - Limited raw burst without setup or combined lines
 - **Faction Guidelines**:
   - Fantasy Archetype: Knights and Humans
   - Vibes: Disciplined, tactical, honorable
   - Mechanics: Main — Combined arms; Shared — Spells, Healing
   - Pawn: Human Soldier

### Purple

 - **Fantasy**: Undead and Wizards; necromancy, curses, and ruthless power.
 - **Strategic Identity**: Flood the board with summons; leverage spells for high-damage windows.
 - **Mechanical Themes**:
   - Token/summon generation, On-Death triggers, and sacrifice outlets
   - Spells that amplify damage, drain, or recur threats
 - **Resource & Stat Tendencies**:
   - Many cheap plays and rituals; spikes when deaths convert to value
   - Low HP profiles; glass cannons with burst potential
 - **Constraints**:
   - Vulnerable to exile effects, sweepers, and area denial
   - Struggles into heavy Armor without specific answers
 - **Faction Guidelines**:
   - Fantasy Archetype: Undead and Wizards
   - Vibes: Grim, relentless, sacrificial
   - Mechanics: Main — Summons; Shared — Spells, High damage
   - Pawn: Ghoul

---

## Pawns (First Iteration)

- Red — Goblin
  - ATK: 2
  - HP: 2
  - Range (RNG): 1
  - Movement (SPD): 1
  - Keywords: Armor 0, Melee

- Orange — Dragon Whelp
  - ATK: 2
  - HP: 1
  - Range (RNG): 1
  - Movement (SPD): 1
  - Keywords: Armor 0, Flying

- Yellow — Dwarf
  - ATK: 1
  - HP: 2
  - Range (RNG): 1
  - Movement (SPD): 1
  - Keywords: Armor 1, Melee

- Green — Treant
  - ATK: 1
  - HP: 2
  - Range (RNG): 1
  - Movement (SPD): 1
  - Keywords: Armor 0, Regenerate 1, Melee

- Blue — Human Soldier
  - ATK: 2
  - HP: 3
  - Range (RNG): 1
  - Movement (SPD): 1
  - Keywords: Armor 0, Melee

- Purple — Ghoul
  - ATK: 1
  - HP: 2
  - Range (RNG): 1
  - Movement (SPD): 1
  - Keywords: Armor 0, Rekindle, Melee

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

