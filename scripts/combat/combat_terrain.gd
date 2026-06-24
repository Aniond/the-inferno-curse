extends Node3D
class_name CombatTerrain

@export var terrain_id: String = ""
@export var block_movement: bool = true
@export var cover_level: int = 2
@export var height_level: int = 0
@export var is_obstruction: bool = true
@export var blocks_line_of_sight: bool = true
@export_range(1, 99) var movement_cost: int = 1
@export var damage_on_enter: int = 0
@export var duration_rounds: int = 0
@export var owner_actor_id: String = ""
@export var source_ability_id: String = ""
@export var terrain_tags: Array[String] = []

func get_cover_bonus() -> int:
	match cover_level:
		0:
			return 0
		1:
			return 12
		2:
			return 26
		_:
			return 0

func get_blocking_cost() -> int:
	if block_movement:
		return 999
	return movement_cost

func get_description() -> String:
	var parts: Array[String] = []
	parts.append("Terrain: %s" % terrain_id)
	parts.append("Blocks movement" if block_movement else "Passable")
	if is_obstruction:
		parts.append("Obstruction")
	if blocks_line_of_sight:
		parts.append("Blocks sight")
	if duration_rounds > 0:
		parts.append("%d rounds" % duration_rounds)
	return ", ".join(parts)
