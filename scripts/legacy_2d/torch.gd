extends Sprite2D

@export var light_color: Color = Color(1.0, 0.55, 0.15, 1.0)
@export var light_energy: float = 1.8
@export var light_radius: float = 200.0
@export var light_shadows: bool = true

var _light: PointLight2D
var _base_energy: float


func _ready() -> void:
	# Visual flame marker
	var canvas = Image.create(8, 12, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.96, 0.55, 0.1, 1.0))
	for y in range(0, 4):
		for x in range(0, 8):
			canvas.set_pixel(x, y, Color(0.9, 0.7, 0.4, 1.0))
	texture = ImageTexture.create_from_image(canvas)
	centered = true
	z_index = 10

	# Point light for 2D HD lighting
	_light = PointLight2D.new()
	_light.color = light_color
	_light.energy = light_energy
	_light.texture_scale = light_radius / 128.0
	_light.shadow_enabled = light_shadows
	_light.shadow_color = Color(0.05, 0.03, 0.08, 0.85)
	_light.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	_light.z_index = -1
	add_child(_light)
	_base_energy = light_energy


func _process(_delta: float) -> void:
	# Subtle flame flicker
	var flicker: float = sin(Time.get_ticks_msec() * 0.008 + hash(position)) * 0.12
	flicker += sin(Time.get_ticks_msec() * 0.021 + hash(position) * 1.7) * 0.06
	_light.energy = _base_energy + flicker
