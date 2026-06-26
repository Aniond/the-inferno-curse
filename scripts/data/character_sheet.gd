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
@export var abilities: Array[Resource] = []
@export var soul_gems: Array[Resource] = []
@export var absorbed_skills: Dictionary = {}    # skill_id -> absorb count
@export var unlocked_nodes: Dictionary = {}     # skill_id -> current tier (0=locked)
@export var equipped_skills: Array[String] = [] # active skill slots (max 4)
@export var equipped_traits: Array[String] = [] # passive trait slots (max 4)
@export var job_sheets: Array[Resource] = []    # JobSheet resources for each job
@export var active_job_id: String = ""          # currently active job

@export var sanity: Resource = null             # SanitySheet — Guglielmo only

const MAX_SKILL_SLOTS := 4
const MAX_TRAIT_SLOTS := 4


func equip_skill(skill_id: String) -> bool:
	if equipped_skills.has(skill_id):
		return false
	if equipped_skills.size() >= MAX_SKILL_SLOTS:
		return false
	equipped_skills.append(skill_id)
	return true


func unequip_skill(skill_id: String) -> void:
	equipped_skills.erase(skill_id)


func equip_trait(skill_id: String) -> bool:
	if equipped_traits.has(skill_id):
		return false
	if equipped_traits.size() >= MAX_TRAIT_SLOTS:
		return false
	equipped_traits.append(skill_id)
	return true


func unequip_trait(skill_id: String) -> void:
	equipped_traits.erase(skill_id)


func get_job_sheet(job_id: String) -> JobSheet:
	for sheet in job_sheets:
		if sheet is JobSheet and sheet.job_id == job_id:
			return sheet
	return null


func get_active_job_sheet() -> JobSheet:
	return get_job_sheet(active_job_id)


func earn_jp(amount: int) -> void:
	var sheet := get_active_job_sheet()
	if sheet != null:
		sheet.earn_jp(amount)


func get_all_unlocked_job_skills() -> Array[String]:
	var all: Array[String] = []
	for sheet in job_sheets:
		if sheet is JobSheet:
			all.append_array(sheet.unlocked_skills)
	return all

@export var weapon: String = ""
@export var head: String = ""
@export var body: String = ""
@export var feet: String = ""
@export var accessory: String = ""
@export var shield: String = ""

# ── Equipment inventory (per-character owned items) ──────────────────────────
@export var owned_equipment: Array[Resource] = []  # EquipmentItem resources
@export var equipped_weapon_id: String = ""
@export var equipped_armor_id: String = ""
@export var equipped_trinket_id: String = ""


## All owned items that fit the given UI slot name ("Weapon"/"Armor"/"Trinket").
func get_equippable(slot_name: String) -> Array:
	var want := EquipmentItem.slot_from_name(slot_name)
	var out: Array = []
	for res in owned_equipment:
		if res is EquipmentItem and res.slot == want:
			out.append(res)
	return out


func get_equipped_id(slot_name: String) -> String:
	match slot_name:
		"Armor":   return equipped_armor_id
		"Trinket": return equipped_trinket_id
	return equipped_weapon_id


func get_equipped_item(slot_name: String) -> EquipmentItem:
	var want_id := get_equipped_id(slot_name)
	if want_id.is_empty():
		return null
	for res in owned_equipment:
		if res is EquipmentItem and res.item_id == want_id:
			return res
	return null


## Equip an item (or pass null / "" to clear the slot). Updates the legacy
## string fields too so existing UI keeps working.
func equip_item(slot_name: String, item_id: String) -> void:
	var item: EquipmentItem = null
	for res in owned_equipment:
		if res is EquipmentItem and res.item_id == item_id:
			item = res
			break
	var label := item.display_name if item != null else ""
	match slot_name:
		"Armor":
			equipped_armor_id = item_id
			body = label
		"Trinket":
			equipped_trinket_id = item_id
			accessory = label
		_:
			equipped_weapon_id = item_id
			weapon = label


func _equipment_bonus(field: String) -> int:
	var total := 0
	for slot_name in ["Weapon", "Armor", "Trinket"]:
		var item := get_equipped_item(slot_name)
		if item != null:
			total += int(item.get(field))
	return total


func get_power() -> int:
	var primary_value: int = get_core_stat(power_stat)
	var support_value: int = int(floor(float(get_core_stat("PRS") + get_core_stat("CRT")) * 0.25))
	return max(1, level + primary_value + support_value + equipment_power + _equipment_bonus("pow_bonus") + _equipment_bonus("weapon_power") + get_stat_modifier_bonus("POW"))


func get_defense() -> int:
	var body_value: int = int(floor(float(get_core_stat("STR") + get_core_stat("SPD") + get_core_stat("PRS")) / 3.0))
	return max(0, level + body_value + equipment_defense + _equipment_bonus("def_bonus") + get_stat_modifier_bonus("DEF"))


func get_attack() -> int:
	return get_power()


func get_core_stat(stat_code: String) -> int:
	var equip := 0
	match stat_code:
		"STR": equip = _equipment_bonus("str_bonus")
		"SPD": equip = _equipment_bonus("spd_bonus")
		"FTH": equip = _equipment_bonus("fth_bonus")
	return max(0, core_stats.get_stat(stat_code) + equip + get_stat_modifier_bonus(stat_code))


func get_max_hp() -> int:
	return max(1, max_hp + _equipment_bonus("hp_bonus") + get_stat_modifier_bonus("HP"))


func get_max_mp() -> int:
	return max(0, max_mp + _equipment_bonus("mp_bonus") + get_stat_modifier_bonus("MP"))


func get_starting_ct() -> int:
	return max(0, starting_ct + get_stat_modifier_bonus("CT"))


func get_speed() -> int:
	return get_core_stat("SPD")


func get_movement() -> int:
	return max(0, movement + get_stat_modifier_bonus("MOV"))


func get_jump() -> int:
	return max(0, jump + get_stat_modifier_bonus("JMP"))


func get_evasion_rate() -> int:
	return clamp(evasion_rate + _equipment_bonus("evasion_bonus") + _equipment_bonus("weapon_evasion") + get_stat_modifier_bonus("C-EV"), 0, 100)


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
