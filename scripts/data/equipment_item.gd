extends Resource
class_name EquipmentItem
## A single equippable piece of gear. Authored as a .tres and held in a
## CharacterSheet's owned_equipment list. Equipping applies the stat bonuses
## below to the character's effective stats.

enum Slot { WEAPON, ARMOR, TRINKET }

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var slot: Slot = Slot.WEAPON
@export var icon_path: String = ""

# Weapon-specific
@export_range(0, 999) var weapon_power: int = 0
@export_range(0, 100) var weapon_evasion: int = 0

# Flat stat bonuses applied while equipped
@export var hp_bonus: int = 0
@export var mp_bonus: int = 0
@export var pow_bonus: int = 0
@export var def_bonus: int = 0
@export var spd_bonus: int = 0
@export var str_bonus: int = 0
@export var fth_bonus: int = 0
@export var evasion_bonus: int = 0


func slot_name() -> String:
	match slot:
		Slot.WEAPON: return "Weapon"
		Slot.ARMOR:  return "Armor"
		Slot.TRINKET: return "Trinket"
	return "Weapon"


## Maps a UI slot label ("Weapon"/"Armor"/"Trinket") to the Slot enum.
static func slot_from_name(name: String) -> Slot:
	match name:
		"Armor":   return Slot.ARMOR
		"Trinket": return Slot.TRINKET
	return Slot.WEAPON
