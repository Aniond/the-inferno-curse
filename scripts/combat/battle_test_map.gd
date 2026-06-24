extends Node3D

const PLAYER_SHEET := preload("res://data/characters/guglielmo_da_siena.tres")
const TEST_MONSTER_SHEET := preload("res://data/monsters/training_brigand.tres")

enum PlayerTurnPhase {
	INACTIVE,
	MOVE,
	ROTATE,
	ATTACK,
}

@export var start_combat_on_ready: bool = false
@export var encounter_trigger_radius: float = 2.75
@export var grid_columns: int = 15
@export var grid_rows: int = 15
@export var grid_cell_size: float = 2.0
@export var grid_origin: Vector3 = Vector3(-15.0, 0.04, -15.0)

var combat_grid: CombatGrid = null
var combat_state: CombatState = null
var player_actor: CombatActor = null
var monster_actor: CombatActor = null
var _battle_overlay: BattleOverlay = null
var _player_node: CharacterBody3D = null
var _encounter_started: bool = false
var _combat_active: bool = false
var _player_phase: int = PlayerTurnPhase.INACTIVE
var weather_system: Node = null
var _reachable_cells: Array = []
var _attackable_targets: Array = []
var _last_action_text: String = ""
var _highlight_root: Node3D = null
var _facing_indicator: MeshInstance3D = null
var _tactical_ai_client: TacticalAiClient = null
var _use_ranged_attack: bool = false
var _reachable_costs: Dictionary = {}
var _exploration_reachable_costs: Dictionary = {}
var _grid_cursor: MeshInstance3D = null
var _hovered_cell: CombatCell = null


func _ready() -> void:
	_create_combat_state()
	_create_player_actor()
	_create_test_monster_actor()
	_create_battle_overlay()
	_player_node = get_node_or_null("Player") as CharacterBody3D
	# Weather system for battles (location + dynamic)
	weather_system = load("res://scripts/weather_system.gd").new()
	weather_system.name = "WeatherSystem"
	add_child(weather_system)
	# Grid and tactical elements are NOT created here. They start only on enemy engagement.
	# This allows normal free movement ("walking around") until combat begins.
	combat_state.grid = null

	# Do not force grid movement until engaged
	if _player_node != null:
		_player_node.grid_movement_only = false

	combat_state.actor_turn_started.connect(_on_actor_turn_started)
	combat_state.ct_updated.connect(_refresh_battle_ui)
	combat_state.encounter_ended.connect(_on_encounter_ended)

	_setup_tactical_ai_client()

	if start_combat_on_ready:
		_start_test_combat()
	else:
		_refresh_battle_ui()


func _process(_delta: float) -> void:
	if combat_grid != null:
		_update_grid_cursor()
		_update_attack_preview()


func _physics_process(_delta: float) -> void:
	if _encounter_started or monster_actor == null:
		return
	if _player_node == null:
		return
	if _player_node.global_position.distance_to(monster_actor.global_position) <= encounter_trigger_radius:
		_start_test_combat()


func _unhandled_input(event: InputEvent) -> void:
	# Only consume grid/tactical inputs after the grid has been engaged (enemy combat started).
	# Before engagement the player walks around normally with free movement.
	if combat_grid == null or not _encounter_started:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _handle_mouse_click():
				get_viewport().set_input_as_handled()
			return

	if _is_grid_move_action_pressed(event):
		if _handle_grid_direction_move():
			get_viewport().set_input_as_handled()
		return

	if not _is_player_combat_turn():
		return

	if event.is_action_pressed("ui_accept"):
		if _player_phase == PlayerTurnPhase.MOVE:
			_player_skip_move()
		elif _player_phase == PlayerTurnPhase.ROTATE:
			_player_skip_rotate()
		elif _player_phase == PlayerTurnPhase.ATTACK:
			_player_skip_attack()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and (event as InputEventKey).pressed:
		var key_event := event as InputEventKey
		if _player_phase == PlayerTurnPhase.ROTATE:
			if key_event.keycode == KEY_Q:
				_player_rotate(-1)
				get_viewport().set_input_as_handled()
				return
			if key_event.keycode == KEY_E:
				_player_rotate(1)
				get_viewport().set_input_as_handled()
				return
		if _player_phase == PlayerTurnPhase.ATTACK and key_event.keycode == KEY_R:
			_use_ranged_attack = not _use_ranged_attack
			_begin_player_attack_phase()
			get_viewport().set_input_as_handled()
			return


func _create_combat_grid() -> void:
	combat_grid = CombatGrid.new()
	combat_grid.name = "CombatGrid"
	combat_grid.columns = grid_columns
	combat_grid.rows = grid_rows
	combat_grid.cell_width = grid_cell_size
	combat_grid.cell_depth = grid_cell_size
	combat_grid.origin = grid_origin
	combat_grid.allow_diagonal_movement = true
	add_child(combat_grid)
	combat_grid.build_grid()


func _create_grid_visuals() -> void:
	var grid_visuals := Node3D.new()
	grid_visuals.name = "BattleGridVisuals"
	add_child(grid_visuals)

	var line_material := StandardMaterial3D.new()
	line_material.albedo_color = Color(0.35, 0.75, 1.0, 0.45)
	line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var total_width := float(grid_columns) * grid_cell_size
	var total_depth := float(grid_rows) * grid_cell_size
	for x in range(grid_columns + 1):
		var line := _make_grid_line(Vector3(0.035, 0.035, total_depth), line_material)
		line.position = grid_origin + Vector3(float(x) * grid_cell_size, 0.02, total_depth * 0.5)
		grid_visuals.add_child(line)
	for y in range(grid_rows + 1):
		var line := _make_grid_line(Vector3(total_width, 0.035, 0.035), line_material)
		line.position = grid_origin + Vector3(total_width * 0.5, 0.02, float(y) * grid_cell_size)
		grid_visuals.add_child(line)


func _create_highlight_root() -> void:
	_highlight_root = Node3D.new()
	_highlight_root.name = "BattleCellHighlights"
	add_child(_highlight_root)


func _create_grid_cursor() -> void:
	_grid_cursor = MeshInstance3D.new()
	_grid_cursor.name = "GridCursor"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(grid_cell_size * 0.96, 0.1, grid_cell_size * 0.96)
	_grid_cursor.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.95, 1.0, 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_grid_cursor.material_override = material
	_grid_cursor.visible = false
	_highlight_root.add_child(_grid_cursor)


func _make_grid_line(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var line := MeshInstance3D.new()
	line.mesh = mesh
	line.material_override = material
	return line


func _mark_wall_border_cells() -> void:
	for x in range(grid_columns):
		for y in range(grid_rows):
			if x > 0 and x < grid_columns - 1 and y > 0 and y < grid_rows - 1:
				continue
			var cell := combat_grid.get_cell(Vector2i(x, y))
			if cell == null:
				continue
			cell.walkable = false
			cell.obstruction = true
			cell.blocks_line_of_sight = true
			cell.terrain_tags.append("tavern_wall")


func _apply_test_map_tactical_cells() -> void:
	_mark_wall_border_cells()

	for coord in [Vector2i(4, 10), Vector2i(5, 10), Vector2i(10, 10), Vector2i(11, 10), Vector2i(3, 5)]:
		var cell := combat_grid.get_cell(coord)
		if cell != null:
			cell.cover_level = CombatCell.CoverLevel.HALF
			cell.terrain_tags.append("table_cover")

	for coord in [Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3)]:
		var cell := combat_grid.get_cell(coord)
		if cell != null:
			cell.cover_level = CombatCell.CoverLevel.FULL
			cell.obstruction = true
			cell.walkable = false
			cell.blocks_line_of_sight = true
			cell.terrain_tags.append("bar_counter")

	var raised_cell := combat_grid.get_cell(Vector2i(6, 6))
	if raised_cell != null:
		raised_cell.height_level = 1
		raised_cell.terrain_tags.append("raised_floor_test")


func _create_test_cover_volumes() -> void:
	var barrel := CoverVolume.new()
	barrel.name = "TestBarrelCover"
	barrel.terrain_id = "tavern_barrel_cover"
	barrel.grid_position = Vector2i(7, 10)
	barrel.cover_facing = "north"
	barrel.coverage_arc = 180.0
	barrel.cover_level = CombatCell.CoverLevel.HALF
	barrel.block_movement = false
	barrel.is_obstruction = false
	barrel.blocks_line_of_sight = false

	var barrel_cell := combat_grid.get_cell(barrel.grid_position)
	if barrel_cell != null:
		barrel.position = combat_grid.grid_to_world(barrel.grid_position, barrel_cell.get_effective_height_level())
	barrel.add_child(_make_cover_volume_marker(Color(0.45, 0.28, 0.12, 1.0)))
	combat_grid.add_child(barrel)
	combat_grid.register_cover_volume(barrel)


func _make_cover_volume_marker(color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = grid_cell_size * 0.22
	mesh.bottom_radius = grid_cell_size * 0.26
	mesh.height = grid_cell_size * 0.55
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	var marker := MeshInstance3D.new()
	marker.mesh = mesh
	marker.material_override = material
	marker.position = Vector3(0.0, mesh.height * 0.5, 0.0)
	return marker


func _create_combat_state() -> void:
	combat_state = CombatState.new()
	combat_state.name = "CombatState"
	add_child(combat_state)


func _create_player_actor() -> void:
	player_actor = CombatActor.new()
	player_actor.name = "PlayerCombatActor"
	player_actor.actor_id = "player_guglielmo"
	player_actor.display_name = "Guglielmo da Siena"
	player_actor.faction = "player"
	player_actor.sheet_resource = PLAYER_SHEET
	player_actor.starting_grid_position = Vector2i(7, 7)
	player_actor.visual_facing = "north"
	add_child(player_actor)
	player_actor.global_position = _grid_to_world(player_actor.starting_grid_position)
	# Position will be updated on grid engagement / snap.

	if _player_node == null:
		_player_node = get_node_or_null("Player") as CharacterBody3D
	# Visible player moves freely until engagement.


func _create_test_monster_actor() -> void:
	monster_actor = CombatActor.new()
	monster_actor.name = "TrainingBrigandCombatActor"
	monster_actor.actor_id = "training_brigand_01"
	monster_actor.display_name = "Training Brigand"
	monster_actor.faction = "enemy"
	monster_actor.sheet_resource = TEST_MONSTER_SHEET
	monster_actor.starting_grid_position = Vector2i(7, 11)
	monster_actor.visual_facing = "north"
	add_child(monster_actor)
	monster_actor.global_position = _grid_to_world(monster_actor.starting_grid_position)
	monster_actor.add_child(_make_actor_marker(Color(0.75, 0.12, 0.08, 1.0), "Training Brigand"))


func _make_actor_marker(color: Color, label_text: String) -> Node3D:
	var marker := Node3D.new()
	marker.name = "BattleMarker"

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.35
	body_mesh.height = 1.5
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = color
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = body_mesh
	body.material_override = body_material
	body.position = Vector3(0, 0.8, 0)
	marker.add_child(body)

	var label := Label3D.new()
	label.name = "NameLabel"
	label.text = label_text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 1)
	label.position = Vector3(0, 1.95, 0)
	marker.add_child(label)
	return marker


func _create_battle_overlay() -> void:
	_battle_overlay = BattleOverlay.new()
	_battle_overlay.name = "BattleOverlay"
	add_child(_battle_overlay)
	_battle_overlay.show_pre_combat("Walk around. Approach the Training Brigand to engage (tactical grid + CT turns activate on contact).")


func _apply_test_jump_modifiers() -> void:
	if player_actor == null:
		return
	# Toggle for manual playtests: set true to verify jump_cost_reduction.
	player_actor.apply_jump_traversal_modifiers({
		"jump_cost_reduction": 0,
		"jump_cost_multiplier": 1.0,
		"ignore_first_height_level": false,
		"downhill_free": false,
	})
	# Test CT modifiers from actions/status (e.g. slow from debuff)
	player_actor.apply_ct_modifiers({
		"ct_gain_multiplier": 0.5,
		"ct_gain_flat": 0
	})


func _ensure_tactical_grid_ready() -> void:
	# Build the tactical combat grid + visuals + overlays ONLY when the player engages the enemy.
	# Before this, the player uses normal free movement while walking around.
	if combat_grid != null:
		return

	_create_combat_grid()
	_create_grid_visuals()
	_create_highlight_root()
	_apply_test_map_tactical_cells()
	_create_test_cover_volumes()
	_create_grid_cursor()
	_create_cover_indicators()

	# Assign initial cells now that grid exists
	if player_actor != null and player_actor.current_cell == null:
		var start_cell := combat_grid.get_cell(player_actor.starting_grid_position)
		if start_cell != null:
			player_actor.set_current_cell(start_cell)
	if monster_actor != null and monster_actor.current_cell == null:
		var mcell := combat_grid.get_cell(monster_actor.starting_grid_position)
		if mcell != null:
			monster_actor.set_current_cell(mcell)
			# ensure marker position if needed


func _setup_tactical_ai_client() -> void:
	_tactical_ai_client = TacticalAiClient.new()
	if EnvSecrets.has_tactical_ai_key():
		_tactical_ai_client.configure(EnvSecrets.get_tactical_ai_api_key())
		print("Tactical AI: API key loaded from .env.local")
	else:
		push_warning("Tactical AI: no API key found in .env.local or environment.")


func _ping_tactical_ai() -> void:
	if _tactical_ai_client == null or not _tactical_ai_client.is_configured():
		return
	_tactical_ai_client.request_tactical_advice(
		'{"task":"ping","encounter":"training_brigand","reply_format":{"status":"ok"}}',
		_on_tactical_ai_ping_response
	)


func _on_tactical_ai_ping_response(payload: Dictionary) -> void:
	if not payload.get("ok", false):
		push_warning("Tactical AI ping failed: %s" % payload.get("error", payload.get("body", "unknown")))
		return
	var body_text := str(payload.get("body", ""))
	print("Tactical AI ping OK: %s" % body_text.left(240))


func _start_test_combat() -> void:
	if _encounter_started:
		return

	# Grid and tactical combat only start on engagement (not while walking around).
	_ensure_tactical_grid_ready()

	_encounter_started = true
	_combat_active = true
	_last_action_text = ""

	_snap_player_to_nearest_cell()
	_apply_test_jump_modifiers()
	combat_state.grid = combat_grid
	combat_state.start_encounter(combat_grid, [player_actor, monster_actor])
	combat_state.weather_system = weather_system
	# Demo: use BEACH + HURRICANE for dramatic mid-battle weather (or TAVERN + RAIN)
	weather_system.set_location(weather_system.LocationType.BEACH)
	weather_system.set_weather(weather_system.WeatherType.HURRICANE)
	_ping_tactical_ai()

	if _player_node != null:
		_player_node.grid_movement_only = true
		_player_node.movement_enabled = false
	_clear_highlights()
	_refresh_battle_ui()
	print("Battle started: %s vs %s" % [player_actor.display_name, monster_actor.display_name])


func _snap_player_to_nearest_cell() -> void:
	if _player_node == null or combat_grid == null or player_actor == null:
		return
	var grid_coord := combat_grid.world_to_grid(_player_node.global_position)
	var cell := combat_grid.get_cell(grid_coord)
	if cell == null or not cell.walkable or cell.is_occupied():
		cell = combat_grid.get_cell(player_actor.starting_grid_position)
	if cell != null:
		player_actor.set_current_cell(cell)
		_sync_player_node_from_actor()


func _on_actor_turn_started(actor: CombatActor) -> void:
	_clear_highlights()
	_player_phase = PlayerTurnPhase.INACTIVE
	_battle_overlay.clear_move_preview()
	_battle_overlay.clear_rotate_preview()
	_battle_overlay.clear_target_preview()
	_refresh_battle_ui()
	if actor == null:
		return
	if actor.faction == "enemy":
		_resolve_enemy_turn(actor)
	elif actor == player_actor:
		_begin_player_turn()


func _begin_player_turn() -> void:
	_player_phase = PlayerTurnPhase.MOVE
	_reachable_costs = combat_state.get_reachable_cell_costs(player_actor)
	_reachable_cells = _reachable_costs.keys()
	_show_reachable_highlights()
	_refresh_battle_ui()


func _resolve_enemy_turn(actor: CombatActor) -> void:
	var turn_controller := combat_state.get_turn_controller()

	# INTENT layer: the tactical AI chooses where to stand and what to attack.
	var ai := EnemyTacticalAI.new(combat_state, combat_grid)
	var plan := ai.choose_turn(actor, actor.pending_directive)
	print("[%s INT %d] %s" % [actor.display_name, actor.intelligence, plan.describe()])

	# MOTION layer: execute the plan (move -> rotate -> attack), mirroring the
	# player's CT accounting so turn order stays fair.
	var moved := plan.destination_cell != null and plan.destination_cell != actor.current_cell
	if moved:
		_apply_actor_move(actor, plan.destination_cell, _get_actor_node(actor))
	if turn_controller != null:
		if moved:
			turn_controller.finish_move()
		else:
			turn_controller.skip_move()
	combat_state.advance_ct(1)  # move/skip action used

	# Rotate to the planned facing (faces the target, or nearest enemy).
	actor.rotate_to_direction(plan.facing)
	if turn_controller != null:
		turn_controller.finish_rotate()
	combat_state.advance_ct(1)  # rotate action used

	# Attack if the plan has a target reachable from the destination cell.
	if plan.target != null and plan.target.is_alive():
		var damage := combat_state.resolve_attack(actor, plan.target, 0, plan.is_ranged)
		var arc_label := TacticalFacing.arc_label(combat_grid.get_attack_arc(actor, plan.target))
		_last_action_text = "%s strikes %s for %d (%s)!" % [actor.display_name, plan.target.display_name, damage, arc_label]
		print(_last_action_text)
		plan.target.current_ct = maxi(0, plan.target.current_ct - 15)
		combat_state.advance_ct(1)  # attack action used
	else:
		_last_action_text = "%s repositions." % actor.display_name

	if turn_controller != null:
		turn_controller.finish_act()
		combat_state.advance_ct(1)  # end of NPC actions
	actor.pending_directive = null
	combat_state.end_actor_turn()
	if weather_system:
		weather_system.roll_for_weather_change()
	_refresh_battle_ui()


func _player_move_to_cell(cell: CombatCell) -> void:
	if cell == null or not _reachable_cells.has(cell):
		return
	if cell != player_actor.current_cell:
		_apply_actor_move(player_actor, cell, _player_node)
		var move_cost := int(_reachable_costs.get(cell, 0))
		if move_cost > 0:
			_last_action_text = "Moved (%d MOV)" % move_cost
	# Action used: advance CT for all
	combat_state.advance_ct(1)
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.finish_move()
	_begin_player_rotate_phase()


## Shared move execution for any actor (player or AI). Moves the actor to
## dest_cell, animates the actor's node if it supports animate_grid_move, and
## applies the height-based CT delay. Does NOT advance CT for the action or
## touch turn-controller phases — callers own that so player/AI keep their
## own flow. No-op if dest_cell equals the actor's current cell.
func _apply_actor_move(actor: CombatActor, dest_cell: CombatCell, actor_node: Node) -> void:
	if actor == null or dest_cell == null or dest_cell == actor.current_cell:
		return
	var delta := dest_cell.grid_position - actor.get_grid_position()
	var travel_dir := _direction_key_from_delta(delta)
	var final_dir := _combat_facing_to_sprite_dir(actor.visual_facing)
	var old_h := 0
	if actor.current_cell != null:
		old_h = actor.current_cell.get_effective_height_level()
	actor.set_current_cell(dest_cell)
	if actor_node != null and actor_node.has_method("animate_grid_move"):
		actor_node.animate_grid_move(actor.global_position, travel_dir, final_dir)
	elif actor == player_actor:
		_sync_player_node_from_actor()
	# Height actions slow down CT (delays next turn) unless skill assists
	var h_delta: int = abs(dest_cell.get_effective_height_level() - old_h)
	if h_delta > 0:
		var delay: int = maxi(0, h_delta * 5 - actor.ct_height_delay_reduction)
		actor.current_ct = maxi(0, actor.current_ct - delay)


func _player_skip_move() -> void:
	if _player_phase != PlayerTurnPhase.MOVE:
		return
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.skip_move()
	_begin_player_rotate_phase()
	combat_state.advance_ct(1)  # skip still advances CT (phase used)


func _begin_player_rotate_phase() -> void:
	_player_phase = PlayerTurnPhase.ROTATE
	_battle_overlay.clear_move_preview()
	_show_rotate_highlights()
	_battle_overlay.update_rotate_preview(_build_rotate_preview())
	_refresh_battle_ui()


func _player_rotate(step: int) -> void:
	if _player_phase != PlayerTurnPhase.ROTATE:
		return
	var next_facing := TacticalFacing.rotate_direction(player_actor.get_tactical_facing(), step)
	player_actor.rotate_to_direction(next_facing)
	_sync_player_node_from_actor()
	_show_rotate_highlights()
	_battle_overlay.update_rotate_preview(_build_rotate_preview())
	_refresh_battle_ui()
	combat_state.advance_ct(1)  # rotate action advances CT


func _player_confirm_rotate() -> void:
	if _player_phase != PlayerTurnPhase.ROTATE:
		return
	_battle_overlay.clear_rotate_preview()
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.finish_rotate()
	_begin_player_attack_phase()


func _player_skip_rotate() -> void:
	if _player_phase != PlayerTurnPhase.ROTATE:
		return
	_battle_overlay.clear_rotate_preview()
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.skip_rotate()
	_begin_player_attack_phase()
	combat_state.advance_ct(1)  # skip phase advances CT


func _begin_player_attack_phase() -> void:
	_player_phase = PlayerTurnPhase.ATTACK
	_clear_facing_indicator()
	var attack_range := 5 if _use_ranged_attack else 1
	var is_ranged := _use_ranged_attack
	_attackable_targets = combat_state.get_attackable_targets(player_actor, attack_range, is_ranged)
	var target_cells: Array = []
	for target in _attackable_targets:
		if target.current_cell != null:
			target_cells.append(target.current_cell)
	var target_color := Color(0.95, 0.45, 0.1, 0.5) if _use_ranged_attack else Color(0.95, 0.2, 0.15, 0.5)
	_show_cell_highlights(target_cells, target_color)
	_refresh_battle_ui()


func _player_attack(target: CombatActor) -> void:
	if not _attackable_targets.has(target):
		return
	var is_ranged := _use_ranged_attack
	var damage := combat_state.resolve_attack(player_actor, target, 0, is_ranged)
	var arc_label := TacticalFacing.arc_label(combat_grid.get_attack_arc(player_actor, target))
	var cover_label := ""
	if is_ranged and player_actor.current_cell != null and target.current_cell != null:
		cover_label = combat_grid.get_directional_cover_description(player_actor.current_cell, target.current_cell)
	var attack_verb := "shoots" if is_ranged else "strikes"
	if cover_label != "" and cover_label != "No Cover":
		_last_action_text = "%s %s %s for %d (%s, %s)!" % [
			player_actor.display_name,
			attack_verb,
			target.display_name,
			damage,
			arc_label,
			cover_label,
		]
	else:
		_last_action_text = "%s %s %s for %d (%s)!" % [
			player_actor.display_name,
			attack_verb,
			target.display_name,
			damage,
			arc_label,
		]
	print(_last_action_text)
	# Example: action affects CT (e.g. attack delays next turn)
	target.current_ct = max(0, target.current_ct - 15)
	# Example: skill/spell to speed up own CT (boost turn speed)
	player_actor.current_ct = min(200, player_actor.current_ct + 25)
	combat_state.advance_ct(1)  # attack used
	_use_ranged_attack = false
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.finish_act()
	_finish_player_turn()


func _player_skip_attack() -> void:
	if _player_phase != PlayerTurnPhase.ATTACK:
		return
	_last_action_text = "%s waits." % player_actor.display_name
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.finish_act()
	_finish_player_turn()


func _finish_player_turn() -> void:
	_clear_highlights()
	_clear_facing_indicator()
	_battle_overlay.clear_move_preview()
	_battle_overlay.clear_rotate_preview()
	_player_phase = PlayerTurnPhase.INACTIVE
	combat_state.end_actor_turn()
	if weather_system:
		weather_system.roll_for_weather_change()
	_refresh_battle_ui()


func _is_player_combat_turn() -> bool:
	return (
		_combat_active
		and combat_state.phase == CombatState.Phase.ACTOR_TURN
		and combat_state.active_actor == player_actor
	)


func _is_exploration_grid_mode() -> bool:
	return not _combat_active or not _is_player_combat_turn()


func _is_grid_move_action_pressed(event: InputEvent) -> bool:
	if not event.is_pressed() or event.is_echo():
		return false
	return (
		event.is_action_pressed("move_left")
		or event.is_action_pressed("move_right")
		or event.is_action_pressed("move_up")
		or event.is_action_pressed("move_down")
	)


func _get_neighbor_cell_from_move_input() -> CombatCell:
	if player_actor == null or player_actor.current_cell == null or combat_grid == null:
		return null

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length_squared() < 0.1:
		return null

	var offset := Vector2i(int(round(input_dir.x)), int(round(input_dir.y)))
	if offset == Vector2i.ZERO:
		return null

	if not combat_grid.allow_diagonal_movement and offset.x != 0 and offset.y != 0:
		if absf(input_dir.x) >= absf(input_dir.y):
			offset.y = 0
		else:
			offset.x = 0

	return combat_grid.get_cell(player_actor.get_grid_position() + offset)


func _handle_grid_direction_move() -> bool:
	if combat_grid == null:
		return false
	var neighbor := _get_neighbor_cell_from_move_input()
	if neighbor == null:
		return false

	if _is_player_combat_turn() and _player_phase == PlayerTurnPhase.MOVE:
		if not _reachable_cells.has(neighbor):
			return false
		_player_move_to_cell(neighbor)
		return true

	if not _is_player_combat_turn():
		return _exploration_move_to_cell(neighbor)

	return false


func _handle_mouse_click() -> bool:
	if combat_grid == null:
		return false
	var cell := _get_cell_under_mouse()
	if cell == null:
		return false

	if _is_player_combat_turn():
		if _player_phase == PlayerTurnPhase.MOVE:
			if _reachable_cells.has(cell):
				_player_move_to_cell(cell)
				return true
		elif _player_phase == PlayerTurnPhase.ROTATE:
			_player_confirm_rotate()
			return true
		elif _player_phase == PlayerTurnPhase.ATTACK:
			var occupant := cell.get_occupant()
			if occupant is CombatActor and _attackable_targets.has(occupant):
				_player_attack(occupant as CombatActor)
				return true
		return false

	if _exploration_move_to_cell(cell):
		return true
	return false


func _exploration_move_to_cell(cell: CombatCell) -> bool:
	if cell == null or player_actor == null:
		return false
	if not _exploration_reachable_costs.has(cell):
		return false
	if cell == player_actor.current_cell:
		return false

	var delta := cell.grid_position - player_actor.get_grid_position()
	var travel_dir := _direction_key_from_delta(delta)
	player_actor.set_current_cell(cell)
	player_actor.face_cell(cell)
	var target_pos := player_actor.global_position
	var final_dir := _combat_facing_to_sprite_dir(player_actor.visual_facing)
	if _player_node != null and _player_node.has_method("animate_grid_move"):
		_player_node.animate_grid_move(target_pos, travel_dir, final_dir)
	else:
		_sync_player_node_from_actor()
	_refresh_exploration_reachability()
	_show_exploration_reachability()
	return true


func _refresh_exploration_reachability() -> void:
	if player_actor == null or combat_state == null:
		_exploration_reachable_costs = {}
		return
	_exploration_reachable_costs = combat_state.get_reachable_cell_costs(player_actor)


func _show_exploration_reachability() -> void:
	if _is_player_combat_turn():
		return
	_clear_highlights()
	var tile_size := grid_cell_size * 0.88
	for cell in _exploration_reachable_costs.keys():
		if cell == null or cell == player_actor.current_cell:
			continue
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.25, 0.7, 0.45, 0.22)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(tile_size, 0.04, tile_size)
		marker.mesh = mesh
		marker.material_override = material
		var world_pos := _cell_world_position(cell)
		marker.position = world_pos + Vector3(0.0, 0.05, 0.0)
		_highlight_root.add_child(marker)


func _get_cell_under_mouse() -> CombatCell:
	if combat_grid == null:
		return null
	var ground_pos := _mouse_to_ground_position()
	if ground_pos == Vector3.INF:
		return null
	var coord := combat_grid.world_to_grid(ground_pos)
	return combat_grid.get_cell(coord)


func _update_grid_cursor() -> void:
	if _grid_cursor == null or combat_grid == null:
		return

	_hovered_cell = _get_cell_under_mouse()
	if _hovered_cell == null:
		_grid_cursor.visible = false
		if _player_phase == PlayerTurnPhase.MOVE:
			_battle_overlay.clear_move_preview()
		return

	_grid_cursor.visible = true
	var world_pos := _cell_world_position(_hovered_cell)
	_grid_cursor.position = world_pos + Vector3(0.0, 0.08, 0.0)

	var material := _grid_cursor.material_override as StandardMaterial3D
	if material == null:
		return

	if _is_player_combat_turn():
		match _player_phase:
			PlayerTurnPhase.MOVE:
				material.albedo_color = (
					Color(0.2, 0.55, 1.0, 0.65)
					if _reachable_cells.has(_hovered_cell)
					else Color(0.9, 0.2, 0.2, 0.45)
				)
				if _hovered_cell == player_actor.current_cell:
					_battle_overlay.clear_move_preview()
				elif _reachable_cells.has(_hovered_cell):
					_battle_overlay.update_move_preview(_build_move_preview(_hovered_cell))
				else:
					_battle_overlay.update_move_preview({"reachable": false})
			PlayerTurnPhase.ATTACK:
				var occupant := _hovered_cell.get_occupant()
				material.albedo_color = (
					Color(0.95, 0.25, 0.15, 0.65)
					if occupant is CombatActor and _attackable_targets.has(occupant)
					else Color(0.9, 0.2, 0.2, 0.45)
				)
			_:
				material.albedo_color = Color(0.95, 0.85, 0.2, 0.55)
	elif _exploration_reachable_costs.has(_hovered_cell):
		material.albedo_color = Color(0.35, 0.95, 0.55, 0.6)
	elif _hovered_cell.walkable and not _hovered_cell.is_occupied():
		material.albedo_color = Color(0.95, 0.95, 1.0, 0.4)
	else:
		material.albedo_color = Color(0.95, 0.25, 0.2, 0.45)


func _hypothetical_melee_reachable(from_cell: CombatCell, target: CombatActor) -> bool:
	if from_cell == null or target == null or target.current_cell == null:
		return false
	var delta := from_cell.grid_position - target.current_cell.grid_position
	var dist: int = maxi(abs(delta.x), abs(delta.y))
	var h_delta: int = abs(from_cell.get_effective_height_level() - target.current_cell.get_effective_height_level())
	return dist <= 1 and h_delta <= player_actor.jump


func _hypothetical_ranged_reachable(from_cell: CombatCell, target: CombatActor) -> bool:
	if from_cell == null or target == null or target.current_cell == null or combat_grid == null:
		return false
	var delta := from_cell.grid_position - target.current_cell.grid_position
	var dist: int = maxi(abs(delta.x), abs(delta.y))
	if dist > 5:
		return false
	return combat_grid.is_grid_line_of_sight_clear(from_cell, target.current_cell, true)


func _arc_label_from_int(arc: int) -> String:
	match arc:
		TacticalFacing.AttackArc.BACK:
			return "back"
		TacticalFacing.AttackArc.LEFT_FLANK:
			return "left flank"
		TacticalFacing.AttackArc.RIGHT_FLANK:
			return "right flank"
		_:
			return "front"


func _show_rotate_highlights() -> void:
	_clear_highlights()
	_show_facing_indicator()
	if player_actor == null or player_actor.current_cell == null or combat_grid == null:
		return
	var tile_size := grid_cell_size * 0.88
	for actor in combat_state.actors:
		if actor == null or actor == player_actor or not actor.is_alive() or actor.current_cell == null:
			continue
		var delta := actor.current_cell.grid_position - player_actor.current_cell.grid_position
		var arc := TacticalFacing.classify_attack_arc(player_actor.get_tactical_facing(), delta)
		var color: Color
		match arc:
			TacticalFacing.AttackArc.BACK:
				color = Color(0.55, 0.15, 0.85, 0.45)
			TacticalFacing.AttackArc.LEFT_FLANK, TacticalFacing.AttackArc.RIGHT_FLANK:
				color = Color(0.95, 0.75, 0.15, 0.45)
			_:
				color = Color(0.9, 0.25, 0.15, 0.45)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(tile_size, 0.05, tile_size)
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var marker := MeshInstance3D.new()
		marker.mesh = mesh
		marker.material_override = material
		marker.position = _cell_world_position(actor.current_cell) + Vector3(0.0, 0.07, 0.0)
		_highlight_root.add_child(marker)


func _build_rotate_preview() -> Dictionary:
	var targets: Array = []
	if player_actor == null:
		return {"facing": "south", "targets": targets}
	for actor in combat_state.actors:
		if actor == null or actor == player_actor or not actor.is_alive() or actor.current_cell == null:
			continue
		var delta := actor.current_cell.grid_position - player_actor.current_cell.grid_position
		var arc := TacticalFacing.classify_attack_arc(player_actor.get_tactical_facing(), delta)
		var arc_label := _arc_label_from_int(arc)
		var bonus := 0
		match arc:
			TacticalFacing.AttackArc.BACK:
				bonus = 20
			TacticalFacing.AttackArc.LEFT_FLANK, TacticalFacing.AttackArc.RIGHT_FLANK:
				bonus = 10
		targets.append({"name": actor.display_name, "arc_label": arc_label, "arc_bonus": bonus})
	return {"facing": player_actor.visual_facing, "targets": targets}


func _build_move_preview(cell: CombatCell) -> Dictionary:
	var move_cost := int(_reachable_costs.get(cell, 0))
	var targets: Array = []
	for actor in combat_state.actors:
		if actor == null or actor == player_actor or not actor.is_alive() or actor.current_cell == null:
			continue
		if actor.faction == player_actor.faction:
			continue
		var melee := _hypothetical_melee_reachable(cell, actor)
		var ranged := _hypothetical_ranged_reachable(cell, actor)
		var arc_label := ""
		if melee:
			var delta := cell.grid_position - actor.current_cell.grid_position
			var arc := TacticalFacing.classify_attack_arc(actor.get_tactical_facing(), delta)
			arc_label = _arc_label_from_int(arc)
		targets.append({
			"name": actor.display_name,
			"melee": melee,
			"ranged": ranged and not melee,
			"arc_label": arc_label,
		})
	return {"reachable": true, "move_cost": move_cost, "targets": targets}


func _mouse_to_ground_position() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3.INF

	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var plane_y := grid_origin.y + 0.05
	if is_zero_approx(ray_dir.y):
		return Vector3.INF

	var t := (plane_y - ray_origin.y) / ray_dir.y
	if t < 0.0:
		return Vector3.INF
	return ray_origin + ray_dir * t


func _cell_world_position(cell: CombatCell) -> Vector3:
	return combat_grid.grid_to_world(cell.grid_position, cell.get_effective_height_level())


func _show_reachable_highlights() -> void:
	_clear_highlights()
	var tile_size := grid_cell_size * 0.88
	for cell in _reachable_cells:
		if cell == null:
			continue
		var move_cost := int(_reachable_costs.get(cell, 0))
		var material := StandardMaterial3D.new()
		if move_cost >= 4:
			material.albedo_color = Color(0.85, 0.35, 0.1, 0.55)
		elif move_cost >= 2:
			material.albedo_color = Color(0.15, 0.45, 0.95, 0.5)
		else:
			material.albedo_color = Color(0.2, 0.55, 1.0, 0.45)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(tile_size, 0.05, tile_size)
		marker.mesh = mesh
		marker.material_override = material
		var world_pos := _cell_world_position(cell)
		marker.position = world_pos + Vector3(0.0, 0.06, 0.0)
		_highlight_root.add_child(marker)

		if move_cost > 0 and cell != player_actor.current_cell:
			var cost_label := Label3D.new()
			cost_label.text = str(move_cost)
			cost_label.font_size = 22
			cost_label.outline_size = 5
			cost_label.outline_modulate = Color(0, 0, 0, 1)
			cost_label.position = world_pos + Vector3(0.0, 0.35, 0.0)
			_highlight_root.add_child(cost_label)


func _show_cell_highlights(cells: Array, color: Color) -> void:
	_clear_highlights()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var tile_size := grid_cell_size * 0.88
	for cell in cells:
		if cell == null:
			continue
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(tile_size, 0.05, tile_size)
		marker.mesh = mesh
		marker.material_override = material
		var world_pos := _cell_world_position(cell)
		marker.position = world_pos + Vector3(0.0, 0.06, 0.0)
		_highlight_root.add_child(marker)


func _create_cover_indicators() -> void:
	if combat_grid == null or _highlight_root == null:
		return
	var tile_size := grid_cell_size * 0.94
	for cell in combat_grid.cells.values():
		if cell.cover_level == CombatCell.CoverLevel.NONE:
			continue
		var color: Color
		if cell.cover_level == CombatCell.CoverLevel.FULL:
			color = Color(0.28, 0.38, 0.62, 0.45)
		else:
			color = Color(0.75, 0.58, 0.18, 0.35)
		var mesh := BoxMesh.new()
		mesh.size = Vector3(tile_size, 0.02, tile_size)
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var marker := MeshInstance3D.new()
		marker.mesh = mesh
		marker.material_override = material
		marker.position = _cell_world_position(cell) + Vector3(0.0, 0.03, 0.0)
		marker.add_to_group("cover_indicator")
		_highlight_root.add_child(marker)


func _clear_highlights() -> void:
	if _highlight_root == null:
		return
	for child in _highlight_root.get_children():
		if child == _facing_indicator or child == _grid_cursor:
			continue
		if child.is_in_group("cover_indicator"):
			continue
		child.queue_free()


func _clear_facing_indicator() -> void:
	if _facing_indicator != null:
		_facing_indicator.queue_free()
		_facing_indicator = null


func _show_facing_indicator() -> void:
	_clear_facing_indicator()
	if player_actor == null or player_actor.current_cell == null:
		return

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.85, 0.2, 0.75)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var mesh := BoxMesh.new()
	mesh.size = Vector3(grid_cell_size * 0.35, 0.06, grid_cell_size * 0.55)
	_facing_indicator = MeshInstance3D.new()
	_facing_indicator.name = "FacingIndicator"
	_facing_indicator.mesh = mesh
	_facing_indicator.material_override = material

	var world_pos := _cell_world_position(player_actor.current_cell)
	_facing_indicator.position = world_pos + Vector3(0.0, 0.1, 0.0)
	_facing_indicator.rotation.y = TacticalFacing.yaw_radians(player_actor.get_tactical_facing())
	_highlight_root.add_child(_facing_indicator)


## Returns the separate visual node that animates an actor's movement, or null
## if the actor moves via its own transform (enemies carry their marker as a
## child, so set_current_cell already moves them).
func _get_actor_node(actor: CombatActor) -> Node:
	if actor == player_actor:
		return _player_node
	return null


func _sync_player_node_from_actor() -> void:
	if _player_node == null or player_actor == null:
		return
	_player_node.global_position = player_actor.global_position
	if _player_node.has_method("set_combat_facing"):
		_player_node.set_combat_facing(_combat_facing_to_sprite_dir(player_actor.visual_facing))


func _combat_facing_to_sprite_dir(visual_facing: String) -> String:
	match visual_facing:
		"north", "north_west", "north_east":
			return "north"
		"south", "south_west", "south_east":
			return "south"
		"east":
			return "east"
		"west":
			return "west"
	return "south"


func _direction_key_from_delta(delta: Vector2i) -> String:
	# Map grid delta to one of the 4 sprite dirs (for walk animation).
	if delta == Vector2i.ZERO:
		return "south"
	if abs(delta.x) >= abs(delta.y):
		return "east" if delta.x > 0 else "west"
	else:
		return "south" if delta.y > 0 else "north"


func _on_encounter_ended(result_phase: int) -> void:
	_combat_active = false
	_player_phase = PlayerTurnPhase.INACTIVE
	_clear_highlights()
	_battle_overlay.clear_move_preview()
	_battle_overlay.clear_rotate_preview()
	_battle_overlay.clear_target_preview()
	if _player_node != null:
		_player_node.movement_enabled = true
		_player_node.grid_movement_only = false  # allow free movement again after combat
	# Reset CT so gauge does not stay filled / count while idle/exploring after combat
	if player_actor:
		player_actor.current_ct = 0
		player_actor.ct_gain_multiplier = 1.0
		player_actor.ct_gain_flat = 0
		player_actor.active_status_effects.clear()
	if monster_actor:
		monster_actor.current_ct = 0
		monster_actor.ct_gain_multiplier = 1.0
		monster_actor.ct_gain_flat = 0
		monster_actor.active_status_effects.clear()
	_refresh_exploration_reachability()
	if combat_grid != null:
		_show_exploration_reachability()

	var result_text := "Combat ended."
	match result_phase:
		CombatState.Phase.VICTORY:
			result_text = "Victory!"
		CombatState.Phase.DEFEAT:
			result_text = "Defeat..."

	if _battle_overlay != null:
		_battle_overlay.clear_target_preview()
		_battle_overlay.update_display({
			"round": combat_state.round,
			"active_actor_name": result_text,
			"player_phase": -1,
			"player_name": player_actor.display_name if player_actor != null else "Player",
			"enemy_name": monster_actor.display_name if monster_actor != null else "Enemy",
			"player_hp": player_actor.current_hp if player_actor != null else 0,
			"player_max_hp": _get_actor_max_hp(player_actor),
			"enemy_hp": monster_actor.current_hp if monster_actor != null else 0,
			"enemy_max_hp": _get_actor_max_hp(monster_actor),
			"player_ct": player_actor.current_ct if player_actor != null else 0,
			"enemy_ct": monster_actor.current_ct if monster_actor != null else 0,
			"ct_threshold": combat_state.get_ct_threshold(),
			"player_mov": player_actor.movement if player_actor != null else 0,
			"player_facing": player_actor.visual_facing if player_actor != null else "south",
			"hint": result_text,
			"last_action": result_text,
		})
	print(result_text)


func _refresh_battle_ui() -> void:
	if _battle_overlay == null:
		return

	if not _encounter_started:
		_battle_overlay.show_pre_combat("Walk around freely. Approach the Training Brigand to engage in tactical combat (grid + turns start on contact).")
		# Ensure CT does not count up while exploring / idle
		if player_actor:
			player_actor.current_ct = 0
			player_actor.ct_gain_multiplier = 1.0
			player_actor.ct_gain_flat = 0
			player_actor.active_status_effects.clear()
		if monster_actor:
			monster_actor.current_ct = 0
			monster_actor.ct_gain_multiplier = 1.0
			monster_actor.ct_gain_flat = 0
			monster_actor.active_status_effects.clear()
		return

	if not _combat_active:
		if player_actor:
			player_actor.current_ct = 0
			player_actor.ct_gain_multiplier = 1.0
			player_actor.ct_gain_flat = 0
			player_actor.active_status_effects.clear()
		if monster_actor:
			monster_actor.current_ct = 0
			monster_actor.ct_gain_multiplier = 1.0
			monster_actor.ct_gain_flat = 0
			monster_actor.active_status_effects.clear()

	var active_name := "CT filling"
	if combat_state.active_actor != null:
		active_name = combat_state.active_actor.display_name
	if weather_system:
		active_name += " | " + weather_system.get_description()

	var hint := ""
	if _combat_active and combat_state.active_actor == player_actor:
		match _player_phase:
			PlayerTurnPhase.MOVE:
				hint = "[b]Move[/b] — Click a cell or use [b]arrows / WASD[/b]. Numbers show MOV cost.\nOrange tiles cost more (height). [b]Enter[/b] skips move."
			PlayerTurnPhase.ROTATE:
				hint = "[b]Rotate[/b] — [b]Q/E[/b] turn facing. Click or [b]Enter[/b] confirms. Yellow wedge shows facing."
			PlayerTurnPhase.ATTACK:
				var mode := "RANGED" if _use_ranged_attack else "MELEE"
				hint = "[b]Attack (%s)[/b] — Click an enemy. [b]R[/b] toggles ranged. Hover for flank/cover preview. [b]Enter[/b] waits." % mode
	elif _combat_active:
		hint = "Enemy is acting..."
	elif not _encounter_started:
		hint = "Walk around with normal controls. Get close to an enemy to start tactical grid combat."
	else:
		hint = "Encounter ended."

	_battle_overlay.update_display({
		"round": combat_state.round,
		"active_actor_name": active_name,
		"player_phase": _player_phase_to_overlay_index(),
		"use_ranged": _use_ranged_attack,
		"player_name": player_actor.display_name if player_actor != null else "Player",
		"enemy_name": monster_actor.display_name if monster_actor != null else "Enemy",
		"player_hp": player_actor.current_hp if player_actor != null else 0,
		"player_max_hp": _get_actor_max_hp(player_actor),
		"enemy_hp": monster_actor.current_hp if monster_actor != null else 0,
		"enemy_max_hp": _get_actor_max_hp(monster_actor),
		"player_ct": (player_actor.current_ct if _combat_active else 0) if player_actor != null else 0,
		"enemy_ct": (monster_actor.current_ct if _combat_active else 0) if monster_actor != null else 0,
		"ct_threshold": combat_state.get_ct_threshold(),
		"player_mov": player_actor.movement if player_actor != null else 0,
		"player_facing": player_actor.visual_facing if player_actor != null else "south",
		"hint": hint,
		"last_action": _last_action_text,
	})


func _player_phase_to_overlay_index() -> int:
	match _player_phase:
		PlayerTurnPhase.MOVE:
			return 0
		PlayerTurnPhase.ROTATE:
			return 1
		PlayerTurnPhase.ATTACK:
			return 2
	return -1


func _get_actor_max_hp(actor: CombatActor) -> int:
	if actor == null:
		return 1
	if actor.sheet_resource != null and actor.sheet_resource.has_method("get_max_hp"):
		return maxi(1, actor.sheet_resource.get_max_hp())
	return maxi(1, actor.current_hp)


func _grid_to_world(coord: Vector2i) -> Vector3:
	# Compute world position from grid coord using the map's grid params.
	# Used for early positioning (e.g. distance trigger) before the CombatGrid is built.
	var y = grid_origin.y
	var half := Vector3(grid_cell_size * 0.5, 0.0, grid_cell_size * 0.5)
	return grid_origin + Vector3(coord.x * grid_cell_size, y, coord.y * grid_cell_size) + half


func _update_attack_preview() -> void:
	if _battle_overlay == null:
		return
	# Only this function owns the shared preview panel during ATTACK phase.
	# In other phases the move/rotate preview owns it, so do NOT clear here
	# or we clobber their panel every frame.
	if _player_phase != PlayerTurnPhase.ATTACK or not _combat_active:
		if _player_phase == PlayerTurnPhase.ATTACK:
			_battle_overlay.clear_target_preview()
		return

	var target := _get_hovered_attack_target()
	if target == null:
		_battle_overlay.clear_target_preview()
		return

	var is_ranged := _use_ranged_attack
	var arc_label := TacticalFacing.arc_label(combat_grid.get_attack_arc(player_actor, target))
	var cover_label := "No Cover"
	var height_delta := 0
	if player_actor.current_cell != null and target.current_cell != null:
		if is_ranged:
			cover_label = combat_grid.get_directional_cover_description(player_actor.current_cell, target.current_cell)
			height_delta = (
				player_actor.current_cell.get_effective_height_level()
				- target.current_cell.get_effective_height_level()
			)
	var predicted_damage := combat_state.calculate_damage(player_actor, target, 0, is_ranged)

	_battle_overlay.update_target_preview({
		"target_name": target.display_name,
		"arc_label": arc_label,
		"cover_label": cover_label,
		"height_delta": height_delta,
		"is_ranged": is_ranged,
		"predicted_damage": predicted_damage,
	})


func _get_hovered_attack_target() -> CombatActor:
	var ground_pos := _mouse_to_ground_position()
	if ground_pos == Vector3.INF:
		return null
	var coord := combat_grid.world_to_grid(ground_pos)
	var cell := combat_grid.get_cell(coord)
	if cell == null:
		return null
	var occupant := cell.get_occupant()
	if occupant is CombatActor and _attackable_targets.has(occupant):
		return occupant as CombatActor
	return null