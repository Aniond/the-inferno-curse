extends Node

const BURST_DURATION := 10.0
const INTERVAL := 1.0
const SAVE_DIR := "C:/Users/david/OneDrive/Desktop/snippets"

var _active := false
var _elapsed := 0.0
var _next_shot := 0.0
var _shot_index := 0
var _session_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= _next_shot:
		_capture()
		_next_shot += INTERVAL
	if _elapsed >= BURST_DURATION:
		_active = false
		print("Screenshot burst complete: %d shots in %s/" % [_shot_index, SAVE_DIR])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed:
		var key := (event as InputEventKey).keycode
		if key == KEY_F12:
			_start_burst()
			get_viewport().set_input_as_handled()
		elif key == KEY_F11:
			_single_shot()
			get_viewport().set_input_as_handled()


func _single_shot() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var timestamp := Time.get_ticks_msec()
	var path := "%s/shot_%d.png" % [SAVE_DIR, timestamp]
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("Screenshot saved: %s" % path)


func _start_burst() -> void:
	_session_id = "burst_%d" % Time.get_ticks_msec()
	_active = true
	_elapsed = 0.0
	_next_shot = 0.0
	_shot_index = 0
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	print("Screenshot burst started. Saving to %s/" % SAVE_DIR)


func _capture() -> void:
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%s_%02d.png" % [SAVE_DIR, _session_id, _shot_index]
	img.save_png(path)
	print("Shot %02d saved: %s" % [_shot_index, path])
	_shot_index += 1
