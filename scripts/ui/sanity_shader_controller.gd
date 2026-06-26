extends Node
## SanityShaderController — listens to SanityEventBus signals and drives
## WorldEnvironment adjustment parameters + a CanvasLayer overlay to express
## the current sanity band visually.
##
## Attach to any persistent node in main.tscn (or as its own child of WorldEnvironment).
## Assign world_environment in the Inspector.

@export var world_environment: WorldEnvironment

# Per-band Environment targets
# [saturation, brightness, fog_density_multiplier]
const BAND_TARGETS := {
	4: { "saturation": 0.85, "brightness": 1.05, "tint": Color(0, 0, 0, 0.0) },
	3: { "saturation": 0.55, "brightness": 0.95, "tint": Color(0.05, 0.05, 0.1, 0.15) },
	2: { "saturation": 0.18, "brightness": 0.85, "tint": Color(0.05, 0.05, 0.12, 0.30) },
	1: { "saturation": 0.0,  "brightness": 0.72, "tint": Color(0.02, 0.0, 0.08, 0.50) },
}

const TWEEN_DURATION := 2.5  # seconds to lerp between bands

var _overlay: ColorRect
var _active_tween: Tween


func _ready() -> void:
	_build_overlay()
	SanityEventBus.band_changed.connect(_on_band_changed)
	SanityEventBus.natural_twenty.connect(_on_natural_twenty)
	# Sync to current band immediately (in case sanity was loaded from save)
	var band := SanityEventBus.get_current_band()
	_apply_band_instant(band)


func _on_band_changed(new_band: int) -> void:
	_tween_to_band(new_band)


func _on_natural_twenty() -> void:
	# Brief vivid color flash — pop saturation up then return
	if world_environment == null:
		return
	var env := world_environment.environment
	if env == null:
		return
	var flash := create_tween()
	flash.tween_property(env, "adjustment_saturation", 1.4, 0.15)
	flash.tween_property(env, "adjustment_saturation", env.adjustment_saturation, 0.6)


func _tween_to_band(band: int) -> void:
	if world_environment == null:
		return
	var env := world_environment.environment
	if env == null:
		return
	var target: Dictionary = BAND_TARGETS.get(band, BAND_TARGETS[4])

	if _active_tween:
		_active_tween.kill()
	_active_tween = create_tween().set_parallel(true)
	_active_tween.tween_property(env, "adjustment_saturation", target["saturation"], TWEEN_DURATION)
	_active_tween.tween_property(env, "adjustment_brightness", target["brightness"], TWEEN_DURATION)
	_active_tween.tween_property(_overlay, "color", target["tint"], TWEEN_DURATION)


func _apply_band_instant(band: int) -> void:
	if world_environment == null:
		return
	var env := world_environment.environment
	if env == null:
		return
	var target: Dictionary = BAND_TARGETS.get(band, BAND_TARGETS[4])
	env.adjustment_saturation = target["saturation"]
	env.adjustment_brightness = target["brightness"]
	if _overlay:
		_overlay.color = target["tint"]


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)
