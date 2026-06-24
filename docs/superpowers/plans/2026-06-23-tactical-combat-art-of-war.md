# Tactical Combat & Art of War Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use summer:subagent-driven-development (recommended) or summer:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship full positional tactical combat (8-way facing, directional cover, height-cost movement) with INT-gated `TacticalMind` enemy AI on the existing `scripts/combat/` stack.

**Architecture:** Extend `CombatGrid`/`CombatActor`/`CombatState` in place. Add focused new types (`CoverVolume`, `TacticalMind`, `CombatInfluenceMaps`, `TacticalProfile`) as separate GDScript files. Player/enemy turns share the same move → rotate → act pipeline. AI reads the same grid data as the player overlay (fairness). Phases P1–P8 each produce a playable encounter in `battle_test_map`.

**Tech Stack:** Godot 4.6, GDScript, existing `MonsterSheet`/`CoreStats`, Summer Engine MCP for playtesting.

**Spec:** `docs/superpowers/specs/2026-06-23-tactical-combat-art-of-war-design.md`

---

## File Map (created / modified)

| File | Responsibility |
|------|----------------|
| `scripts/combat/tactical_facing.gd` | 8-way enum, vectors, angle math, arc classification |
| `scripts/combat/combat_actor.gd` | 8-way facing; rotate API; jump-cost modifiers hook |
| `scripts/combat/combat_grid.gd` | Angle-based flank/pincer; cover ray hooks; influence map host |
| `scripts/combat/combat_state.gd` | Turn phases; path cost with height; rotate phase; AI dispatch |
| `scripts/combat/cover_volume.gd` | Directional cover node extending `CombatTerrain` |
| `scripts/combat/combat_influence_maps.gd` | Threat/cover/choke/retreat scalar fields |
| `scripts/combat/tactical_mind.gd` | INT tiers, belief, plan scoring |
| `scripts/combat/tactical_plan.gd` | Authored plan definitions + utility scoring |
| `scripts/combat/group_battle_plan.gd` | Commander group plan + role assignments |
| `scripts/combat/tactical_profile.gd` | Ability pattern resource |
| `scripts/combat/combat_turn_controller.gd` | Shared move/rotate/act state machine |
| `scripts/combat/battle_test_map.gd` | Player rotate UI; phase hints; test cover volumes |
| `scripts/combat/battle_overlay.gd` | Cover/flank/height preview UI |
| `scripts/data/monster_sheet.gd` | Doctrine, formation, group_role, morale fields |
| `data/monsters/training_brigand.tres` | Sample doctrine + INT for AI tests |
| `docs/turn_based_battle_system.md` | Update to match shipped behavior |

**Verification:** No GUT suite yet. Each phase ends with `summer_play` + scripted checks in `battle_test_map` and `print` assertions callable from a debug key.

---

## Phase P1 — 8-way facing, rotate, angle flank arcs

### Task 1: `TacticalFacing` utility

**Files:**
- Create: `scripts/combat/tactical_facing.gd`
- Modify: `scripts/combat/combat_actor.gd`
- Modify: `scripts/combat/combat_grid.gd`

- [ ] **Step 1: Create `tactical_facing.gd`**

```gdscript
extends RefCounted
class_name TacticalFacing

enum Direction {
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST,
}

const DIRECTION_VECTORS := {
	Direction.NORTH: Vector2i(0, -1),
	Direction.NORTH_EAST: Vector2i(1, -1),
	Direction.EAST: Vector2i(1, 0),
	Direction.SOUTH_EAST: Vector2i(1, 1),
	Direction.SOUTH: Vector2i(0, 1),
	Direction.SOUTH_WEST: Vector2i(-1, 1),
	Direction.WEST: Vector2i(-1, 0),
	Direction.NORTH_WEST: Vector2i(-1, -1),
}

const VISUAL_NAMES := [
	"north", "north_east", "east", "south_east",
	"south", "south_west", "west", "north_west",
]

static func direction_from_visual(name: String) -> int:
	return VISUAL_NAMES.find(name)

static func visual_from_direction(direction: int) -> String:
	if direction < 0 or direction >= VISUAL_NAMES.size():
		return "south"
	return VISUAL_NAMES[direction]

static func vector_from_direction(direction: int) -> Vector2i:
	return DIRECTION_VECTORS.get(direction, Vector2i(0, 1))

static func direction_from_vector(delta: Vector2i) -> int:
	if delta == Vector2i.ZERO:
		return Direction.SOUTH
	var best_dir := Direction.SOUTH
	var best_dot := -999.0
	for direction in DIRECTION_VECTORS.keys():
		var basis: Vector2i = DIRECTION_VECTORS[direction]
		var dot := float(basis.x * delta.x + basis.y * delta.y)
		if dot > best_dot:
			best_dot = dot
			best_dir = direction
	return best_dir

static func angle_degrees(direction: int) -> float:
	# 0° = east, counter-clockwise
	match direction:
		Direction.EAST: return 0.0
		Direction.NORTH_EAST: return 45.0
		Direction.NORTH: return 90.0
		Direction.NORTH_WEST: return 135.0
		Direction.WEST: return 180.0
		Direction.SOUTH_WEST: return 225.0
		Direction.SOUTH: return 270.0
		Direction.SOUTH_EAST: return 315.0
	return 270.0

enum AttackArc { FRONT, RIGHT_FLANK, BACK, LEFT_FLANK }

static func classify_attack_arc(defender_facing: int, attack_delta: Vector2i) -> int:
	var attack_dir := direction_from_vector(attack_delta)
	var defender_angle := angle_degrees(defender_facing)
	var attack_angle := angle_degrees(attack_dir)
	var diff := fposmod(attack_angle - defender_angle + 180.0, 360.0) - 180.0
	if abs(diff) <= 45.0:
		return AttackArc.FRONT
	if diff > 45.0 and diff <= 135.0:
		return AttackArc.RIGHT_FLANK
	if diff < -45.0 and diff >= -135.0:
		return AttackArc.LEFT_FLANK
	return AttackArc.BACK
```

- [ ] **Step 2: Refactor `CombatActor` to use `TacticalFacing`**

Replace 4-way `TacticalFacing` enum and collapse maps with:

```gdscript
func get_tactical_facing() -> int:
	return TacticalFacing.direction_from_visual(visual_facing)

func get_facing_vector() -> Vector2i:
	return TacticalFacing.vector_from_direction(get_tactical_facing())

func set_tactical_facing(direction: int) -> void:
	visual_facing = TacticalFacing.visual_from_direction(direction)

func rotate_to_direction(direction: int) -> void:
	set_tactical_facing(direction)
```

- [ ] **Step 3: Update `CombatGrid.get_attack_arc` and `get_flank_bonus`**

```gdscript
func get_attack_arc(attacker: CombatActor, target: CombatActor) -> int:
	if attacker == null or target == null:
		return TacticalFacing.AttackArc.FRONT
	var delta := attacker.get_grid_position() - target.get_grid_position()
	return TacticalFacing.classify_attack_arc(target.get_tactical_facing(), delta)

func get_flank_bonus(attacker: Node, target: Node) -> int:
	if not (attacker is CombatActor and target is CombatActor):
		return 0
	var arc := get_attack_arc(attacker as CombatActor, target as CombatActor)
	match arc:
		TacticalFacing.AttackArc.BACK: return 20
		TacticalFacing.AttackArc.RIGHT_FLANK, TacticalFacing.AttackArc.LEFT_FLANK: return 10
		_: return 0
```

Update `get_pincer_bonus` to use opposite arc (BACK vs FRONT, flanks opposite flanks) instead of cardinal `_axis_direction`.

- [ ] **Step 4: Playtest P1 flank**

Run game, start brigand fight. Move player to NE of enemy facing north; attack should log damage with +20 flank (back arc). Diagonal backstab scenario from spec test #1.

- [ ] **Step 5: Commit**

```bash
git add scripts/combat/tactical_facing.gd scripts/combat/combat_actor.gd scripts/combat/combat_grid.gd
git commit -m "feat(combat): 8-way facing and angle-based flank arcs"
```

---

### Task 2: Turn phases — move, rotate, act

**Files:**
- Create: `scripts/combat/combat_turn_controller.gd`
- Modify: `scripts/combat/combat_state.gd`
- Modify: `scripts/combat/battle_test_map.gd`

- [ ] **Step 1: Create `combat_turn_controller.gd`**

```gdscript
extends RefCounted
class_name CombatTurnController

enum Phase { MOVE, ROTATE, ACT, DONE }

var phase: int = Phase.MOVE
var has_moved: bool = false
var has_rotated: bool = false
var has_acted: bool = false

func reset() -> void:
	phase = Phase.MOVE
	has_moved = false
	has_rotated = false
	has_acted = false

func can_move() -> bool:
	return phase == Phase.MOVE and not has_moved

func can_rotate() -> bool:
	return (phase == Phase.MOVE or phase == Phase.ROTATE) and not has_acted

func can_act() -> bool:
	return not has_acted

func skip_move() -> void:
	if phase == Phase.MOVE:
		phase = Phase.ROTATE

func finish_move() -> void:
	has_moved = true
	phase = Phase.ROTATE

func finish_rotate() -> void:
	has_rotated = true
	phase = Phase.ACT

func skip_rotate() -> void:
	if phase == Phase.ROTATE:
		phase = Phase.ACT

func finish_act() -> void:
	has_acted = true
	phase = Phase.DONE
```

- [ ] **Step 2: Wire controller into `CombatState`**

Add `var turn_controller: CombatTurnController` per active actor turn. Reset on `actor_turn_started`. Gate `end_actor_turn` on `Phase.DONE`.

- [ ] **Step 3: Player rotate in `battle_test_map.gd`**

Add `PlayerTurnPhase.ROTATE` between MOVE and ATTACK. Bind keys: `Q`/`E` or right-click drag to cycle facing. Show facing wedge mesh on player cell. Enter confirms rotate skip.

- [ ] **Step 4: Playtest rotate-then-backstab**

Skip move, rotate to face away from brigand, let brigand move adjacent behind, next turn attack for back bonus.

- [ ] **Step 5: Commit**

```bash
git add scripts/combat/combat_turn_controller.gd scripts/combat/combat_state.gd scripts/combat/battle_test_map.gd
git commit -m "feat(combat): move-rotate-act turn phases with player rotate"
```

---

## Phase P2 — `CoverVolume` directional cover

### Task 3: Cover volume node

**Files:**
- Create: `scripts/combat/cover_volume.gd`
- Modify: `scripts/combat/combat_grid.gd`
- Modify: `scripts/combat/combat_state.gd`
- Modify: `scripts/combat/battle_test_map.gd`

- [ ] **Step 1: Create `cover_volume.gd`**

```gdscript
extends CombatTerrain
class_name CoverVolume

@export_enum("north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west") var cover_facing: String = "south"
@export_range(90, 360) var coverage_arc: float = 180.0
@export var grid_position: Vector2i = Vector2i.ZERO

func get_cover_direction() -> int:
	return TacticalFacing.direction_from_visual(cover_facing)

func protects_against_attack(from_cell: CombatCell, to_cell: CombatCell) -> bool:
	if from_cell == null or to_cell == null:
		return false
	var incoming := from_cell.grid_position - grid_position
	var attack_dir := TacticalFacing.direction_from_vector(incoming)
	var diff := absf(
		fposmod(TacticalFacing.angle_degrees(attack_dir) - TacticalFacing.angle_degrees(get_cover_direction()) + 180.0, 360.0) - 180.0
	)
	return diff <= coverage_arc * 0.5

func get_cover_bonus() -> int:
	match cover_level:
		1: return 12
		2: return 26
		_: return 0
```

- [ ] **Step 2: Register volumes on grid**

`CombatGrid` holds `var cover_volumes: Array[CoverVolume]`. `register_cover_volume(vol)` on encounter start from scene children.

- [ ] **Step 3: Replace `get_directional_cover_modifier`**

Iterate `cover_volumes` between attacker/defender; apply strongest bonus only when `protects_against_attack` is true. Keep cell-level cover as fallback on defender cell.

- [ ] **Step 4: Place test barrel in `battle_test_map`**

Spawn `CoverVolume` at `(5, 8)` facing `south`. Ranged attack from north gets half cover; from south does not.

- [ ] **Step 5: Playtest + commit**

```bash
git add scripts/combat/cover_volume.gd scripts/combat/combat_grid.gd scripts/combat/battle_test_map.gd
git commit -m "feat(combat): directional CoverVolume cover"
```

---

## Phase P3 — Jump movement costs

### Task 4: Height-cost pathfinding

**Files:**
- Modify: `scripts/combat/combat_state.gd`
- Modify: `scripts/combat/combat_actor.gd`

- [ ] **Step 1: Add jump cost helpers on `CombatActor`**

```gdscript
var jump_cost_reduction: int = 0
var jump_cost_multiplier: float = 1.0
var ignore_first_height_level: bool = false
var downhill_free: bool = false

func get_height_step_cost(from_level: int, to_level: int) -> int:
	var delta := to_level - from_level
	if delta == 0:
		return 0
	var magnitude := absi(delta)
	if ignore_first_height_level and magnitude > 0:
		magnitude = maxi(0, magnitude - 1)
	if delta < 0 and downhill_free:
		return 0
	var per_level := 2 if delta > 0 else 1
	var raw := magnitude * per_level
	raw = int(ceil(float(raw) * jump_cost_multiplier))
	return maxi(0, raw - jump_cost_reduction)
```

- [ ] **Step 2: Update `get_reachable_cells` step cost**

```gdscript
var height_cost := actor.get_height_step_cost(
	cell.get_effective_height_level(),
	neighbor.get_effective_height_level()
)
var step_cost: int = max(neighbor.movement_cost, (2 if is_diagonal else 1) + height_cost)
```

- [ ] **Step 3: Playtest raised floor at `(4,4)`**

Confirm diagonal climb costs 4 MOV from adjacent lower cell.

- [ ] **Step 4: Commit**

```bash
git add scripts/combat/combat_actor.gd scripts/combat/combat_state.gd
git commit -m "feat(combat): height-based movement costs"
```

---

## Phase P4 — Battle overlay UI

### Task 5: `BattleOverlay`

**Files:**
- Create: `scripts/combat/battle_overlay.gd`
- Modify: `scripts/combat/battle_test_map.gd`

- [ ] **Step 1: Create overlay node** — draws flank arc wedges, cover label on hover, height chip using `CombatGrid` queries.

- [ ] **Step 2: Hook mouse hover** during ATTACK phase to show `"Half cover — south approach"` string from `get_directional_cover_modifier` breakdown.

- [ ] **Step 3: Playtest** — all three overlays visible on hover.

- [ ] **Step 4: Commit**

```bash
git add scripts/combat/battle_overlay.gd scripts/combat/battle_test_map.gd
git commit -m "feat(combat): tactical battle overlay UI"
```

---

## Phase P5 — `TacticalMind` tiers 1–3

### Task 6: Tactical mind core

**Files:**
- Create: `scripts/combat/tactical_mind.gd`
- Create: `scripts/combat/tactical_plan.gd`
- Modify: `scripts/combat/combat_actor.gd`
- Modify: `scripts/combat/combat_state.gd`
- Modify: `scripts/data/monster_sheet.gd`
- Modify: `data/monsters/training_brigand.tres`

- [ ] **Step 1: `TacticalMind` tier from INT**

```gdscript
extends RefCounted
class_name TacticalMind

var intellect: int = 5
var mind_tier: int = 1
var belief_last_seen: Vector2i = Vector2i(-1, -1)

func _init(int_value: int) -> void:
	intellect = int_value
	mind_tier = maxi(1, inti(float(intellect) / 3.0))

func update_belief(player_cell: Vector2i, had_los: bool) -> void:
	if had_los:
		belief_last_seen = player_cell
```

- [ ] **Step 2: `TacticalPlan` resources** — `shield_wall`, `direct_attack` with `score(actor, state, mind) -> float`.

- [ ] **Step 3: Replace `_resolve_enemy_turn`** — tier 1: nearest attack; tier 2: move to nearest half-cover cell then attack; tier 3: execute `shield_wall` (hold cover facing player).

- [ ] **Step 4: Add `doctrine` + `group_role` to `MonsterSheet`**; set brigand `doctrine = "hold_ground"`, INT 4 for tier 2 test.

- [ ] **Step 5: Playtest** — brigand seeks table cover before attacking.

- [ ] **Step 6: Commit**

```bash
git add scripts/combat/tactical_mind.gd scripts/combat/tactical_plan.gd scripts/data/monster_sheet.gd data/monsters/training_brigand.tres scripts/combat/battle_test_map.gd scripts/combat/combat_state.gd
git commit -m "feat(combat): TacticalMind tiers 1-3 and doctrine-driven enemy turns"
```

---

## Phase P6 — Influence maps + tiers 4–5 + commander

### Task 7: Influence maps and group plans

**Files:**
- Create: `scripts/combat/combat_influence_maps.gd`
- Create: `scripts/combat/group_battle_plan.gd`
- Modify: `scripts/combat/combat_grid.gd`
- Modify: `scripts/combat/tactical_mind.gd`

- [ ] **Step 1: `CombatInfluenceMaps.rebuild(grid, actors)`** — compute threat, cover_quality, chokepoint, retreat_safety per cell.

- [ ] **Step 2: Plan scoring uses maps** — `pincer_close` scores high when two flank lanes exist; `kill_box` when chokepoint traps player.

- [ ] **Step 3: `GroupBattlePlan`** — commander actor picks plan; `flanker`/`front` roles get sub-target cells.

- [ ] **Step 4: Add second brigand to test map** for pincer test.

- [ ] **Step 5: Playtest + commit**

```bash
git add scripts/combat/combat_influence_maps.gd scripts/combat/group_battle_plan.gd
git commit -m "feat(combat): influence maps and commander group tactics"
```

---

## Phase P7 — Curse stages + tier 6 belief

### Task 8: Curse tactical integration

**Files:**
- Modify: `scripts/combat/combat_actor.gd`
- Modify: `scripts/combat/tactical_mind.gd`

- [ ] **Step 1: `curse_stacks` on actor** — latent/active/compounding per spec table.

- [ ] **Step 2: MOV −1 at active; rotate costs 1 MOV at compounding.**

- [ ] **Step 3: Tier 6 mind** — `curse_press` plan prefers corrupted targets; bounded route memory in `belief_last_seen` trail.

- [ ] **Step 4: Playtest + commit**

```bash
git commit -m "feat(combat): curse-stage tactics and infernal mind tier"
```

---

## Phase P8 — Ability tactical profiles

### Task 9: Cones and spell cover

**Files:**
- Create: `scripts/combat/tactical_profile.gd`
- Modify: `scripts/combat/combat_state.gd`

- [ ] **Step 1: `TacticalProfile` resource** with `attack_pattern`, `range_max`, `facing_required`.

- [ ] **Step 2: `get_cells_in_cone(actor, profile)`** — 90° arc from facing, range N.

- [ ] **Step 3: Barricade ritual spawns timed `CoverVolume` via `place_terrain`.**

- [ ] **Step 4: Playtest cone ability + commit**

```bash
git add scripts/combat/tactical_profile.gd
git commit -m "feat(combat): tactical ability profiles and spell cover"
```

---

## Spec Coverage Checklist

| Spec section | Plan task | Status |
|--------------|-----------|--------|
| 8-way facing + flank arcs | P1 Task 1 | [x] |
| move / rotate / act | P1 Task 2 | [x] |
| Jump movement costs | P3 Task 4 | [x] |
| CoverVolume | P2 Task 3 | [x] |
| Battle overlay UI | P4 Task 5 | [x] |
| TacticalMind + INT tiers | P5 Task 6 | [ ] (partial) |
| Influence maps + commander | P6 Task 7 | [ ] |
| Curse stages | P7 Task 8 | [ ] |
| TacticalProfile abilities | P8 Task 9 | [ ] |
| MonsterSheet doctrine fields | P5 Task 6 | [x] |
| Art of War doctrines | P5–P6 plan scoring | [ ] |

**Combat system:** Core implemented and tested (grid engagement, CT/action-based turns, height costs, facing). Checkmarked in tracking. 

**Day/Night cycle:** Fully implemented (day_night_cycle.gd driving sun, sky, ambient, fog, torches; action-tied in combat). Marked complete in tracking.

**Weather (new):** Implemented WeatherSystem for battles - location (beach=hurricane) + dynamic mid-battle changes (rainstorm etc.). Affects env, CT, move, LOS, damage, height. Action-based with skills support. See scripts/weather_system.gd and battle_test_map integration. Ready for AI tie-in.

**Deferred (open questions):** battle orders UI, hidden INT on sheet, boss MCTS — not in this plan.

---

## Execution Order

```
P1 → P2 → P3 → P4 → P5 → P6 → P7 → P8
```

Stop and playtest after each phase. Do not start P5 until P1–P4 feel good in the tavern test map.