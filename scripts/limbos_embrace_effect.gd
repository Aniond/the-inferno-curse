extends AnimatedSprite3D

@export var frame_count: int = 4
@export var fps: float = 8.0

func _ready() -> void:
	setup_sprite_frames()

func setup_sprite_frames() -> void:
	var texture := load("res://assets/images/limbos_embrace_sprite_sheet.png") as Texture2D
	if not texture:
		push_error("Failed to load limbos_embrace_sprite_sheet.png")
		return

	var frames := SpriteFrames.new()
	var frame_width := float(texture.get_width()) / frame_count
	var frame_height := float(texture.get_height())

	frames.add_animation("grab")
	frames.set_animation_speed("grab", fps)
	frames.set_animation_loop("grab", false)

	for i in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("grab", atlas)

	sprite_frames = frames
	animation_finished.connect(_on_animation_finished)

func play_grab(at_position: Vector3 = Vector3.ZERO) -> void:
	if not sprite_frames or not sprite_frames.has_animation("grab"):
		return
	visible = true
	if at_position != Vector3.ZERO:
		global_position = at_position
	play("grab")

func _on_animation_finished() -> void:
	queue_free()
