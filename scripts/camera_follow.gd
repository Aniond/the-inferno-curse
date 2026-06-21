extends Camera3D

@export var target_path: NodePath
@export var follow_speed := 4.0
@export var ortho_size := 13.5
@export var camera_offset := Vector3(7.0, 7.5, 7.0)
@export var look_at_height := 1.1
@export var dead_zone_radius := 1.5

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

	var current_focus := global_position - camera_offset
	var target_focus := _target.global_position
	var drift := Vector3(
		target_focus.x - current_focus.x,
		0.0,
		target_focus.z - current_focus.z
	)

	if drift.length() > dead_zone_radius:
		var corrected_focus := target_focus - drift.normalized() * dead_zone_radius
		global_position = global_position.lerp(
			corrected_focus + camera_offset,
			min(follow_speed * delta, 1.0)
		)

	look_at(_target.global_position + Vector3(0, look_at_height, 0), Vector3.UP)
	self.rotation.z = 0.0
