extends Node3D
class_name MercatoVecchio

# Mercato Vecchio — Florence's old market district.
# Layout skeleton: ground, building shells, fountain, stalls, river edge, exits.
# Assets (models, textures, NPCs) slot in when generated.

func _ready() -> void:
	pass


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Return to city map
		get_tree().change_scene_to_file("res://scenes/main.tscn")
