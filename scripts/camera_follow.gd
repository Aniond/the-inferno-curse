extends Camera3D

@export var target_path: NodePath
@export var follow_speed := 8.0
@export var ortho_size := 16.0
@export var camera_offset := Vector3(4.5, 5.5, 8.0)
@export var look_at_height := 1.1

var _target: Node3D


func _ready() -> void:
	if target_path:
		_target = get_node(target_path) as Node3D

	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = ortho_size
	current = true

	if _target:
		global_position = _target.global_position + camera_offset
		look_at(_target.global_position + Vector3(0, look_at_height, 0), Vector3.UP)


func _process(delta: float) -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = ortho_size
	current = true

	if not _target:
		return

	global_position = global_position.lerp(
		_target.global_position + camera_offset,
		follow_speed * delta
	)
	look_at(_target.global_position + Vector3(0, look_at_height, 0), Vector3.UP)
	self.rotation.z = 0.0
