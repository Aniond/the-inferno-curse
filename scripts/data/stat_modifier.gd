extends Resource
class_name StatModifier

const STAT_CODES := ["STR", "SPD", "INT", "FTH", "CRT", "PRS", "HP", "MP", "CT", "POW", "DEF", "MOV", "JMP", "C-EV", "CRIT"]

@export var source_id: String = ""
@export var source_name: String = ""
@export_enum("STR", "SPD", "INT", "FTH", "CRT", "PRS", "HP", "MP", "CT", "POW", "DEF", "MOV", "JMP", "C-EV", "CRIT") var target_stat: String = "STR"
@export var is_active: bool = true
@export_range(-999, 999) var flat_bonus: int = 0
@export_range(-99.0, 99.0, 0.01) var per_level_bonus: float = 0.0


func get_bonus(level: int) -> int:
	if not is_active:
		return 0

	var level_steps: int = max(0, level - 1)
	var level_bonus: int = int(floor(per_level_bonus * float(level_steps)))
	return flat_bonus + level_bonus
