extends CharacterBody3D

@export var pixel_size: float = 0.0061
@export var sprite_height_scale: float = 1.74
@export_enum("south", "east", "north", "west") var starting_direction: String = "south"
@export var play_walk_on_ready: bool = false

const SPRITE_BASE := "res://assets/images/baker"
const IDLE_FPS := 4.0
const WALK_FPS := 8.0

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite
@onready var collision: CollisionShape3D = $Collision

var _current_direction: String = "south"


func _ready() -> void:
	_setup_collision()
	_setup_sprite()

	if play_walk_on_ready:
		play_walk(starting_direction)
	else:
		play_idle(starting_direction)


func play_idle(direction: String = _current_direction) -> void:
	var anim_name: String = "idle_" + direction

	if animated_sprite.sprite_frames.has_animation(anim_name):
		_current_direction = direction
		animated_sprite.play(anim_name)


func play_walk(direction: String = _current_direction) -> void:
	var anim_name: String = "walk_" + direction

	if animated_sprite.sprite_frames.has_animation(anim_name):
		_current_direction = direction
		animated_sprite.play(anim_name)
	else:
		play_idle(direction)


func face_direction(direction: String) -> void:
	play_idle(direction)


func get_current_direction() -> String:
	return _current_direction


func _setup_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.7
	collision.shape = shape
	collision.position = Vector3(0.0, 0.85, 0.0)


func _setup_sprite() -> void:
	var frames := SpriteFrames.new()
	_register_idle_anims(frames)
	_register_walk_anims(frames)

	animated_sprite.sprite_frames = frames
	animated_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	animated_sprite.centered = true
	animated_sprite.pixel_size = pixel_size
	animated_sprite.scale = Vector3(1.0, sprite_height_scale, 1.0)
	animated_sprite.position = Vector3(0.0, 0.95, 0.0)


func _register_idle_anims(frames: SpriteFrames) -> void:
	for dir_key in ["south", "east", "north", "west"]:
		var anim_name: String = "idle_" + dir_key
		var frame_path: String = "%s/Idle/%s/frame_000.png" % [SPRITE_BASE, dir_key]

		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, IDLE_FPS)

		if ResourceLoader.exists(frame_path):
			var tex: Texture2D = load(frame_path)
			frames.add_frame(anim_name, tex)


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

		if frames.get_frame_count(anim_name) == 0:
			var idle_anim: String = "idle_" + dir_key
			if frames.has_animation(idle_anim) and frames.get_frame_count(idle_anim) > 0:
				frames.add_frame(anim_name, frames.get_frame_texture(idle_anim, 0))
