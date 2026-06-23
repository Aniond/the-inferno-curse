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
@export var grid_columns: int = 12
@export var grid_rows: int = 12
@export var grid_cell_size: float = 2.0
@export var grid_origin: Vector3 = Vector3(-11.0, 0.04, -11.0)

var combat_grid: CombatGrid = null
var combat_state: CombatState = null
var player_actor: CombatActor = null
var monster_actor: CombatActor = null
var _status_label: Label3D = null
var _player_node: CharacterBody3D = null
var _encounter_started: bool = false
var _combat_active: bool = false
var _player_phase: int = PlayerTurnPhase.INACTIVE
var _reachable_cells: Array = []
var _attackable_targets: Array = []
var _last_action_text: String = ""
var _highlight_root: Node3D = null
var _facing_indicator: MeshInstance3D = null
var _tactical_ai_client: TacticalAiClient = null


func _ready() -> void:
	_create_combat_grid()
	_create_grid_visuals()
	_create_highlight_root()
	_apply_test_map_tactical_cells()
	_create_combat_state()
	_create_player_actor()
	_create_test_monster_actor()
	_create_status_label()
	_player_node = get_node_or_null("Player") as CharacterBody3D

	combat_state.actor_turn_started.connect(_on_actor_turn_started)
	combat_state.ct_updated.connect(_refresh_status_label)
	combat_state.encounter_ended.connect(_on_encounter_ended)

	_setup_tactical_ai_client()

	if start_combat_on_ready:
		_start_test_combat()
	else:
		_refresh_status_label()


func _physics_process(_delta: float) -> void:
	if _encounter_started or monster_actor == null:
		return
	if _player_node == null:
		return
	if _player_node.global_position.distance_to(monster_actor.global_position) <= encounter_trigger_radius:
		_start_test_combat()


func _unhandled_input(event: InputEvent) -> void:
	if not _combat_active or combat_state.phase != CombatState.Phase.ACTOR_TURN:
		return
	if combat_state.active_actor != player_actor:
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

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_player_click()
			get_viewport().set_input_as_handled()


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


func _make_grid_line(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var line := MeshInstance3D.new()
	line.mesh = mesh
	line.material_override = material
	return line


func _apply_test_map_tactical_cells() -> void:
	for coord in [Vector2i(2, 8), Vector2i(3, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(1, 3)]:
		var cell := combat_grid.get_cell(coord)
		if cell != null:
			cell.cover_level = CombatCell.CoverLevel.HALF
			cell.terrain_tags.append("table_cover")

	for coord in [Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1)]:
		var cell := combat_grid.get_cell(coord)
		if cell != null:
			cell.cover_level = CombatCell.CoverLevel.FULL
			cell.obstruction = true
			cell.walkable = false
			cell.blocks_line_of_sight = true
			cell.terrain_tags.append("bar_counter")

	var raised_cell := combat_grid.get_cell(Vector2i(4, 4))
	if raised_cell != null:
		raised_cell.height_level = 1
		raised_cell.terrain_tags.append("raised_floor_test")


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
	player_actor.starting_grid_position = Vector2i(3, 6)
	player_actor.visual_facing = "north"
	add_child(player_actor)
	player_actor.set_current_cell(combat_grid.get_cell(player_actor.starting_grid_position))

	if _player_node == null:
		_player_node = get_node_or_null("Player") as CharacterBody3D
	if _player_node != null:
		_player_node.global_position = player_actor.global_position


func _create_test_monster_actor() -> void:
	monster_actor = CombatActor.new()
	monster_actor.name = "TrainingBrigandCombatActor"
	monster_actor.actor_id = "training_brigand_01"
	monster_actor.display_name = "Training Brigand"
	monster_actor.faction = "enemy"
	monster_actor.sheet_resource = TEST_MONSTER_SHEET
	monster_actor.starting_grid_position = Vector2i(7, 6)
	monster_actor.visual_facing = "west"
	add_child(monster_actor)
	monster_actor.set_current_cell(combat_grid.get_cell(monster_actor.starting_grid_position))
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


func _create_status_label() -> void:
	_status_label = Label3D.new()
	_status_label.name = "CombatStatusLabel"
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 28
	_status_label.outline_size = 8
	_status_label.outline_modulate = Color(0, 0, 0, 1)
	_status_label.position = Vector3(-7.5, 2.5, -7.0)
	add_child(_status_label)


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
	_encounter_started = true
	_combat_active = true
	_last_action_text = ""

	_snap_player_to_nearest_cell()
	combat_state.start_encounter(combat_grid, [player_actor, monster_actor])
	_ping_tactical_ai()

	if _player_node != null:
		_player_node.movement_enabled = false

	_refresh_status_label()
	print("Battle started: %s vs %s" % [player_actor.display_name, monster_actor.display_name])


func _snap_player_to_nearest_cell() -> void:
	if _player_node == null or combat_grid == null or player_actor == null:
		return
	var grid_coord := combat_grid.world_to_grid(_player_node.global_position)
	var cell := combat_grid.get_cell(grid_coord)
	if cell == null or not cell.walkable or cell.is_occupied():
		cell = combat_grid.get_cell(player_actor.starting_grid_position)
	player_actor.set_current_cell(cell)
	if cell != null:
		_sync_player_node_from_actor()


func _on_actor_turn_started(actor: CombatActor) -> void:
	_clear_highlights()
	_player_phase = PlayerTurnPhase.INACTIVE
	_refresh_status_label()
	if actor == null:
		return
	if actor.faction == "enemy":
		_resolve_enemy_turn(actor)
	elif actor == player_actor:
		_begin_player_turn()


func _begin_player_turn() -> void:
	_player_phase = PlayerTurnPhase.MOVE
	_reachable_cells = combat_state.get_reachable_cells(player_actor)
	_show_cell_highlights(_reachable_cells, Color(0.2, 0.55, 1.0, 0.45))
	_refresh_status_label()


func _resolve_enemy_turn(actor: CombatActor) -> void:
	var turn_controller := combat_state.get_turn_controller()
	var targets := combat_state.get_attackable_targets(actor, 1, false)
	if not targets.is_empty():
		var target: CombatActor = targets[0]
		actor.face_cell(target.current_cell)
		if turn_controller != null:
			turn_controller.skip_move()
			turn_controller.finish_rotate()
		var damage := combat_state.resolve_attack(actor, target, 0, false)
		var arc_label := TacticalFacing.arc_label(combat_grid.get_attack_arc(actor, target))
		_last_action_text = "%s strikes %s for %d (%s)!" % [actor.display_name, target.display_name, damage, arc_label]
		print(_last_action_text)
	if turn_controller != null:
		turn_controller.finish_act()
	combat_state.end_actor_turn()
	_refresh_status_label()


func _player_move_to_cell(cell: CombatCell) -> void:
	if cell == null or not _reachable_cells.has(cell):
		return
	if cell != player_actor.current_cell:
		player_actor.set_current_cell(cell)
		_sync_player_node_from_actor()
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.finish_move()
	_begin_player_rotate_phase()


func _player_skip_move() -> void:
	if _player_phase != PlayerTurnPhase.MOVE:
		return
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.skip_move()
	_begin_player_rotate_phase()


func _begin_player_rotate_phase() -> void:
	_player_phase = PlayerTurnPhase.ROTATE
	_clear_highlights()
	_show_facing_indicator()
	_refresh_status_label()


func _player_rotate(step: int) -> void:
	if _player_phase != PlayerTurnPhase.ROTATE:
		return
	var next_facing := TacticalFacing.rotate_direction(player_actor.get_tactical_facing(), step)
	player_actor.rotate_to_direction(next_facing)
	_sync_player_node_from_actor()
	_show_facing_indicator()
	_refresh_status_label()


func _player_confirm_rotate() -> void:
	if _player_phase != PlayerTurnPhase.ROTATE:
		return
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.finish_rotate()
	_begin_player_attack_phase()


func _player_skip_rotate() -> void:
	if _player_phase != PlayerTurnPhase.ROTATE:
		return
	var turn_controller := combat_state.get_turn_controller()
	if turn_controller != null:
		turn_controller.skip_rotate()
	_begin_player_attack_phase()


func _begin_player_attack_phase() -> void:
	_player_phase = PlayerTurnPhase.ATTACK
	_clear_facing_indicator()
	_attackable_targets = combat_state.get_attackable_targets(player_actor, 1, false)
	var target_cells: Array = []
	for target in _attackable_targets:
		if target.current_cell != null:
			target_cells.append(target.current_cell)
	_show_cell_highlights(target_cells, Color(0.95, 0.2, 0.15, 0.5))
	_refresh_status_label()


func _player_attack(target: CombatActor) -> void:
	if not _attackable_targets.has(target):
		return
	var damage := combat_state.resolve_attack(player_actor, target, 0, false)
	var arc_label := TacticalFacing.arc_label(combat_grid.get_attack_arc(player_actor, target))
	_last_action_text = "%s strikes %s for %d (%s)!" % [player_actor.display_name, target.display_name, damage, arc_label]
	print(_last_action_text)
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
	_player_phase = PlayerTurnPhase.INACTIVE
	combat_state.end_actor_turn()
	_refresh_status_label()


func _handle_player_click() -> void:
	var ground_pos := _mouse_to_ground_position()
	if ground_pos == Vector3.INF:
		return
	var coord := combat_grid.world_to_grid(ground_pos)
	var cell := combat_grid.get_cell(coord)
	if cell == null:
		return

	if _player_phase == PlayerTurnPhase.MOVE:
		if _reachable_cells.has(cell):
			_player_move_to_cell(cell)
	elif _player_phase == PlayerTurnPhase.ROTATE:
		_player_confirm_rotate()
	elif _player_phase == PlayerTurnPhase.ATTACK:
		var occupant := cell.get_occupant()
		if occupant is CombatActor and _attackable_targets.has(occupant):
			_player_attack(occupant as CombatActor)


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


func _clear_highlights() -> void:
	if _highlight_root == null:
		return
	for child in _highlight_root.get_children():
		if child == _facing_indicator:
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


func _on_encounter_ended(result_phase: int) -> void:
	_combat_active = false
	_player_phase = PlayerTurnPhase.INACTIVE
	_clear_highlights()
	if _player_node != null:
		_player_node.movement_enabled = true

	var result_text := "Combat ended."
	match result_phase:
		CombatState.Phase.VICTORY:
			result_text = "Victory!"
		CombatState.Phase.DEFEAT:
			result_text = "Defeat..."

	_status_label.text = result_text
	print(result_text)


func _refresh_status_label() -> void:
	if _status_label == null:
		return

	if not _encounter_started:
		_status_label.text = "Approach the Training Brigand to start combat."
		return

	var active_name := "CT filling"
	if combat_state.active_actor != null:
		active_name = combat_state.active_actor.display_name

	var player_ct := player_actor.current_ct if player_actor != null else 0
	var monster_ct := monster_actor.current_ct if monster_actor != null else 0
	var threshold := combat_state.get_ct_threshold()
	var hint := ""
	if _combat_active and combat_state.active_actor == player_actor:
		match _player_phase:
			PlayerTurnPhase.MOVE:
				hint = "\nClick blue cell to move | Enter to skip move"
			PlayerTurnPhase.ROTATE:
				hint = "\nQ/E to rotate | Click to confirm facing | Enter to skip rotate"
			PlayerTurnPhase.ATTACK:
				hint = "\nClick red enemy to attack | Enter to skip attack"

	var action_line := ""
	if _last_action_text != "":
		action_line = "\n%s" % _last_action_text

	_status_label.text = "Round %d | Turn: %s\nCT %d/%d vs %d/%d%s%s" % [
		combat_state.round,
		active_name,
		player_ct,
		threshold,
		monster_ct,
		threshold,
		hint,
		action_line,
	]