# AI Tactical Combat Direction

## Core Idea

Battles should feel like tactical encounters against enemies with doctrine, formations, morale, and plans.

The goal is not for every monster to be a genius. The goal is for enemies to behave as if they belong to a battlefield tradition:

- Soldiers use formation and discipline.
- Bandits use ambush, pressure, and escape routes.
- Beasts use pack behavior, fear, and territorial instincts.
- Cultic or infernal enemies use ritual patterns, sacrifice, and psychological pressure.
- Bosses use staged plans and adapt when the player disrupts them.

This lets enemy AI feel grounded in the world rather than like random RPG attack selection.

## Inspiration

Use military and strategic principles as design language, especially ideas associated with battlefield deception, terrain, concentration of force, timing, and morale.

This should be inspired by real tactics rather than quoting or simulating any one text literally.

## Tactical Layers

Enemy AI should eventually think in layers:

1. **Doctrine** - What kind of fighter is this group?
2. **Formation** - How do they arrange themselves before contact?
3. **Intent** - What are they trying to accomplish this turn?
4. **Target Priority** - Who do they want to pressure?
5. **Terrain Use** - How do they use cover, chokepoints, height, doors, counters, pews, alleys, or stalls?
6. **Morale** - When do they press, retreat, panic, regroup, or surrender?
7. **Adaptation** - How do they respond when their plan fails?

## Formation Examples

### Shield Line

Used by disciplined guards, militia, trained soldiers.

- Front units hold lanes and protect weaker allies.
- Rear units attack from safety.
- AI prefers chokepoints and narrow streets.
- Weakness: vulnerable to flanking, area attacks, or forced movement.

### Pincer

Used by bandits, hunters, trained ambushers.

- One group holds attention.
- Fast units circle around the side.
- AI prioritizes isolating a healer, archer, or low-defense character.
- Weakness: breaks if one side is defeated early.

### Kill Box

Used in alleys, shop ambushes, city gates, and prepared traps.

- Enemies lure or push the player into a central lane.
- Ranged units cover exits.
- Heavy units block retreat.
- Weakness: if the player refuses the bait or controls the blockers, the trap collapses.

### Pack Harass

Used by beasts, desperate mobs, or lightly armed enemies.

- Avoids direct full commitment.
- Circles wounded targets.
- Tests the player's formation.
- Retreats when morale drops.
- Weakness: disciplined player formation and overwatch-style abilities.

### Ritual Circle

Used by circle-of-Hell-influenced enemies.

- Units defend key ritual actors or positions.
- The formation has symbolic meaning tied to the city/circle.
- The player can disrupt the pattern by moving enemies, breaking lines, or occupying ritual cells.
- Weakness: rigid plan, vulnerable once pattern is broken.

## Planning Model

Each enemy group should have a plan object, not only individual unit decisions.

Example group plan:

- `plan_id`: `limbo_guard_delay`
- `doctrine`: `disciplined_delay`
- `formation`: `shield_line`
- `goal`: `hold_position`
- `preferred_terrain`: `chokepoint`
- `target_rule`: `block_player_advance`
- `morale_rule`: `retreat_when_leader_falls`
- `adaptation_rule`: `fallback_to_second_line`

This supports battles that feel authored but still dynamic.

## Monster And Enemy Sheet Implications

Monster and enemy data should eventually include:

- `doctrine`
- `formation_tags`
- `morale`
- `discipline`
- `aggression`
- `preferred_range`
- `terrain_preferences`
- `group_role`
- `commander_priority`
- `retreat_behavior`

Current stat sheets can stay simple for now. These fields should be added when combat scaffolding begins.

## Battle Map Implications

Because explorable rooms and streets can become battle maps, tactical AI depends on scene layout.

Battle-ready spaces should mark:

- Walkable cells.
- Chokepoints.
- Cover positions.
- High-value terrain.
- Spawn zones.
- Retreat routes.
- Flank lanes.
- Objective cells.

The same inn, shop, alley, or church can become more interesting when AI understands its terrain.

## Florence - Limbo Combat Flavor

Florence under Limbo should not fight like a fiery Hell zone.

Enemy tactics should express delay, indecision, repetition, memory loss, and civic stagnation.

Possible Limbo tactics:

- Enemies hold ground instead of charging.
- Guards form defensive lines and refuse to advance.
- Scholars or spirits repeat old patterns.
- Enemies delay the player with zones, barriers, and denial.
- Morale breaks slowly, as if they are not fully alive to danger.
- Some enemies may not attack until the player disrupts a memory, oath, or civic symbol.

The tactical feeling should be: beautiful order without purpose.

## Design Rule

AI tactics should create readable player choices:

- Break the line or flank it?
- Attack the commander or clear the front?
- Take the bait or force enemies to move?
- Hold formation or chase a wounded enemy?
- Disrupt the ritual or survive the damage?

If the player cannot understand what the enemy is trying to do, the AI is too opaque. Smart AI must still be readable.

