extends Node3D

@export var light_color := Color(1.0, 0.65, 0.2, 1.0)
@export var base_energy := 2.5
@export var flicker_strength := 0.6
@export var flicker_speed := 3.0
@export var light_range := 4.5
@export var shadow_enabled := true

var _light: OmniLight3D
var _noise: FastNoiseLite
var _seed_offset: float
var _external_mult: float = 1.0


func _ready() -> void:
	_light = OmniLight3D.new()
	_light.name = "TorchLight"
	_light.light_color = light_color
	_light.light_energy = base_energy
	_light.omni_range = light_range
	_light.shadow_enabled = shadow_enabled
	add_child(_light)

	_noise = FastNoiseLite.new()
	_noise.frequency = 0.015
	_seed_offset = randf() * 1000.0


func set_external_multiplier(m: float) -> void:
	_external_mult = max(0.1, m)

func _process(_delta: float) -> void:
	if not _light:
		return

	var t := Time.get_ticks_msec() * 0.001 * flicker_speed
	var n := _noise.get_noise_1d(t + _seed_offset)
	var flicker := 1.0 + n * flicker_strength - randf() * 0.08
	var effective := base_energy * _external_mult
	_light.light_energy = max(effective * flicker, 0.25)
