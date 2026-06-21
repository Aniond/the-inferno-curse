extends Resource
class_name CharacterSheet

const CoreStatsResource := preload("res://scripts/data/core_stats.gd")
const StatModifierResource := preload("res://scripts/data/stat_modifier.gd")

@export var character_id: String = ""
@export var display_name: String = ""
@export var job_title: String = ""
@export_range(1, 99) var level: int = 1
@export_range(0, 999999) var experience: int = 0

@export var core_stats: Resource = CoreStatsResource.new()
@export_range(1, 9999) var max_hp: int = 50
@export_range(0, 9999) var max_mp: int = 10
@export_range(0, 999) var starting_ct: int = 0
@export_range(0, 99) var movement: int = 5
@export_range(0, 99) var jump: int = 3
@export_range(0, 100) var evasion_rate: int = 10
@export_range(0, 100) var critical_rate: int = 5

@export_enum("STR", "SPD", "INT", "FTH", "CRT", "PRS") var power_stat: String = "STR"
@export_range(0, 999) var equipment_power: int = 0
@export_range(0, 999) var equipment_defense: int = 0
@export var stat_modifiers: Array[Resource] = []

@export var portrait_path: String = ""
@export var sprite_scene_path: String = ""
@export var abilities: Array[String] = []

@export var weapon: String = ""
@export var head: String = ""
@export var body: String = ""
@export var feet: String = ""
@export var accessory: String = ""
@export var shield: String = ""


func get_power() -> int:
	var primary_value: int = get_core_stat(power_stat)
	var support_value: int = int(floor(float(get_core_stat("PRS") + get_core_stat("CRT")) * 0.25))
	return max(1, level + primary_value + support_value + equipment_power + get_stat_modifier_bonus("POW"))


func get_defense() -> int:
	var body_value: int = int(floor(float(get_core_stat("STR") + get_core_stat("SPD") + get_core_stat("PRS")) / 3.0))
	return max(0, level + body_value + equipment_defense + get_stat_modifier_bonus("DEF"))


func get_attack() -> int:
	return get_power()


func get_core_stat(stat_code: String) -> int:
	return max(0, core_stats.get_stat(stat_code) + get_stat_modifier_bonus(stat_code))


func get_max_hp() -> int:
	return max(1, max_hp + get_stat_modifier_bonus("HP"))


func get_max_mp() -> int:
	return max(0, max_mp + get_stat_modifier_bonus("MP"))


func get_starting_ct() -> int:
	return max(0, starting_ct + get_stat_modifier_bonus("CT"))


func get_speed() -> int:
	return get_core_stat("SPD")


func get_movement() -> int:
	return max(0, movement + get_stat_modifier_bonus("MOV"))


func get_jump() -> int:
	return max(0, jump + get_stat_modifier_bonus("JMP"))


func get_evasion_rate() -> int:
	return clamp(evasion_rate + get_stat_modifier_bonus("C-EV"), 0, 100)


func get_critical_rate() -> int:
	return clamp(critical_rate + get_stat_modifier_bonus("CRIT"), 0, 100)


func get_stat_modifier_bonus(stat_code: String) -> int:
	var total := 0
	for modifier in stat_modifiers:
		if modifier == null:
			continue
		if modifier.get("target_stat") != stat_code:
			continue
		if modifier.has_method("get_bonus"):
			total += modifier.get_bonus(level)
	return total


func get_summary() -> String:
	return "%s Lv.%d %s | HP %d | MP %d | POW %d | DEF %d | MOV %d | JMP %d" % [
		display_name,
		level,
		job_title,
		get_max_hp(),
		get_max_mp(),
		get_power(),
		get_defense(),
		get_movement(),
		get_jump(),
	]
