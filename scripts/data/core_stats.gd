extends Resource
class_name CoreStats

const STAT_CODES := ["STR", "SPD", "INT", "FTH", "CRT", "PRS"]

@export_range(1, 999) var strength: int = 5
@export_range(1, 999) var speed: int = 5
@export_range(1, 999) var intellect: int = 5
@export_range(1, 999) var faith: int = 5
@export_range(1, 999) var creativity: int = 5
@export_range(1, 999) var presence: int = 5


func get_stat(stat_code: String) -> int:
	match stat_code:
		"STR":
			return strength
		"SPD":
			return speed
		"INT":
			return intellect
		"FTH":
			return faith
		"CRT":
			return creativity
		"PRS":
			return presence
		_:
			push_warning("Unknown stat code: %s" % stat_code)
			return 0


func get_core_total() -> int:
	return strength + speed + intellect + faith + creativity + presence


func calculate_power(primary_stat: String, level: int, bonus_power: int = 0) -> int:
	var primary_value: int = get_stat(primary_stat)
	var support_value: int = int(floor(float(presence + creativity) * 0.25))
	return max(1, level + primary_value + support_value + bonus_power)


func calculate_defense(level: int, bonus_defense: int = 0) -> int:
	var body_value: int = int(floor(float(strength + speed + presence) / 3.0))
	return max(0, level + body_value + bonus_defense)
