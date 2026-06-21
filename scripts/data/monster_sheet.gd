extends Resource
class_name MonsterSheet

const CoreStatsResource := preload("res://scripts/data/core_stats.gd")

@export var monster_id: String = ""
@export var display_name: String = ""
@export var family: String = ""
@export_range(1, 99) var level: int = 1

@export var core_stats: Resource = CoreStatsResource.new()
@export_range(1, 9999) var max_hp: int = 30
@export_range(0, 9999) var max_mp: int = 0
@export_range(0, 999) var starting_ct: int = 0

@export_enum("STR", "SPD", "INT", "FTH", "CRT", "PRS") var power_stat: String = "STR"
@export_range(0, 999) var natural_power: int = 0
@export_range(0, 999) var natural_defense: int = 0

@export var sprite_scene_path: String = ""
@export var abilities: Array[String] = []
@export var ai_tags: Array[String] = []
@export_range(0, 99999) var reward_experience: int = 0
@export_range(0, 99999) var reward_coin: int = 0
@export var drop_table: Array[String] = []


func get_power() -> int:
	return core_stats.calculate_power(power_stat, level, natural_power)


func get_defense() -> int:
	return core_stats.calculate_defense(level, natural_defense)


func get_speed() -> int:
	return core_stats.speed


func get_summary() -> String:
	return "%s Lv.%d %s | HP %d | POW %d | DEF %d" % [
		display_name,
		level,
		family,
		max_hp,
		get_power(),
		get_defense(),
	]
