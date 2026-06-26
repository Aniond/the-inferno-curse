extends Resource
class_name SanitySheet

@export_range(0, 100) var sanity_current: int = 100
@export_range(1, 100) var sanity_max: int = 100
@export var witnessed_events: Array[String] = []


func get_band() -> int:
	if sanity_current >= 75:
		return 4
	elif sanity_current >= 50:
		return 3
	elif sanity_current >= 25:
		return 2
	return 1


func apply_delta(delta: int) -> int:
	sanity_current = clamp(sanity_current + delta, 0, sanity_max)
	return sanity_current


func has_witnessed(event_id: String) -> bool:
	return witnessed_events.has(event_id)


func log_event(event_id: String) -> void:
	if not witnessed_events.has(event_id):
		witnessed_events.append(event_id)
