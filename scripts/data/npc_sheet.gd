extends Resource
class_name NpcSheet

const CoreStatsResource := preload("res://scripts/data/core_stats.gd")

@export var npc_id: String = ""
@export var display_name: String = ""
@export var role: String = ""
@export var faction: String = ""
@export_range(1, 99) var level: int = 1

@export var core_stats: Resource = CoreStatsResource.new()
@export var portrait_path: String = ""
@export var sprite_scene_path: String = ""
@export var home_node: String = ""
@export var dialogue_tags: Array[String] = []
@export var services: Array[String] = []

@export var can_join_battle: bool = false
@export_range(1, 9999) var max_hp: int = 30
@export_range(0, 9999) var max_mp: int = 0
@export_enum("STR", "SPD", "INT", "FTH", "CRT", "PRS") var power_stat: String = "PRS"
@export_range(0, 999) var equipment_power: int = 0
@export_range(0, 999) var equipment_defense: int = 0
@export var abilities: Array[String] = []


func get_power() -> int:
	if not can_join_battle:
		return 0
	return core_stats.calculate_power(power_stat, level, equipment_power)


func get_defense() -> int:
	if not can_join_battle:
		return 0
	return core_stats.calculate_defense(level, equipment_defense)


func get_summary() -> String:
	if can_join_battle:
		return "%s Lv.%d %s | HP %d | POW %d | DEF %d" % [
			display_name,
			level,
			role,
			max_hp,
			get_power(),
			get_defense(),
		]

	return "%s Lv.%d %s | Services %d | Home %s" % [
		display_name,
		level,
		role,
		services.size(),
		home_node,
	]
