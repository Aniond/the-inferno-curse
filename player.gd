extends CharacterBody2D

@export var speed: float = 120.0
@export var acceleration: float = 600.0
@export var friction: float = 500.0

const ANIM_BASE := "res://assets/images"
const WALK_FPS := 8.0
const IDLE_FPS := 4.0

var _last_direction: String = "south"


func _ready() -> void:
	var col_shape = RectangleShape2D.new()
	col_shape.size = Vector2(24, 36)
	$Collision.shape = col_shape

	var frames := SpriteFrames.new()
	_register_walk_anims(frames)
	_register_idle_anims(frames)

	$AnimatedSprite.sprite_frames = frames
	$AnimatedSprite.centered = true
	$AnimatedSprite.scale = Vector2(2.0, 2.0)
	$AnimatedSprite.play("idle_south")

	# Divine light aura -- follows the priest, pushes back darkness
	var aura := PointLight2D.new()
	aura.name = "Aura"
	aura.color = Color(1.0, 0.78, 0.45, 1.0)
	aura.energy = 1.5
	aura.texture_scale = 300.0 / 128.0
	aura.shadow_enabled = true
	aura.shadow_color = Color(0.05, 0.03, 0.08, 0.9)
	aura.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	aura.z_index = -2
	add_child(aura)


func _register_walk_anims(frames: SpriteFrames) -> void:
	for dir_key in ["south", "east", "north", "west"]:
		var dir_path: String = "%s/Walking/%s" % [ANIM_BASE, dir_key]
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
		"west": null,  # fallback
	}

	for dir_key in ["south", "east", "north", "west"]:
		var anim_name: String = "idle_" + dir_key
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, IDLE_FPS)

		if idle_frames.has(dir_key) and idle_frames[dir_key] != null:
			var tex: Texture2D = load(idle_frames[dir_key])
			frames.add_frame(anim_name, tex)
		else:
			# Fallback: first walk frame
			var walk_anim: String = "walk_" + dir_key
			if frames.has_animation(walk_anim):
				frames.add_frame(anim_name, frames.get_frame_texture(walk_anim, 0))


func _process(_delta: float) -> void:
	# Divine aura pulse -- breathing light
	if has_node("Aura"):
		var pulse: float = sin(Time.get_ticks_msec() * 0.003) * 0.15
		$Aura.energy = 1.5 + pulse


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
		_play_walk_anim(input_dir)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		_play_idle_anim()

	move_and_slide()


func _get_direction_key(input_dir: Vector2) -> String:
	if abs(input_dir.x) >= abs(input_dir.y):
		if input_dir.x > 0:
			return "east"
		return "west"
	else:
		if input_dir.y > 0:
			return "south"
		return "north"


func _play_walk_anim(input_dir: Vector2) -> void:
	var dir_key: String = _get_direction_key(input_dir)
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
