extends Resource
class_name CityNodeData

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var preview_image_path: String = ""
@export var scene_path: String = ""
@export var map_position: Vector2 = Vector2.ZERO  # pixel position on the map image
@export var unlocked: bool = true
@export var is_secret: bool = false
@export var district: String = ""  # e.g. "centro", "oltrarno", "gate"
