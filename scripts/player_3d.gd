extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0

const SPRITE_BASE := "res://assets/images"
const WALK_FPS := 8.0
const IDLE_FPS := 4.0

var movement_enabled: bool = true
var grid_movement_only: bool = false
var _last_direction: String = "south"
var _move_tween: Tween = null


func _ready() -> void:
	# Collision capsule
	var shape := CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.7
	$Collision.shape = shape
	$Collision.position = Vector3(0, 0.85, 0)

	# AnimatedSprite3D with SpriteFrames
	var frames := SpriteFrames.new()
	_register_walk_anims(frames)
	_register_idle_anims(frames)

	$AnimatedSprite.sprite_frames = frames
	$AnimatedSprite.billboard = 1  # BILLBOARD_ENABLED
	$AnimatedSprite.centered = true
	$AnimatedSprite.pixel_size = 0.012
	# Y-scale compensation: undo vertical squash from camera pitch
	# Y-Scale = 1 / cos(pitch). Camera pitch is 55 deg -> 1/cos(55) = 1.74
	$AnimatedSprite.scale = Vector3(1.0, 1.74, 1.0)
	$AnimatedSprite.position = Vector3(0, 0.95, 0)
	$AnimatedSprite.play("idle_south")

	# Divine light aura
	var aura := OmniLight3D.new()
	aura.name = "Aura"
	aura.light_color = Color(1.0, 0.75, 0.4, 1.0)
	aura.light_energy = 2.0
	aura.omni_range = 4.0
	aura.position = Vector3(0, 0.8, 0)
	add_child(aura)


func _register_walk_anims(frames: SpriteFrames) -> void:
	for dir_key in ["south", "east", "north", "west"]:
		var dir_path: String = "%s/Walking/%s" % [SPRITE_BASE, dir_key]
		var anim_name: String = "walk_" + dir_key
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, WALK_FPS)

		for i in range(8):
			var frame_path: String = "%s/frame_%03d.png" % [dir_path, i]
			if ResourceLoader.exists(frame_path):
				var tex: Texture2D = load(frame_path)
				frames.add_frame(anim_name, tex)
			else:
				break


func _register_idle_anims(frames: SpriteFrames) -> void:
	var idle_frames := {
		"south": "res://assets/images/south.png",
		"east": "res://assets/images/rotations/east.png",
		"north": "res://assets/images/rotations/north.png",
		"west": null,
	}

	for dir_key in ["south", "east", "north", "west"]:
		var anim_name: String = "idle_" + dir_key
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, IDLE_FPS)

		if idle_frames.has(dir_key) and idle_frames[dir_key] != null:
			var tex: Texture2D = load(idle_frames[dir_key])
			frames.add_frame(anim_name, tex)
		else:
			var walk_anim: String = "walk_" + dir_key
			if frames.has_animation(walk_anim):
				frames.add_frame(anim_name, frames.get_frame_texture(walk_anim, 0))


func _process(_delta: float) -> void:
	# Divine aura pulse
	if has_node("Aura"):
		var pulse: float = sin(Time.get_ticks_msec() * 0.003) * 0.3
		$Aura.light_energy = 2.0 + pulse


func _physics_process(delta: float) -> void:
	# Lock all rotation; sprite billboards face camera, body never tilts.
	self.rotation = Vector3.ZERO

	if not movement_enabled or grid_movement_only:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		# Do not force _play_idle_anim() here — when in grid mode, animation state
		# (walk vs idle) is driven by explicit calls from the grid controller (battle map)
		# so the player uses the move (walk) animation during grid steps.
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir := Vector3(input_dir.x, 0.0, input_dir.y)

	if move_dir != Vector3.ZERO:
		velocity = velocity.move_toward(move_dir * speed, acceleration * delta)
		_play_walk_anim(move_dir)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		_play_idle_anim()

	move_and_slide()


func _get_direction_key(move_dir: Vector3) -> String:
	if abs(move_dir.x) >= abs(move_dir.z):
		if move_dir.x > 0:
			return "east"
		return "west"
	else:
		if move_dir.z > 0:
			return "south"
		return "north"


func _play_walk_anim(move_dir: Vector3) -> void:
	var dir_key: String = _get_direction_key(move_dir)
	var anim_name: String = "walk_" + dir_key

	if $AnimatedSprite.sprite_frames.has_animation(anim_name):
		$AnimatedSprite.play(anim_name)
	_last_direction = dir_key


func _play_idle_anim() -> void:
	var anim_name: String = "idle_" + _last_direction

	if $AnimatedSprite.sprite_frames.has_animation(anim_name):
		if $AnimatedSprite.animation != anim_name:
			$AnimatedSprite.play(anim_name)
	else:
		if $AnimatedSprite.animation != "idle_south":
			$AnimatedSprite.play("idle_south")


func set_combat_facing(dir_key: String) -> void:
	if dir_key in ["south", "east", "north", "west"]:
		_last_direction = dir_key
	_play_idle_anim()


# --- Grid movement animation support ---
# These allow external grid controllers to show the walk ("active"/move) animation
# while snapping or tweening the player between cells. The walk anim is transient;
# we restore the combat facing's idle anim on completion.

func play_walk_for_dir(dir_key: String) -> void:
	dir_key = _normalize_dir_key(dir_key)
	var anim_name: String = "walk_" + dir_key
	if $AnimatedSprite.sprite_frames.has_animation(anim_name):
		$AnimatedSprite.play(anim_name)
	# Do not overwrite _last_direction — travel dir is only for the transient walk frames.


func _normalize_dir_key(dir_key: String) -> String:
	# Collapse 8-way or unknown to our 4-dir sprite set.
	match dir_key:
		"south", "south_east", "south_west":
			return "south"
		"north", "north_east", "north_west":
			return "north"
		"east":
			return "east"
		"west":
			return "west"
		_:
			return "south"


func animate_grid_move(target_pos: Vector3, travel_dir_key: String, final_dir_key: String = "") -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	play_walk_for_dir(travel_dir_key)
	_move_tween = create_tween()
	var dist := global_position.distance_to(target_pos)
	var duration := clampf(dist / 8.0, 0.12, 0.6)
	_move_tween.tween_property(self, "global_position", target_pos, duration)
	_move_tween.tween_callback(Callable(self, "_on_grid_move_complete").bind(final_dir_key))


func _on_grid_move_complete(final_dir_key: String) -> void:
	_move_tween = null
	if final_dir_key != "" and final_dir_key in ["south", "east", "north", "west"]:
		_last_direction = final_dir_key
	_play_idle_anim()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and movement_enabled:
		_do_attack()
	if event.is_action_pressed("grab_effect") and movement_enabled:
		_do_void_grab()


func _do_attack() -> void:
	if has_node("ClawSlash"):
		$ClawSlash.play_slash()

func _do_void_grab() -> void:
	var effect_scene := load("res://scenes/limbos_embrace_effect.tscn") as PackedScene
	if not effect_scene:
		push_error("Failed to load limbos_embrace_effect.tscn")
		return
	var effect := effect_scene.instantiate() as AnimatedSprite3D
	effect.global_position = global_position
	get_parent().add_child(effect)
	if effect.has_method("play_grab"):
		effect.play_grab()
