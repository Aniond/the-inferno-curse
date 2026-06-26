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
@export_range(0, 99) var movement: int = 4
@export_range(0, 99) var jump: int = 2

@export_enum("STR", "SPD", "INT", "FTH", "CRT", "PRS") var power_stat: String = "STR"
@export_range(0, 999) var natural_power: int = 0
@export_range(0, 999) var natural_defense: int = 0

@export var sprite_scene_path: String = ""
@export var abilities: Array[String] = []  # combat-facing abilities
@export var ai_tags: Array[String] = []
@export_range(1, 10) var intelligence: int = 5  # drives tactical AI sophistication
@export_range(0, 99999) var reward_experience: int = 0
@export_range(0, 99999) var reward_coin: int = 0
@export var drop_table: Array[String] = []

# Ability Absorption fields (for main character growth)
@export var normal_ability: String = ""
@export var uncommon_ability: String = ""
@export var rare_ability: String = ""
@export var ability_theme_tags: Array[String] = []  # e.g. ["martial", "infernal"] for class grouping


func get_power() -> int:
	return core_stats.calculate_power(power_stat, level, natural_power)


func get_defense() -> int:
	return core_stats.calculate_defense(level, natural_defense)


func get_max_hp() -> int:
	return max(1, max_hp)


func get_max_mp() -> int:
	return max(0, max_mp)


func get_starting_ct() -> int:
	return max(0, starting_ct)


func get_speed() -> int:
	return core_stats.speed


func get_movement() -> int:
	return max(0, movement)


func get_jump() -> int:
	return max(0, jump)


func get_intelligence() -> int:
	return clampi(intelligence, 1, 10)


func get_summary() -> String:
	return "%s Lv.%d %s | HP %d | POW %d | DEF %d | MOV %d | JMP %d" % [
		display_name,
		level,
		family,
		get_max_hp(),
		get_power(),
		get_defense(),
		get_movement(),
		get_jump(),
	]
