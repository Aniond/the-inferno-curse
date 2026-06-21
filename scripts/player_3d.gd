extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 15.0
@export var friction: float = 12.0

const SPRITE_BASE := "res://assets/images"
const WALK_FPS := 8.0
const IDLE_FPS := 4.0

var _last_direction: String = "south"


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
