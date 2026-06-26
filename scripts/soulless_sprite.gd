extends Node3D

const SHEET := "res://assets/images/soulless/soulless_spritesheet.png"
const FRAME_W := 128
const FRAME_H := 109
const FRAME_COUNT := 8
const FPS := 8.0

var _sprite: AnimatedSprite3D = null


func _ready() -> void:
	_sprite = AnimatedSprite3D.new()
	_sprite.name = "SoullessSprite"
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = 0.012
	_sprite.centered = true
	_sprite.scale = Vector3(1.0, 1.74, 1.0)
	_sprite.position = Vector3(0, 0.95, 0)

	var sheet_tex: Texture2D = load(SHEET)
	if sheet_tex == null:
		push_warning("SoullessSprite: sheet not found at %s" % SHEET)
		add_child(_sprite)
		return

	var frames := SpriteFrames.new()

	# Walk south (the only direction on this sheet — reuse for all until more sheets exist)
	for dir in ["walk_south", "walk_north", "walk_east", "walk_west", "idle_south"]:
		frames.add_animation(dir)
		frames.set_animation_speed(dir, FPS)
		frames.set_animation_loop(dir, true)
		for i in range(FRAME_COUNT):
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet_tex
			atlas.region = Rect2(i * FRAME_W, 0, FRAME_W, FRAME_H)
			frames.add_frame(dir, atlas)

	_sprite.sprite_frames = frames
	_sprite.play("walk_south")
	add_child(_sprite)


func play_anim(anim: String) -> void:
	if _sprite != null and _sprite.sprite_frames != null:
		if _sprite.sprite_frames.has_animation(anim):
			_sprite.play(anim)
