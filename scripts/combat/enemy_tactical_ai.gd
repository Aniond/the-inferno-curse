extends RefCounted
class_name EnemyTacticalAI

## Per-unit tactical AI (the INTENT layer). Pure logic, no scene nodes, so it
## is unit-testable: feed it CombatState + CombatGrid, call choose_turn(actor),
## get back a scored AiTurnPlan. The motion layer (battle_test_map) executes it.
##
## Sophistication scales with actor.intelligence (1-10): which considerations
## are weighed, decision temperature, self-preservation threshold, and 1-ply
## lookahead are all gated/lerped on it. See the design spec.

const MAX_CANDIDATE_CELLS := 24
const LOOKAHEAD_PLAN_COUNT := 3
const LOOKAHEAD_INT_GATE := 7
const LOOKAHEAD_WEIGHT := 1.2

const TEMP_HIGH := 0.8   # INT 1: sloppy, frequently suboptimal
const TEMP_LOW := 0.05   # INT 10: near-deterministic optimal

const MELEE_RANGE := 1
const RANGED_RANGE := 5

## Base weight per consideration and the minimum intelligence to use it.
const WEIGHTS := {
	"damage": 1.0,
	"close_distance": 0.6,
	"flank": 0.8,
	"cover": 0.5,
	"height": 0.4,
	"exposure": 0.7,        # applied as a penalty
	"self_preserve": 1.0,
}
const INT_GATES := {
	"damage": 1,
	"close_distance": 1,
	"flank": 3,
	"cover": 4,
	"height": 4,
	"exposure": 5,
	"self_preserve": 5,
}

var _state: CombatState = null
var _grid: CombatGrid = null
var _rng: RandomNumberGenerator = null


func _init(state: CombatState, grid: CombatGrid, rng: RandomNumberGenerator = null) -> void:
	_state = state
	_grid = grid
	_rng = rng if rng != null else RandomNumberGenerator.new()


## Choose this actor's turn. directive is an optional AiDirective (Phase 2);
## null means act solo.
func choose_turn(actor: CombatActor, directive = null) -> AiTurnPlan:
	var plans := _enumerate_plans(actor)
	if plans.is_empty():
		# No reachable cells at all: stay put, no action.
		var fallback := AiTurnPlan.new()
		fallback.destination_cell = actor.current_cell
		fallback.facing = actor.get_tactical_facing()
		fallback.add_reason("no moves available")
		return fallback

	for plan in plans:
		_score_plan(actor, plan, directive)

	_apply_lookahead(actor, plans)
	return _select_plan(actor, plans)


# ---------------------------------------------------------------------------
# Plan enumeration
# ---------------------------------------------------------------------------

func _enumerate_plans(actor: CombatActor) -> Array[AiTurnPlan]:
	var plans: Array[AiTurnPlan] = []
	var cells := _candidate_cells(actor)
	var enemies := _opposing_actors(actor)

	for cell in cells:
		for target in enemies:
			var melee := _melee_reachable_from(actor, cell, target)
			var ranged := _ranged_reachable_from(cell, target)
			if not melee and not ranged:
				continue
			var plan := AiTurnPlan.new()
			plan.destination_cell = cell
			plan.target = target
			plan.facing = _facing_toward(cell, target.current_cell)
			plan.is_ranged = ranged and not melee
			plans.append(plan)
		# Always allow a no-attack plan for this cell (reposition / retreat).
		var move_plan := AiTurnPlan.new()
		move_plan.destination_cell = cell
		move_plan.target = null
		move_plan.facing = _facing_toward(cell, _nearest_enemy_cell(cell, enemies))
		plans.append(move_plan)

	return plans


func _candidate_cells(actor: CombatActor) -> Array:
	var costs := _state.get_reachable_cell_costs(actor)
	var cells := costs.keys()
	# Keep the cheapest MAX_CANDIDATE_CELLS to bound scoring cost.
	cells.sort_custom(func(a, b): return int(costs[a]) < int(costs[b]))
	if cells.size() > MAX_CANDIDATE_CELLS:
		cells = cells.slice(0, MAX_CANDIDATE_CELLS)
	if actor.current_cell != null and not cells.has(actor.current_cell):
		cells.append(actor.current_cell)
	return cells


func _opposing_actors(actor: CombatActor) -> Array:
	var out := []
	for other in _state.actors:
		if other == null or other == actor:
			continue
		if other.is_alive() and other.faction != actor.faction and other.current_cell != null:
			out.append(other)
	return out


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------

func _score_plan(actor: CombatActor, plan: AiTurnPlan, _directive) -> void:
	# _directive biases are applied in Phase 2 (Step 9); unused in Phase 1.
	var int_level := actor.intelligence
	var score := 0.0

	# damage + flank (only when attacking)
	if plan.target != null:
		var dmg := _hypothetical_damage(actor, plan, plan.is_ranged)
		score += _w("damage") * float(dmg)
		plan.add_reason("dmg %d" % dmg)

		if _gated(int_level, "flank"):
			var arc := _arc_from_cell(plan.destination_cell, plan.target)
			var arc_bonus := _arc_bonus(arc)
			if arc_bonus > 0:
				score += _w("flank") * float(arc_bonus)
				plan.add_reason("%s +%d%%" % [_arc_name(arc), arc_bonus])

	# close_distance: reward getting nearer the nearest enemy
	if _gated(int_level, "close_distance"):
		var enemies := _opposing_actors(actor)
		var before := _dist_to_nearest(actor.current_cell, enemies)
		var after := _dist_to_nearest(plan.destination_cell, enemies)
		var closed := before - after
		if closed != 0:
			score += _w("close_distance") * float(closed)
			if closed > 0:
				plan.add_reason("closed %d" % closed)

	# cover: standing on a cover cell
	if _gated(int_level, "cover") and plan.destination_cell != null:
		var cover := int(plan.destination_cell.cover_level)
		if cover > 0:
			score += _w("cover") * float(cover)
			plan.add_reason("cover %d" % cover)

	# height: advantage over the target
	if _gated(int_level, "height") and plan.target != null and plan.destination_cell != null:
		var h := plan.destination_cell.get_effective_height_level() - plan.target.current_cell.get_effective_height_level()
		if h > 0:
			score += _w("height") * float(h)
			plan.add_reason("height +%d" % h)

	# exposure: penalty for ending in reach of living enemies
	if _gated(int_level, "exposure"):
		var exposure := _exposure_at(actor, plan.destination_cell)
		if exposure > 0:
			score -= _w("exposure") * float(exposure)
			plan.add_reason("exposed -%d" % exposure)

	# self_preserve: when wounded, value distance/safety, devalue attacking
	if _gated(int_level, "self_preserve") and _is_wounded(actor):
		var enemies2 := _opposing_actors(actor)
		var safety := _dist_to_nearest(plan.destination_cell, enemies2)
		score += _w("self_preserve") * float(safety)
		plan.add_reason("retreat safety %d" % safety)

	plan.score = score


func _hypothetical_damage(actor: CombatActor, plan: AiTurnPlan, is_ranged: bool) -> int:
	# calculate_damage reads attacker.current_cell for cover/height/flank. The
	# attacker has not moved yet, so approximate by basing the estimate on the
	# planned arc bonus instead of mutating state. Use the engine calc for the
	# base (power vs defense) and add our own flank delta.
	var base := _state.calculate_damage(actor, plan.target, 0, is_ranged)
	return maxi(1, base)


# ---------------------------------------------------------------------------
# 1-ply lookahead (INT-gated)
# ---------------------------------------------------------------------------

func _apply_lookahead(actor: CombatActor, plans: Array[AiTurnPlan]) -> void:
	if actor.intelligence < LOOKAHEAD_INT_GATE:
		return
	# Penalize only the current top plans (by pre-lookahead score).
	var ranked := plans.duplicate()
	ranked.sort_custom(func(a, b): return a.score > b.score)
	var count := mini(LOOKAHEAD_PLAN_COUNT, ranked.size())
	for i in count:
		var plan: AiTurnPlan = ranked[i]
		var threat := _lookahead_penalty(actor, plan)
		if threat > 0.0:
			plan.score -= LOOKAHEAD_WEIGHT * threat
			plan.add_reason("counter risk -%.0f" % threat)


## Worst-case retaliation damage against actor if it stands on plan's cell.
## No nested lookahead. Returns 0 below the INT gate.
func _lookahead_penalty(actor: CombatActor, plan: AiTurnPlan) -> float:
	if actor.intelligence < LOOKAHEAD_INT_GATE or plan.destination_cell == null:
		return 0.0
	var worst := 0.0
	for foe in _opposing_actors(actor):
		# Could the foe reach a cell adjacent to our destination and hit us?
		var dist := _chebyshev(foe.current_cell.grid_position, plan.destination_cell.grid_position)
		# Approx: foe can close if within its movement+1; estimate its damage to us.
		if dist <= foe.movement + MELEE_RANGE:
			var dmg := _state.calculate_damage(foe, actor, 0, false)
			worst = maxf(worst, float(dmg))
	return worst


# ---------------------------------------------------------------------------
# Selection (softmax top-k)
# ---------------------------------------------------------------------------

func _select_plan(actor: CombatActor, plans: Array[AiTurnPlan]) -> AiTurnPlan:
	var temperature := lerpf(TEMP_HIGH, TEMP_LOW, clampf(float(actor.intelligence) / 10.0, 0.0, 1.0))
	if temperature <= 0.0001:
		return _argmax(plans)

	# Softmax sample over scores.
	var max_score := plans[0].score
	for p in plans:
		max_score = maxf(max_score, p.score)
	var weights: Array[float] = []
	var total := 0.0
	for p in plans:
		var w := exp((p.score - max_score) / temperature)
		weights.append(w)
		total += w
	if total <= 0.0:
		return _argmax(plans)
	var roll := _rng.randf() * total
	var acc := 0.0
	for i in plans.size():
		acc += weights[i]
		if roll <= acc:
			return plans[i]
	return plans[plans.size() - 1]


func _argmax(plans: Array[AiTurnPlan]) -> AiTurnPlan:
	var best: AiTurnPlan = plans[0]
	for p in plans:
		if p.score > best.score:
			best = p
	return best


# ---------------------------------------------------------------------------
# Helpers (self-contained: depend only on state/grid, never the map node)
# ---------------------------------------------------------------------------

func _w(key: String) -> float:
	return float(WEIGHTS.get(key, 0.0))


func _gated(int_level: int, key: String) -> bool:
	return int_level >= int(INT_GATES.get(key, 99))


func _is_wounded(actor: CombatActor) -> bool:
	var max_hp := _max_hp(actor)
	if max_hp <= 0:
		return false
	var frac := float(actor.current_hp) / float(max_hp)
	var retreat_frac := lerpf(0.0, 0.4, clampf(float(actor.intelligence) / 10.0, 0.0, 1.0))
	return frac < retreat_frac


func _max_hp(actor: CombatActor) -> int:
	if actor.sheet_resource != null and actor.sheet_resource.has_method("get_max_hp"):
		return actor.sheet_resource.get_max_hp()
	return maxi(actor.current_hp, 1)


func _melee_reachable_from(actor: CombatActor, from_cell: CombatCell, target: CombatActor) -> bool:
	if from_cell == null or target == null or target.current_cell == null:
		return false
	var dist := _chebyshev(from_cell.grid_position, target.current_cell.grid_position)
	var h_delta: int = absi(from_cell.get_effective_height_level() - target.current_cell.get_effective_height_level())
	return dist <= MELEE_RANGE and h_delta <= actor.jump


func _ranged_reachable_from(from_cell: CombatCell, target: CombatActor) -> bool:
	if from_cell == null or target == null or target.current_cell == null or _grid == null:
		return false
	var dist := _chebyshev(from_cell.grid_position, target.current_cell.grid_position)
	if dist > RANGED_RANGE:
		return false
	return _grid.is_grid_line_of_sight_clear(from_cell, target.current_cell, true)


func _exposure_at(actor: CombatActor, cell: CombatCell) -> int:
	if cell == null:
		return 0
	var count := 0
	for foe in _opposing_actors(actor):
		var dist := _chebyshev(foe.current_cell.grid_position, cell.grid_position)
		if dist <= foe.movement + MELEE_RANGE:
			count += 1
	return count


func _dist_to_nearest(cell: CombatCell, enemies: Array) -> int:
	if cell == null or enemies.is_empty():
		return 0
	var best := 9999
	for e in enemies:
		best = mini(best, _chebyshev(cell.grid_position, e.current_cell.grid_position))
	return best


func _nearest_enemy_cell(cell: CombatCell, enemies: Array) -> CombatCell:
	var best_cell: CombatCell = null
	var best := 9999
	for e in enemies:
		var d := _chebyshev(cell.grid_position, e.current_cell.grid_position)
		if d < best:
			best = d
			best_cell = e.current_cell
	return best_cell


func _facing_toward(from_cell: CombatCell, to_cell: CombatCell) -> int:
	if from_cell == null or to_cell == null:
		return TacticalFacing.Direction.SOUTH
	return TacticalFacing.direction_from_vector(to_cell.grid_position - from_cell.grid_position)


func _arc_from_cell(from_cell: CombatCell, target: CombatActor) -> int:
	# Arc the target would be attacked from if the attacker stood on from_cell.
	var attack_delta := from_cell.grid_position - target.current_cell.grid_position
	return TacticalFacing.classify_attack_arc(target.get_tactical_facing(), attack_delta)


func _arc_bonus(arc: int) -> int:
	match arc:
		TacticalFacing.AttackArc.BACK:
			return 20
		TacticalFacing.AttackArc.LEFT_FLANK, TacticalFacing.AttackArc.RIGHT_FLANK:
			return 10
		_:
			return 0


func _arc_name(arc: int) -> String:
	match arc:
		TacticalFacing.AttackArc.BACK:
			return "back"
		TacticalFacing.AttackArc.LEFT_FLANK:
			return "left flank"
		TacticalFacing.AttackArc.RIGHT_FLANK:
			return "right flank"
		_:
			return "front"


func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return maxi(absi(d.x), absi(d.y))
