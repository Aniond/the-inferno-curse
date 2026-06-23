extends CombatTerrain
class_name CoverVolume

@export_enum("north", "north_east", "east", "south_east", "south", "south_west", "west", "north_west") var cover_facing: String = "south"
@export_range(90.0, 360.0) var coverage_arc: float = 180.0
@export var grid_position: Vector2i = Vector2i.ZERO

func _init() -> void:
	block_movement = false
	is_obstruction = false
	blocks_line_of_sight = false
	cover_level = 1
	terrain_id = "cover_volume"


func get_cover_direction() -> int:
	return TacticalFacing.direction_from_visual(cover_facing)


func protects_against_attack(from_cell: CombatCell, to_cell: CombatCell) -> bool:
	if from_cell == null or to_cell == null:
		return false

	var incoming := from_cell.grid_position - grid_position
	if incoming == Vector2i.ZERO:
		return false

	var attack_dir := TacticalFacing.direction_from_vector(incoming)
	var cover_dir := get_cover_direction()
	var attack_angle := TacticalFacing.angle_degrees(attack_dir)
	var cover_angle := TacticalFacing.angle_degrees(cover_dir)
	var diff := absf(fposmod(attack_angle - cover_angle + 180.0, 360.0) - 180.0)
	return diff <= coverage_arc * 0.5


func blocks_attack_line_of_sight(from_cell: CombatCell, to_cell: CombatCell) -> bool:
	if not blocks_line_of_sight:
		return false
	return protects_against_attack(from_cell, to_cell)


func get_cover_label() -> String:
	match cover_level:
		1:
			return "Half Cover"
		2:
			return "Full Cover"
		_:
			return "No Cover"