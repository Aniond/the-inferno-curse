extends Node3D
class_name CombatActor

@export var actor_id: String = ""
@export var display_name: String = ""
@export var faction: String = "neutral"
@export var actor_type: String = "unit"
@export var sheet_resource: Resource
@export var starting_grid_position: Vector2i = Vector2i.ZERO
@export var starting_height_level: int = 0
@export_enum("north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west") var visual_facing: String = "south"

var current_hp: int = 1
var current_mp: int = 0
var current_ct: int = 0
var movement: int = 0
var jump: int = 0
var speed: int = 0
var power: int = 0
var defense: int = 0
var cover_bonus: int = 0
var current_cell: CombatCell = null
var jump_cost_reduction: int = 0
var jump_cost_multiplier: float = 1.0
var ignore_first_height_level: bool = false
var downhill_free: bool = false
var ct_gain_multiplier: float = 1.0
var ct_gain_flat: int = 0
var active_status_effects: Dictionary = {}
var ct_height_delay_reduction: int = 0  # skills can reduce height CT cost
var intelligence: int = 5  # tactical AI sophistication (1-10), synced from sheet
var pending_directive: AiDirective = null  # written by EnemyCommander each round

func _ready() -> void:
	_sync_stats()

func _sync_stats() -> void:
	if sheet_resource == null:
		return

	if sheet_resource.has_method("get_max_hp"):
		current_hp = sheet_resource.get_max_hp()
	if sheet_resource.has_method("get_max_mp"):
		current_mp = sheet_resource.get_max_mp()
	if sheet_resource.has_method("get_starting_ct"):
		current_ct = sheet_resource.get_starting_ct()
	if sheet_resource.has_method("get_movement"):
		movement = sheet_resource.get_movement()
	if sheet_resource.has_method("get_jump"):
		jump = sheet_resource.get_jump()
	if sheet_resource.has_method("get_speed"):
		speed = sheet_resource.get_speed()
	if sheet_resource.has_method("get_power"):
		power = sheet_resource.get_power()
	if sheet_resource.has_method("get_defense"):
		defense = sheet_resource.get_defense()
	if sheet_resource.has_method("get_intelligence"):
		intelligence = sheet_resource.get_intelligence()

	cover_bonus = 0

func set_current_cell(cell: CombatCell) -> void:
	if current_cell != null and current_cell.is_occupied_by(self):
		current_cell.clear_occupant(self)

	current_cell = cell
	if current_cell != null:
		current_cell.set_occupant(self)
		global_position = current_cell.world_position

func is_alive() -> bool:
	return current_hp > 0

func get_attack_power() -> int:
	return power

func get_defense_value() -> int:
	return defense + cover_bonus

func apply_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)

func heal(amount: int) -> void:
	var max_hp: int = current_hp
	if sheet_resource != null and sheet_resource.has_method("get_max_hp"):
		max_hp = sheet_resource.get_max_hp()
	current_hp = min(current_hp + amount, max_hp)

func get_grid_position() -> Vector2i:
	if current_cell != null:
		return current_cell.grid_position
	return starting_grid_position

func get_world_position() -> Vector3:
	if current_cell != null:
		return current_cell.world_position
	return global_position

func get_tactical_facing() -> int:
	return TacticalFacing.direction_from_visual(visual_facing)

func get_facing_vector() -> Vector2i:
	return TacticalFacing.vector_from_direction(get_tactical_facing())

func set_tactical_facing(direction: int) -> void:
	visual_facing = TacticalFacing.visual_from_direction(direction)

func rotate_to_direction(direction: int) -> void:
	set_tactical_facing(direction)

func set_visual_facing_from_vector(direction: Vector2i) -> void:
	set_tactical_facing(TacticalFacing.direction_from_vector(direction))

func face_cell(cell: CombatCell) -> void:
	if cell == null:
		return
	set_visual_facing_from_vector(cell.grid_position - get_grid_position())


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
	var raw_cost := magnitude * per_level
	raw_cost = int(ceil(float(raw_cost) * jump_cost_multiplier))
	return maxi(0, raw_cost - jump_cost_reduction)


func get_step_movement_cost(from_cell: CombatCell, to_cell: CombatCell) -> int:
	if from_cell == null or to_cell == null:
		return 999

	var delta_pos := to_cell.grid_position - from_cell.grid_position
	var is_diagonal := absi(delta_pos.x) == 1 and absi(delta_pos.y) == 1
	var base_step := 2 if is_diagonal else 1
	base_step = maxi(base_step, to_cell.movement_cost)
	var height_cost := get_height_step_cost(
		from_cell.get_effective_height_level(),
		to_cell.get_effective_height_level()
	)
	var total := base_step + height_cost
	# Weather (location + dynamic/AI) can slow movement and height
	if get_parent().has_method("get_weather_mod"):  # if attached or via state
		# For now, assume combat_state or global query; in practice passed via battle map
		pass
	return total


func apply_jump_traversal_modifiers(modifiers: Dictionary) -> void:
	if modifiers.has("jump_cost_reduction"):
		jump_cost_reduction = int(modifiers["jump_cost_reduction"])
	if modifiers.has("jump_cost_multiplier"):
		jump_cost_multiplier = float(modifiers["jump_cost_multiplier"])
	if modifiers.has("ignore_first_height_level"):
		ignore_first_height_level = bool(modifiers["ignore_first_height_level"])
	if modifiers.has("downhill_free"):
		downhill_free = bool(modifiers["downhill_free"])

func apply_ct_modifiers(modifiers: Dictionary) -> void:
	if modifiers.has("ct_gain_multiplier"):
		ct_gain_multiplier *= float(modifiers["ct_gain_multiplier"])
		ct_gain_multiplier = max(0.1, ct_gain_multiplier)
	if modifiers.has("ct_gain_flat"):
		ct_gain_flat += int(modifiers["ct_gain_flat"])
	if modifiers.has("ct_height_delay_reduction"):
		ct_height_delay_reduction += int(modifiers["ct_height_delay_reduction"])

func apply_status_effect(effect_id: String, duration_rounds: int = 3, ct_modifiers: Dictionary = {}) -> void:
	active_status_effects[effect_id] = {
		"duration": duration_rounds,
		"ct_modifiers": ct_modifiers.duplicate()
	}
	if ct_modifiers:
		apply_ct_modifiers(ct_modifiers)
