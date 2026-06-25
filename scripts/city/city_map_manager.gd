extends Node
class_name CityMapManager

const NODE_DIR := "res://data/city/florence/"
const NODE_FILES := [
	"tavern_common_room.tres",
	"cathedral.tres",
	"piazza_della_signoria.tres",
	"mercato_vecchio.tres",
	"ponte_vecchio.tres",
	"guild_hall_street.tres",
	"oltrarno_quarter.tres",
	"city_gate.tres",
]

var _screen: Node = null  # CityMapScreen — typed as Node until class cache refreshes
var _nodes: Array[CityNodeData] = []


func _ready() -> void:
	_load_nodes()
	_screen = load("res://scripts/city/city_map_screen.gd").new()
	_screen.name = "CityMapScreen"
	add_child(_screen)
	_screen.node_travel_requested.connect(_on_travel_requested)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_city_map"):
		if _screen.visible:
			_screen.close()
		else:
			_screen.open(_nodes)
		get_viewport().set_input_as_handled()


func unlock_node(node_id: String) -> void:
	_screen.unlock_node(node_id)


func _load_nodes() -> void:
	_nodes.clear()
	for file_name in NODE_FILES:
		var path: String = NODE_DIR + file_name
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is CityNodeData:
				_nodes.append(res as CityNodeData)
		else:
			push_warning("CityMapManager: node file not found: %s" % path)


func _on_travel_requested(node_data: CityNodeData) -> void:
	if node_data.scene_path == "":
		return
	get_tree().change_scene_to_file(node_data.scene_path)
