# Skill Data System Design
_2026-06-25_

## Overview

Replace hardcoded per-skill functions in `battle_test_map.gd` with a data-driven `SkillData` resource class. Each skill is authored as a `.tres` file. A single `_execute_skill()` method in the battle map handles all skill execution by reading from the resource.

---

## SkillData Resource (`scripts/data/skill_data.gd`)

`extends Resource`, `class_name SkillData`.

### Identity
| Field | Type | Notes |
|---|---|---|
| `skill_id` | `String` | Unique key, matches file name |
| `display_name` | `String` | Shown in UI |
| `skill_type` | `enum` | `SPELL / ABILITY / PASSIVE` |
| `tier` | `enum` | `I / II / III / IV` |
| `grimoire_source` | `String` | Spell name as it appears in the PDF |
| `flavor_text` | `String` | Tooltip/lore text |

### Cost
| Field | Type | Notes |
|---|---|---|
| `mp_cost` | `int` | Deducted on cast |
| `corruption_cost` | `float` | Added to `CombatActor.current_corruption` (0.0–1.0 scale) |

### Timing & Range
| Field | Type | Notes |
|---|---|---|
| `casting_time` | `enum` | `INSTANT / ONE_ROUND / TWO_ROUNDS` |
| `range_cells` | `int` | 0 = self or melee |
| `area` | `enum` | `SINGLE / CONE / RADIUS / LINE / SELF` |

### Targeting
| Field | Type | Notes |
|---|---|---|
| `target` | `enum` | `SINGLE_ENEMY / SINGLE_ALLY / SELF / AOE` |
| `stat_check` | `enum` | See stat check table below |

**Stat check enum:**
```
NO_ROLL      # utility, buffs, self-cast — always succeeds
AUTO_HIT     # unavoidable damage or effect — no defense possible
INT_VS_POW   # magic vs mental resistance — spells, mind effects
STR_VS_DEF   # physical force vs armor — melee abilities
FTH_VS_POW   # divine/folk magic vs willpower — church spells, curses
SPD_VS_SPD   # contested speed — interrupts, steal turn, reactions
```

### Effect
| Field | Type | Notes |
|---|---|---|
| `primary_effect_description` | `String` | Human-readable, for tooltip |
| `duration_turns` | `int` | 0 = instant |
| `status_applied` | `String` | effect_id string passed to `apply_status_effect()`; `""` = none |

### Formula (enum-based, no eval)
| Field | Type | Notes |
|---|---|---|
| `damage_formula` | `enum` | `NONE / FLAT / PERCENT_MAX_HP / CASTER_POW` |
| `damage_value` | `float` | Flat amount or multiplier depending on formula |
| `healing_formula` | `enum` | `NONE / FLAT / PERCENT_MAX_HP / CASTER_POW` |
| `healing_value` | `float` | Flat amount or multiplier depending on formula |

### Stat Modifier
| Field | Type | Notes |
|---|---|---|
| `stat_modifier_stat` | `String` | Stat code e.g. `"DEF"`, `"SPD"`; `""` = none |
| `stat_modifier_amount` | `int` | Positive or negative |
| `stat_modifier_duration` | `int` | Turns the modifier lasts |

### Absorption & Tags
| Field | Type | Notes |
|---|---|---|
| `absorption_tier` | `enum` | `NORMAL / UNCOMMON / RARE` |
| `tags` | `Array[String]` | e.g. `["fire", "aoe", "divine"]` |

---

## Execution Flow (`battle_test_map.gd`)

Single method replaces all hardcoded `_use_skill_*` functions:

```gdscript
func _execute_skill(skill: SkillData, caster: CombatActor, target: CombatActor) -> void
```

Steps in order:
1. **MP check** — if `caster.current_mp < skill.mp_cost`: print insufficient MP, return to action menu. No cost deducted.
2. **Stat check** — if not `NO_ROLL` or `AUTO_HIT`: roll the appropriate check. On failure: deduct MP, log miss, end turn.
3. **Deduct MP** — `caster.current_mp -= skill.mp_cost`
4. **Add corruption** — `caster.current_corruption += skill.corruption_cost`
5. **Apply damage** — match `damage_formula`, compute amount, call `target.apply_damage()`
6. **Apply healing** — match `healing_formula`, compute amount, call `target.heal()`
7. **Apply status** — if `skill.status_applied != ""`: call `target.apply_status_effect()` with `duration_turns` and stat modifier fields
8. **Log action** — build `_last_action_text` from skill name, caster, target, and effect numbers
9. **End turn** — advance CT, call `turn_controller.finish_act()`, `_finish_player_turn()`

`_on_skill_selected()` changes from a `match skill_name` string switch to: find `SkillData` in `player_actor.sheet_resource.abilities` by `skill_id`, then route to targeting phase or call `_execute_skill()` directly based on `skill.target`.

---

## CombatActor Changes (`scripts/combat/combat_actor.gd`)

Add one field:
```gdscript
var current_corruption: float = 0.0
```

---

## CharacterSheet Changes (`scripts/data/character_sheet.gd`)

```gdscript
# Before
@export var abilities: Array[String] = []

# After
@export var abilities: Array[Resource] = []
```

Monster sheets (`starved_wolf.tres`, `training_brigand.tres`) keep `Array[String]` for now — their abilities are not player-executable yet.

---

## Files

### New
- `scripts/data/skill_data.gd`
- `data/skills/guts.tres`
- `data/skills/protezione.tres`
- `data/skills/guarigione.tres`

### Modified
- `scripts/data/character_sheet.gd` — abilities field type
- `scripts/combat/combat_actor.gd` — add `current_corruption`
- `scripts/combat/battle_test_map.gd` — replace hardcoded skill functions
- `data/characters/guglielmo_da_siena.tres` — update abilities to resource references

---

## Out of Scope (future passes)
- Corruption thresholds and manifestations
- Enemy AI using SkillData
- AOE targeting resolution
- Skill trees / unlock system
- Monster sheet migration to SkillData
