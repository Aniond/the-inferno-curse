extends Camera3D

@export var target_path: NodePath
@export var follow_speed := 4.0
@export var ortho_size := 13.5
@export var look_at_height := 1.1
@export var dead_zone_radius := 1.5

# Orbit rig: the camera sits on a sphere around the focus point, defined by a
# yaw (around Y), a pitch (elevation), and a distance. The default reproduces
# the original isometric framing.
@export var orbit_distance := 12.0
@export var default_yaw_deg := 45.0     # isometric default
@export var pitch_deg := 35.0           # elevation angle above the ground

# --- Manual pan / zoom / rotate (battle overview) ---
@export var pan_speed := 0.018          # world units per pixel (lower = less sensitive)
@export var key_pan_speed := 9.0        # world units / second for arrow pan
@export var rotate_speed := 0.25        # degrees of yaw per pixel of drag (lower = slower)
@export var key_rotate_speed := 90.0    # degrees / second for [ ] orbit
@export var zoom_step := 1.5
@export var zoom_min := 6.0
@export var zoom_max := 26.0
@export var pan_limit := 20.0

var _target: Node3D
var _pan_offset := Vector3.ZERO
var _yaw_deg := 45.0                     # current orbit yaw
var _is_panning := false                # middle-mouse held: drag pans
var _is_rotating := false               # right-mouse held: drag orbits
var _manual_control := false


func _ready() -> void:
	if target_path:
		_target = get_node(target_path) as Node3D
	_yaw_deg = default_yaw_deg
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = ortho_size
	current = true
	if _target:
		_snap_to_focus(_target.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_MIDDLE:
				_is_panning = mb.pressed
				if mb.pressed:
					_manual_control = true
			MOUSE_BUTTON_RIGHT:
				_is_rotating = mb.pressed
				if mb.pressed:
					_manual_control = true
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					_zoom_by(-zoom_step)
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_zoom_by(zoom_step)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _is_rotating:
			_yaw_deg += mm.relative.x * rotate_speed
		elif _is_panning:
			_pan_by_screen_delta(mm.relative)

	if event is InputEventKey and (event as InputEventKey).pressed:
		var key := (event as InputEventKey).keycode
		if key == KEY_HOME or key == KEY_F:
			recenter()


func _process(delta: float) -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	current = true
	pitch_deg = clampf(pitch_deg, 30.0, 60.0)
	_yaw_deg = clampf(_yaw_deg, 0.0, 90.0)
	ortho_size = clampf(ortho_size, zoom_min, zoom_max)
	size = lerpf(size, ortho_size, minf(follow_speed * delta, 1.0))
	if not _target:
		return

	_apply_key_controls(delta)

	var base_focus := _target.global_position
	var focus := base_focus + _pan_offset

	# In auto-follow, hold a dead zone around the target; in manual mode, track
	# the panned/rotated focus directly.
	var goal := _camera_pos_for_focus(focus)
	if not _manual_control:
		var flat_drift := Vector3(
			base_focus.x - (global_position - _orbit_vector()).x,
			0.0,
			base_focus.z - (global_position - _orbit_vector()).z
		)
		if flat_drift.length() <= dead_zone_radius:
			goal = global_position  # inside dead zone: stay put
	global_position = global_position.lerp(goal, minf(follow_speed * delta, 1.0))

	look_at(focus + Vector3(0, look_at_height, 0), Vector3.UP)
	rotation.z = 0.0


## Recenter on the target, clear pan, restore default angle, resume follow.
func recenter() -> void:
	_pan_offset = Vector3.ZERO
	_yaw_deg = default_yaw_deg
	_manual_control = false
	if _target:
		_snap_to_focus(_target.global_position)


# --- internals ---

func _orbit_vector() -> Vector3:
	# Offset from focus to camera, from yaw + pitch + distance.
	var yaw := deg_to_rad(_yaw_deg)
	var pitch := deg_to_rad(pitch_deg)
	var horiz := orbit_distance * cos(pitch)
	return Vector3(horiz * sin(yaw), orbit_distance * sin(pitch), horiz * cos(yaw))


func _camera_pos_for_focus(focus: Vector3) -> Vector3:
	return focus + _orbit_vector()


func _snap_to_focus(base_focus: Vector3) -> void:
	global_position = _camera_pos_for_focus(base_focus + _pan_offset)
	look_at((base_focus + _pan_offset) + Vector3(0, look_at_height, 0), Vector3.UP)
	rotation.z = 0.0


func _zoom_by(amount: float) -> void:
	_manual_control = true
	ortho_size = clampf(ortho_size + amount, zoom_min, zoom_max)


func _pan_by_screen_delta(screen_delta: Vector2) -> void:
	var right := global_transform.basis.x
	var fwd := global_transform.basis.y
	right.y = 0.0
	fwd.y = 0.0
	right = right.normalized() if right.length() > 0.0 else Vector3.RIGHT
	fwd = fwd.normalized() if fwd.length() > 0.0 else Vector3.FORWARD
	_pan_offset += -right * screen_delta.x * pan_speed + fwd * screen_delta.y * pan_speed
	_clamp_pan()


func _apply_key_controls(delta: float) -> void:
	if not _manual_control:
		return
	# Bracket keys orbit the camera (Q/E are reserved for combat facing).
	if Input.is_key_pressed(KEY_BRACKETLEFT):
		_yaw_deg -= key_rotate_speed * delta
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		_yaw_deg += key_rotate_speed * delta
	# Arrow keys pan the focus along the camera's ground plane.
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0
	if Input.is_key_pressed(KEY_UP):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		move.y += 1.0
	if move != Vector2.ZERO:
		var right := global_transform.basis.x
		var fwd := global_transform.basis.y
		right.y = 0.0
		fwd.y = 0.0
		right = right.normalized() if right.length() > 0.0 else Vector3.RIGHT
		fwd = fwd.normalized() if fwd.length() > 0.0 else Vector3.FORWARD
		_pan_offset += (right * move.x - fwd * move.y) * key_pan_speed * delta
		_clamp_pan()


func _clamp_pan() -> void:
	if _pan_offset.length() > pan_limit:
		_pan_offset = _pan_offset.normalized() * pan_limit
