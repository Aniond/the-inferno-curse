extends Resource
class_name SanityEvent

@export var event_id: String = ""
@export var circle: String = "limbo"
@export var description: String = ""
@export_range(1, 30) var sanity_cost: int = 5
@export_range(1, 20) var roll_difficulty: int = 10
@export_enum("on_enter", "on_interact", "on_story_beat", "on_timer") var trigger_type: String = "on_enter"
