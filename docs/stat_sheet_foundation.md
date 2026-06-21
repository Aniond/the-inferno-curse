# Stat Sheet Foundation

## Core Attributes

- STR - Strength: physical force, melee scaling, carrying weight, body checks.
- SPD - Speed: turn timing, movement, evasion, quick reactions.
- INT - Intellect: tactics, study, technical knowledge, arcane reasoning.
- FTH - Faith: miracles, vows, morale, spiritual resistance.
- CRT - Creativity: invention, improvisation, crafting, unusual techniques.
- PRS - Presence: leadership, intimidation, charm, command, resolve.

## Derived Battle Stats

- POW - Power: calculated offensive force.
- DEF - Defense: calculated mitigation and staying power.
- MOV - Movement: tactical grid movement range.
- JMP - Jump: vertical movement and ledge traversal range.
- C-EV - Character evasion: defensive avoidance percentage.
- CRT - Critical rate: chance to trigger critical outcomes.

POW and DEF are not authored as core identity stats. They are derived from level, core attributes, and equipment or natural monster bonuses. MOV, JMP, C-EV, and CRT are currently authored on the character sheet so battle testing can tune them directly before the combat engine owns final formulas.

Current formulas:

```text
effective stat = base stat + active modifiers
POW = level + effective primary stat + floor((effective PRS + effective CRT) * 0.25) + active POW modifiers
DEF = level + floor((effective STR + effective SPD + effective PRS) / 3) + active DEF modifiers
```

## Modifier System

Character stats start from simple flat authored values. A value of 5 is the normal baseline for early characters and tuning passes.

`res://scripts/data/stat_modifier.gd` is the shared modifier resource for level growth, equipment, buffs, passives, weather effects, and temporary object effects. Each modifier has:

- `source_id`
- `source_name`
- `target_stat`
- `flat_bonus`
- `per_level_bonus`
- `is_active`

The character sheet sums active modifiers when calculating effective values. Level growth is modeled as a modifier with a `per_level_bonus`, while equipment and objects usually use `flat_bonus`.

Current sample:

- `Training Sword` adds `POW +4`.
- `Basic Squire Kit` adds `DEF +5`.
- `Squire Level Growth` adds HP/MP and slow STR growth as level increases.

## Current Data Resources

- `res://scripts/data/core_stats.gd`
- `res://scripts/data/stat_modifier.gd`
- `res://scripts/data/character_sheet.gd`
- `res://scripts/data/npc_sheet.gd`
- `res://scripts/data/monster_sheet.gd`
- `res://data/characters/guglielmo_da_siena.tres`
- `res://data/npcs/matteo_the_baker.tres`
- `res://data/monsters/training_brigand.tres`

These sheets are combat-readable but do not depend on the combat engine yet.

The current playable test sheet is `res://data/characters/guglielmo_da_siena.tres`. It owns the authored values. Runtime UI reads those values through the `PlayerData` autoload, which acts as the mutable bridge for current HP, MP, CT, experience, and future battle state.

## UI Templates

- Character sheet active template: `res://assets/images/edited-parchment-rpg-interface.png`
- Monster/enemy sheet visual target: `res://assets/ui/monster_sheet_template.png`

The monster template is the clean tactical multi-column sheet: unit profile, combat stats, resistances, abilities, passive/active skills, and loadout grid. Use it as the target when building the monster/enemy sheet UI.
