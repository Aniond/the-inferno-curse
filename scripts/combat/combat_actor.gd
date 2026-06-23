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