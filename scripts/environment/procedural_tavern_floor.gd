extends Node3D

@export var floor_width: float = 30.0
@export var floor_depth: float = 30.0
@export var plank_width: float = 0.9
@export var plank_height: float = 0.05
@export var plank_gap: float = 0.035
@export var base_color: Color = Color(0.26, 0.15, 0.07, 1.0)
@export var alternate_color: Color = Color(0.18, 0.10, 0.045, 1.0)


func _ready() -> void:
	_build_floor()


func _build_floor() -> void:
	var plank_count: int = int(ceil(floor_depth / plank_width))
	var start_z: float = -floor_depth * 0.5 + plank_width * 0.5

	for i in range(plank_count):
		var plank := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var material := StandardMaterial3D.new()
		var z: float = start_z + i * plank_width
		var tone: float = 0.85 + float(i % 5) * 0.04

		mesh.size = Vector3(floor_width, plank_height, plank_width - plank_gap)
		material.albedo_color = base_color.lerp(alternate_color, float(i % 2) * 0.45) * tone
		material.roughness = 0.85
		material.metallic = 0.0

		plank.name = "Plank%02d" % i
		plank.mesh = mesh
		plank.material_override = material
		plank.position = Vector3(0.0, plank_height * 0.5 + 0.01, z)
		add_child(plank)
