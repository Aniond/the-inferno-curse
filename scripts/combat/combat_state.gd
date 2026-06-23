extends Node
class_name CombatState

signal encounter_started
signal actor_turn_started(actor: CombatActor)
signal ct_updated
signal encounter_ended(result_phase: int)

enum Phase {
	READY,
	STARTED,
	ACTOR_TURN,
	ACTION_RESOLUTION,
	ROUND_END,
	VICTORY,
	DEFEAT,
}

const CT_ACTION_THRESHOLD := 100

@export var ct_tick_interval: float = 0.35

var grid: CombatGrid = null
var actors: Array[CombatActor] = []
var active_actor: CombatActor = null
var active_terrain: Array[CombatTerrain] = []
var terrain_cells: Dictionary = {}
var terrain_cell_snapshots: Dictionary = {}
var round: int = 0
var phase: int = Phase.READY
var turns_completed: int = 0
var active_turn_controller: CombatTurnController = null

var _encounter_active: bool = false
var _ct_tick_timer: float = 0.0

func start_encounter(grid_node: CombatGrid, actor_nodes: Array) -> void:
	grid = grid_node
	actors = []
	for actor in actor_nodes:
		if actor is CombatActor:
			actors.append(actor)
		else:
			push_warning("Non-CombatActor passed to CombatState.start_encounter: %s" % actor)

	if grid == null:
		push_error("CombatState needs a CombatGrid to start an encounter.")
		return

	for actor in actors:
		if actor.current_cell == null:
			var start_cell = grid.get_cell(actor.starting_grid_position)
			actor.set_current_cell(start_cell)
			if start_cell != null:
				actor.global_position = start_cell.world_position

	round = 1
	turns_completed = 0
	_ct_tick_timer = 0.0
	_encounter_active = true
	phase = Phase.STARTED
	encounter_started.emit()
	_try_grant_next_actor_turn()


func _process(delta: float) -> void:
	if not _encounter_active or phase == Phase.ACTOR_TURN:
		return
	if phase == Phase.VICTORY or phase == Phase.DEFEAT:
		return
	if is_encounter_over():
		_stop_encounter()
		return

	_ct_tick_timer += delta
	while _ct_tick_timer >= ct_tick_interval and phase != Phase.ACTOR_TURN:
		_ct_tick_timer -= ct_tick_interval
		_tick_ct()
		if phase == Phase.ACTOR_TURN:
			break


func _tick_ct() -> void:
	for actor in actors:
		if not actor.is_alive():
			continue
		actor.current_ct = mini(actor.current_ct + maxi(1, actor.speed), CT_ACTION_THRESHOLD * 2)
	ct_updated.emit()
	_try_grant_next_actor_turn()


func _try_grant_next_actor_turn() -> void:
	if phase == Phase.ACTOR_TURN or not _encounter_active:
		return

	var ready: Array[CombatActor] = []
	for actor in actors:
		if actor.is_alive() and actor.current_ct >= CT_ACTION_THRESHOLD:
			ready.append(actor)
	if ready.is_empty():
		phase = Phase.STARTED
		return

	ready.sort_custom(_sort_ct_priority)
	active_actor = ready[0]
	active_actor.current_ct -= CT_ACTION_THRESHOLD
	active_turn_controller = CombatTurnController.new()
	active_turn_controller.reset()
	phase = Phase.ACTOR_TURN
	actor_turn_started.emit(active_actor)


func _sort_ct_priority(a: CombatActor, b: CombatActor) -> bool:
	if a.current_ct != b.current_ct:
		return a.current_ct > b.current_ct
	if a.speed != b.speed:
		return a.speed > b.speed
	return a.actor_id < b.actor_id


func end_actor_turn() -> void:
	if phase != Phase.ACTOR_TURN:
		return
	if active_turn_controller != null and not active_turn_controller.is_done():
		return

	turns_completed += 1
	var living_count := actors.filter(func(actor): return actor.is_alive()).size()
	if living_count > 0 and turns_completed % living_count == 0:
		round += 1
		_tick_temporary_terrain()

	phase = Phase.ACTION_RESOLUTION
	active_actor = null
	active_turn_controller = null

	if is_encounter_over():
		_stop_encounter()
		return

	phase = Phase.STARTED
	_try_grant_next_actor_turn()


func _stop_encounter() -> void:
	_encounter_active = false
	encounter_ended.emit(phase)


func get_ct_threshold() -> int:
	return CT_ACTION_THRESHOLD


func get_turn_controller() -> CombatTurnController:
	return active_turn_controller

func get_reachable_cells(actor: CombatActor) -> Array:
	var reachable: Array = []
	if actor == null or actor.current_cell == null:
		return reachable
	var frontier: Array = [{"cell": actor.current_cell, "cost": 0}]
	var visited: Dictionary = {actor.current_cell.grid_position: 0}

	while frontier.size() > 0:
		var entry = frontier.pop_front()
		var cell: CombatCell = entry["cell"]
		var cost: int = entry["cost"]
		reachable.append(cell)
		for neighbor in grid.get_neighbors(cell, grid.allow_diagonal_movement):
			if neighbor == null or not neighbor.walkable or neighbor.is_occupied():
				continue
			if not _can_traverse_height(actor, cell, neighbor):
				continue
			var is_diagonal: bool = abs(cell.grid_position.x - neighbor.grid_position.x) == 1 and abs(cell.grid_position.y - neighbor.grid_position.y) == 1
			var step_cost: int = 2 if is_diagonal else 1
			step_cost = max(step_cost, neighbor.movement_cost)
			var next_cost: int = cost + step_cost
			if next_cost > actor.movement:
				continue
			if not visited.has(neighbor.grid_position) or next_cost < visited[neighbor.grid_position]:
				visited[neighbor.grid_position] = next_cost
				frontier.append({"cell": neighbor, "cost": next_cost})
	return reachable

func get_attackable_targets(actor: CombatActor, attack_range: int = 1, is_ranged: bool = false, ignores_cover: bool = false) -> Array:
	var targets: Array = []
	if actor == null or actor.current_cell == null:
		return targets
	for candidate in actors:
		if candidate == actor or not candidate.is_alive() or candidate.faction == actor.faction or candidate.current_cell == null:
			continue
		if can_target_actor(actor, candidate, attack_range, is_ranged, ignores_cover):
			targets.append(candidate)
	return targets

func can_target_actor(attacker: CombatActor, defender: CombatActor, attack_range: int = 1, is_ranged: bool = false, ignores_cover: bool = false) -> bool:
	if attacker == null or defender == null or attacker.current_cell == null or defender.current_cell == null:
		return false
	var effective_range := attack_range
	if is_ranged:
		effective_range += grid.get_range_bonus_from_height(attacker.current_cell, defender.current_cell)

	if _grid_distance(attacker.current_cell, defender.current_cell) > effective_range:
		return false
	if is_ranged and not ignores_cover:
		return grid.is_grid_line_of_sight_clear(attacker.current_cell, defender.current_cell, true)
	if not is_ranged and not _can_melee_reach(attacker, defender):
		return false
	return true


func calculate_damage(attacker: CombatActor, defender: CombatActor, base_damage: int = 0, is_ranged: bool = false, ignores_cover: bool = false) -> int:
	if attacker == null or defender == null:
		return 0
	var raw_attack = attacker.get_attack_power() + base_damage
	var cover := 0
	if is_ranged and not ignores_cover:
		cover = grid.get_directional_cover_modifier(attacker.current_cell, defender.current_cell)
	var height := grid.get_ranged_height_modifier(attacker.current_cell, defender.current_cell) if is_ranged else grid.get_height_modifier(attacker.current_cell, defender.current_cell)
	var flank = grid.get_flank_bonus(attacker, defender)
	var pincer = grid.get_pincer_bonus(attacker, defender, actors)
	var defense = defender.get_defense_value() + cover
	return max(1, raw_attack + height + flank + pincer - defense)

func resolve_attack(attacker: CombatActor, defender: CombatActor, base_damage: int = 0, is_ranged: bool = false, ignores_cover: bool = false) -> int:
	var damage = calculate_damage(attacker, defender, base_damage, is_ranged, ignores_cover)
	defender.apply_damage(damage)
	if defender.is_alive():
		defender.face_cell(attacker.current_cell)
	return damage

func is_encounter_over() -> bool:
	var allies_alive = actors.any(func(actor): return actor.is_alive() and actor.faction == "player")
	var enemies_alive = actors.any(func(actor): return actor.is_alive() and actor.faction == "enemy")
	if not allies_alive:
		phase = Phase.DEFEAT
		return true
	if not enemies_alive:
		phase = Phase.VICTORY
		return true
	return false

func get_actor_by_id(actor_id: String) -> CombatActor:
	for actor in actors:
		if actor.actor_id == actor_id:
			return actor
	return null


func place_terrain(terrain: CombatTerrain, affected_cells: Array[CombatCell], owner: CombatActor = null, source_ability_id: String = "") -> void:
	if terrain == null:
		return
	if owner != null:
		terrain.owner_actor_id = owner.actor_id
	if source_ability_id != "":
		terrain.source_ability_id = source_ability_id
	if not active_terrain.has(terrain):
		active_terrain.append(terrain)
	terrain_cells[terrain] = affected_cells.duplicate()
	var snapshots: Dictionary = {}
	for cell in affected_cells:
		snapshots[cell] = _snapshot_cell(cell)
		grid.apply_terrain_to_cell(cell, terrain)
	if terrain is CoverVolume:
		grid.register_cover_volume(terrain as CoverVolume)
	terrain_cell_snapshots[terrain] = snapshots


func remove_terrain(terrain: CombatTerrain, affected_cells: Array[CombatCell]) -> void:
	if terrain == null:
		return
	active_terrain.erase(terrain)
	var cells_to_clear: Array = affected_cells
	if cells_to_clear.is_empty() and terrain_cells.has(terrain):
		cells_to_clear = terrain_cells[terrain]
	for cell in cells_to_clear:
		if terrain_cell_snapshots.has(terrain) and terrain_cell_snapshots[terrain].has(cell):
			_restore_cell(cell, terrain_cell_snapshots[terrain][cell])
		else:
			grid.clear_terrain_from_cell(cell)
	if terrain is CoverVolume:
		grid.unregister_cover_volume(terrain as CoverVolume)
	terrain_cells.erase(terrain)
	terrain_cell_snapshots.erase(terrain)


func _tick_temporary_terrain() -> void:
	var expired: Array[CombatTerrain] = []
	for terrain in active_terrain:
		if terrain.duration_rounds <= 0:
			continue
		terrain.duration_rounds -= 1
		if terrain.duration_rounds <= 0:
			expired.append(terrain)
	for terrain in expired:
		var affected_cells: Array[CombatCell] = []
		remove_terrain(terrain, affected_cells)


func _grid_distance(from_cell: CombatCell, to_cell: CombatCell) -> int:
	var delta: Vector2i = from_cell.grid_position - to_cell.grid_position
	return max(abs(delta.x), abs(delta.y)) if grid.allow_diagonal_movement else abs(delta.x) + abs(delta.y)


func _can_traverse_height(actor: CombatActor, from_cell: CombatCell, to_cell: CombatCell) -> bool:
	var height_delta: int = abs(to_cell.get_effective_height_level() - from_cell.get_effective_height_level())
	return height_delta <= actor.jump


func _can_melee_reach(attacker: CombatActor, defender: CombatActor) -> bool:
	if _grid_distance(attacker.current_cell, defender.current_cell) > 1:
		return false
	var height_delta: int = abs(attacker.current_cell.get_effective_height_level() - defender.current_cell.get_effective_height_level())
	return height_delta <= attacker.jump


func _snapshot_cell(cell: CombatCell) -> Dictionary:
	return {
		"walkable": cell.walkable,
		"cover_level": cell.cover_level,
		"obstruction": cell.obstruction,
		"blocks_line_of_sight": cell.blocks_line_of_sight,
		"movement_cost": cell.movement_cost,
		"terrain_height_delta": cell.terrain_height_delta,
		"terrain_tags": cell.terrain_tags.duplicate(),
		"temporary_effect_ids": cell.temporary_effect_ids.duplicate(),
	}


func _restore_cell(cell: CombatCell, snapshot: Dictionary) -> void:
	cell.walkable = snapshot["walkable"]
	cell.cover_level = snapshot["cover_level"]
	cell.obstruction = snapshot["obstruction"]
	cell.blocks_line_of_sight = snapshot["blocks_line_of_sight"]
	cell.movement_cost = snapshot["movement_cost"]
	cell.terrain_height_delta = snapshot["terrain_height_delta"]
	cell.terrain_tags = snapshot["terrain_tags"]
	cell.temporary_effect_ids = snapshot["temporary_effect_ids"]
