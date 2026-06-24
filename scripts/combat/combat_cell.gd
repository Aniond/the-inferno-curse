extends RefCounted
class_name CombatCell

enum CoverLevel {
	NONE = 0,
	HALF = 1,
	FULL = 2,
}

@export var grid_position: Vector2i = Vector2i.ZERO
@export var world_position: Vector3 = Vector3.ZERO
@export var height_level: int = 0
@export var walkable: bool = true
@export var cover_level: int = CoverLevel.NONE
@export var obstruction: bool = false
@export var blocks_line_of_sight: bool = false
@export_range(1, 99) var movement_cost: int = 1
@export var terrain_height_delta: int = 0
@export var terrain_tags: Array[String] = []
@export var temporary_effect_ids: Array[String] = []

var _occupant: Node = null

func is_occupied() -> bool:
	return _occupant != null


func is_occupied_by(actor: Node) -> bool:
	return _occupant == actor


func set_occupant(actor: Node) -> void:
	_occupant = actor


func clear_occupant(actor: Node = null) -> void:
	if actor == null or _occupant == actor:
		_occupant = null


func get_occupant() -> Node:
	return _occupant


func get_effective_height_level() -> int:
	return height_level + terrain_height_delta


func blocks_ranged_line_of_sight() -> bool:
	return blocks_line_of_sight or obstruction or cover_level == CoverLevel.FULL


func get_cover_bonus() -> int:
	match cover_level:
		CoverLevel.HALF:
			return 12
		CoverLevel.FULL:
			return 26
		_:
			return 0

func get_cover_label() -> String:
	match cover_level:
		CoverLevel.HALF:
			return "Half Cover"
		CoverLevel.FULL:
			return "Full Cover"
		_:
			return "No Cover"
