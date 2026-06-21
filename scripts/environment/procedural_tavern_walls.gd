extends Node3D

@export var room_width: float = 30.0
@export var room_depth: float = 30.0
@export var wall_height: float = 3.4
@export var wainscot_height: float = 1.15
@export var panel_depth: float = 0.08
@export var module_width: float = 4.0

@export var plaster_color: Color = Color(0.36, 0.32, 0.30, 1.0)
@export var plaster_alt_color: Color = Color(0.26, 0.24, 0.25, 1.0)
@export var wood_color: Color = Color(0.24, 0.13, 0.055, 1.0)
@export var dark_wood_color: Color = Color(0.12, 0.065, 0.035, 1.0)


func _ready() -> void:
	_build_walls()


func _build_walls() -> void:
	_build_side("North", Vector3(0.0, 0.0, -room_depth * 0.5 + 0.29), room_width, false)
	_build_side("South", Vector3(0.0, 0.0, room_depth * 0.5 - 0.29), room_width, false)
	_build_side("East", Vector3(room_width * 0.5 - 0.29, 0.0, 0.0), room_depth, true)
	_build_side("West", Vector3(-room_width * 0.5 + 0.29, 0.0, 0.0), room_depth, true)


func _build_side(side_name: String, origin: Vector3, length: float, along_z: bool) -> void:
	var module_count: int = int(ceil(length / module_width))
	var start: float = -length * 0.5

	for i in range(module_count):
		var current_width: float = min(module_width, length - i * module_width)
		var center_offset: float = start + i * module_width + current_width * 0.5
		var base_position := origin

		if along_z:
			base_position.z = center_offset
		else:
			base_position.x = center_offset

		_add_panel("%sPlaster%02d" % [side_name, i], base_position, current_width, wall_height - wainscot_height, wainscot_height + (wall_height - wainscot_height) * 0.5, along_z, plaster_color.lerp(plaster_alt_color, float(i % 3) * 0.18))
		_add_panel("%sWainscot%02d" % [side_name, i], base_position, current_width, wainscot_height, wainscot_height * 0.5, along_z, wood_color.lerp(dark_wood_color, float(i % 2) * 0.25))

		if i > 0:
			var beam_position := origin
			if along_z:
				beam_position.z = start + i * module_width
			else:
				beam_position.x = start + i * module_width
			_add_vertical_beam("%sBeam%02d" % [side_name, i], beam_position, along_z)

	_add_horizontal_rail("%sBottomRail" % side_name, origin, length, 0.12, along_z)
	_add_horizontal_rail("%sChairRail" % side_name, origin, length, wainscot_height, along_z)
	_add_horizontal_rail("%sTopRail" % side_name, origin, length, wall_height, along_z)


func _add_panel(node_name: String, position: Vector3, width: float, height: float, center_y: float, along_z: bool, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	var material := _make_material(color, 0.78)

	mesh.size = _wall_size(width, height, panel_depth, along_z)
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position + Vector3(0.0, center_y, 0.0)
	add_child(mesh_instance)


func _add_vertical_beam(node_name: String, position: Vector3, along_z: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	var material := _make_material(dark_wood_color, 0.7)

	mesh.size = _wall_size(0.16, wall_height, panel_depth * 1.6, along_z)
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position + Vector3(0.0, wall_height * 0.5, 0.0)
	add_child(mesh_instance)


func _add_horizontal_rail(node_name: String, position: Vector3, length: float, y: float, along_z: bool) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	var material := _make_material(dark_wood_color, 0.7)

	mesh.size = _wall_size(length, 0.14, panel_depth * 1.7, along_z)
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position + Vector3(0.0, y, 0.0)
	add_child(mesh_instance)


func _wall_size(width: float, height: float, depth: float, along_z: bool) -> Vector3:
	if along_z:
		return Vector3(depth, height, width)
	return Vector3(width, height, depth)


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	return material
