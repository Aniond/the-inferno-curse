extends RefCounted
class_name EnemyCommander

## Squad coordination layer (Phase 2). A commander reads the board once per
## round and writes an AiDirective onto each living subordinate. It emits only
## data; it never moves anything. The per-unit EnemyTacticalAI consumes the
## directives as biases.
##
## Pure logic (RefCounted), so it is unit-testable: feed it state + actor lists,
## inspect the directives written onto subordinates.

const LOW_HP_FRAC := 0.4   # a target at/under this fraction is "vulnerable"

var _state: CombatState = null
var _grid: CombatGrid = null


func _init(state: CombatState, grid: CombatGrid) -> void:
	_state = state
	_grid = grid


## Plan the round: choose squad posture + focus target, then assign each
## subordinate a formation slot. Writes directives onto subordinates' actors.
func plan_round(commander: CombatActor) -> void:
	if commander == null:
		return
	var subordinates := _living_allies(commander)
	var enemies := _living_enemies(commander)
	if enemies.is_empty():
		return

	var focus := _pick_focus_target(enemies)
	var posture := _pick_posture(commander, focus, subordinates)

	# Low-INT commanders only issue a blunt "all press the focus" order.
	var crude := commander.intelligence < 5

	var flank_toggle := true
	for unit in subordinates:
		var d := AiDirective.new()
		d.posture = posture
		d.focus_target = focus
		d.anchor_cell = commander.current_cell
		if crude:
			d.formation_slot = AiDirective.Slot.NONE
		else:
			d.formation_slot = _assign_slot(posture, flank_toggle)
			flank_toggle = not flank_toggle
		unit.pending_directive = d


# ---------------------------------------------------------------------------
# Decisions
# ---------------------------------------------------------------------------

## Concentrate fire on the most finishable target (lowest current HP).
func _pick_focus_target(enemies: Array) -> CombatActor:
	var best: CombatActor = null
	var best_hp := 1 << 30
	for e in enemies:
		if e.current_hp < best_hp:
			best_hp = e.current_hp
			best = e
	return best


## PRESS when the player is vulnerable (low HP), HOLD when they look strong,
## HARASS otherwise. High-INT commanders read this; crude ones always PRESS.
func _pick_posture(commander: CombatActor, focus: CombatActor, subordinates: Array) -> int:
	if commander.intelligence < 5:
		return AiDirective.Posture.PRESS
	if focus != null and _hp_fraction(focus) <= LOW_HP_FRAC:
		return AiDirective.Posture.PRESS
	# Outnumbered heavily -> hold and let CT/positioning favor us.
	if subordinates.size() + 1 <= _living_enemies(commander).size():
		return AiDirective.Posture.HOLD
	return AiDirective.Posture.HARASS


## Alternate flanks for a pincer; screen on HOLD.
func _assign_slot(posture: int, flank_toggle: bool) -> int:
	if posture == AiDirective.Posture.HOLD:
		return AiDirective.Slot.SCREEN
	return AiDirective.Slot.FLANK_LEFT if flank_toggle else AiDirective.Slot.FLANK_RIGHT


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _living_allies(commander: CombatActor) -> Array:
	var out := []
	for a in _state.actors:
		if a == null or a == commander:
			continue
		if a.is_alive() and a.faction == commander.faction and a.current_cell != null:
			out.append(a)
	return out


func _living_enemies(commander: CombatActor) -> Array:
	var out := []
	for a in _state.actors:
		if a == null:
			continue
		if a.is_alive() and a.faction != commander.faction and a.current_cell != null:
			out.append(a)
	return out


func _hp_fraction(actor: CombatActor) -> float:
	var max_hp := 1
	if actor.sheet_resource != null and actor.sheet_resource.has_method("get_max_hp"):
		max_hp = actor.sheet_resource.get_max_hp()
	else:
		max_hp = maxi(actor.current_hp, 1)
	return float(actor.current_hp) / float(maxi(max_hp, 1))
