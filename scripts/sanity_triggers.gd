extends Node
## SanityTriggers — scene-level wiring for sanity event triggers and debug recovery.
## Ambient timer fires limbo_ambient_fade every 4 minutes.
## Press Y to fire limbo_dante_echo (story beat test).
## Press U to recover via inn rest.

@onready var _debug_label: Label = $SanityDebugUI/Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SanityEventBus.sanity_changed.connect(_on_sanity_changed)
	SanityEventBus.band_changed.connect(_on_band_changed)
	_refresh_debug()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Y:
				SanityEventBus.trigger("limbo_dante_echo")
			KEY_U:
				SanityEventBus.recover("inn")


func _on_ambient_timer_timeout() -> void:
	SanityEventBus.trigger("limbo_ambient_fade")


func _on_sanity_changed(_new_value: int, _delta: int) -> void:
	_refresh_debug()


func _on_band_changed(_new_band: int) -> void:
	_refresh_debug()


func _refresh_debug() -> void:
	if _debug_label == null:
		return
	var sanity := SanityEventBus.get_current_sanity()
	var band := SanityEventBus.get_current_band()
	var band_names := {4: "Stable", 3: "Unsettled", 2: "Fractured", 1: "Breaking"}
	_debug_label.text = "Sanity: %d  [%s]\nY=echo  U=inn rest" % [sanity, band_names.get(band, "?")]


func _on_zone_body_entered(_body: Node3D) -> void:
	SanityEventBus.trigger("limbo_river_pale")
