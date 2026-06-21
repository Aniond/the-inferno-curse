extends Node
## PlayerData - runtime bridge from CharacterSheet resources to UI/game systems.
## The authored source of truth is a CharacterSheet `.tres`; this node holds
## mutable current-state values such as current HP, MP, CT, and experience.

const DEFAULT_CHARACTER_SHEET_PATH := "res://data/characters/guglielmo_da_siena.tres"
const CharacterSheetScript := preload("res://scripts/data/character_sheet.gd")

signal stats_changed
signal health_changed(current_hp: int, max_hp: int)
signal mana_changed(current_mp: int, max_mp: int)
signal level_up(new_level: int)
signal ability_unlocked(ability_name: String)

var character_sheet_path: String = DEFAULT_CHARACTER_SHEET_PATH
var character_sheet: Resource

var character_name: String = ""
var character_title: String = ""
var portrait_path: String = ""

var level: int = 1
var experience: int = 0
var exp_to_next: int = 100

var _hp: int = 1
var hp: int:
	get:
		return _hp
	set(value):
		_hp = clampi(value, 0, max_hp)
		health_changed.emit(_hp, max_hp)
		stats_changed.emit()

var max_hp: int = 1

var _mp: int = 0
var mp: int:
	get:
		return _mp
	set(value):
		_mp = clampi(value, 0, max_mp)
		mana_changed.emit(_mp, max_mp)
		stats_changed.emit()

var max_mp: int = 0
var ct: int = 0
var max_ct: int = 100

var STR: int = 5
var SPD: int = 5
var INT: int = 5
var FTH: int = 5
var ATK: int = 5
var DEF: int = 5
var CRT: int = 5
var PRS: int = 5
var POW: int = 5
var MOV: int = 5
var JMP: int = 3
var critical_rate: int = 0
var evasion_rate: int = 0

var resist_physical: int = 0
var resist_fire: int = 0
var resist_ice: int = 0
var resist_thunder: int = 0
var resist_holy: int = 0
var resist_dark: int = 0

var abilities: Array[Dictionary] = []


func _ready() -> void:
	load_character_sheet(character_sheet_path)


func load_character_sheet(path: String) -> bool:
	var loaded := load(path)
	if loaded == null or not is_instance_of(loaded, CharacterSheetScript):
		push_error("Failed to load CharacterSheet resource: %s" % path)
		return false

	character_sheet_path = path
	character_sheet = loaded
	_apply_character_sheet()
	stats_changed.emit()
	return true


func _apply_character_sheet() -> void:
	if character_sheet == null:
		return

	character_name = character_sheet.display_name
	character_title = character_sheet.job_title
	portrait_path = character_sheet.portrait_path
	level = character_sheet.level
	experience = character_sheet.experience
	exp_to_next = _calculate_exp_to_next(level)

	_recalculate_effective_stats()
	_hp = max_hp
	_mp = max_mp
	ct = character_sheet.get_starting_ct()
	_build_ability_rows()


func _recalculate_effective_stats() -> void:
	if character_sheet == null:
		return

	character_sheet.level = level
	character_sheet.experience = experience

	max_hp = character_sheet.get_max_hp()
	max_mp = character_sheet.get_max_mp()
	STR = character_sheet.get_core_stat("STR")
	SPD = character_sheet.get_core_stat("SPD")
	INT = character_sheet.get_core_stat("INT")
	FTH = character_sheet.get_core_stat("FTH")
	CRT = character_sheet.get_core_stat("CRT")
	PRS = character_sheet.get_core_stat("PRS")
	ATK = character_sheet.get_attack()
	DEF = character_sheet.get_defense()
	POW = character_sheet.get_power()
	MOV = character_sheet.get_movement()
	JMP = character_sheet.get_jump()
	critical_rate = character_sheet.get_critical_rate()
	evasion_rate = character_sheet.get_evasion_rate()
	ct = clampi(ct, 0, max_ct)
	_hp = clampi(_hp, 0, max_hp)
	_mp = clampi(_mp, 0, max_mp)


func _build_ability_rows() -> void:
	abilities.clear()
	if character_sheet == null:
		return

	for ability_name in character_sheet.abilities:
		abilities.append({
			"name": ability_name,
			"at_cost": 0,
			"cev": "%d%%" % evasion_rate,
			"unlocked": true,
		})


func get_attribute(attr_name: String) -> int:
	match attr_name:
		"STR":
			return STR
		"SPD":
			return SPD
		"INT":
			return INT
		"FTH":
			return FTH
		"ATK":
			return ATK
		"DEF":
			return DEF
		"CRT":
			return CRT
		"PRS":
			return PRS
		"POW":
			return POW
		"MOV":
			return MOV
		"JMP":
			return JMP
	return 0


func get_resistance(element: String) -> int:
	match element:
		"Physical":
			return resist_physical
		"Fire":
			return resist_fire
		"Ice":
			return resist_ice
		"Thunder":
			return resist_thunder
		"Holy":
			return resist_holy
		"Dark":
			return resist_dark
	return 0


func deal_damage(amount: int) -> void:
	hp -= amount


func heal(amount: int) -> void:
	hp += amount


func spend_mana(amount: int) -> void:
	mp -= amount


func restore_mana(amount: int) -> void:
	mp += amount


func add_experience(amount: int) -> void:
	experience += amount
	while experience >= exp_to_next:
		experience -= exp_to_next
		level += 1
		exp_to_next = _calculate_exp_to_next(level)
		level_up.emit(level)

	_recalculate_effective_stats()
	stats_changed.emit()


func _calculate_exp_to_next(for_level: int) -> int:
	var value := 100
	for _index in range(max(0, for_level - 1)):
		value = int(round(float(value) * 1.35))
	return value
