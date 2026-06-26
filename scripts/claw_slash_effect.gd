extends AnimatedSprite3D

@export var frame_count: int = 4
@export var fps: float = 10.0

func _ready():
	setup_sprite_frames()

func setup_sprite_frames():
	var texture = load("res://assets/images/claw_slash_spritesheet.png") as Texture2D
	if not texture:
		push_error("Failed to load claw slash spritesheet")
		return

	var frames = SpriteFrames.new()
	var frame_width = float(texture.get_width()) / frame_count
	var frame_height = float(texture.get_height())

	frames.add_animation("slash")
	frames.set_animation_speed("slash", fps)
	frames.set_animation_loop("slash", false)

	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("slash", atlas)

	sprite_frames = frames
	animation_finished.connect(_on_animation_finished)

func play_slash():
	if not sprite_frames or not sprite_frames.has_animation("slash"):
		return
	visible = true
	play("slash")

func _on_animation_finished():
	queue_free()
