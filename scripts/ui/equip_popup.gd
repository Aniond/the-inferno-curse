extends Control
class_name EquipPopup
## FFT-style anchored picker. Call open_at() with a list of options; emits
## option_chosen(id) when the player clicks one, or closes silently on
## click-away / Esc. id == "" means "unequip / none".

signal option_chosen(id: String)

const COLOR_PANEL    := Color(0.10, 0.08, 0.05, 0.97)
const COLOR_BORDER   := Color(0.72, 0.55, 0.25, 1.0)
const COLOR_ROW_HOV  := Color(0.22, 0.18, 0.11, 1.0)
const COLOR_CURRENT  := Color(0.25, 0.45, 0.25, 0.9)
const COLOR_TEXT     := Color(0.88, 0.83, 0.72, 1.0)
const COLOR_SUB      := Color(0.55, 0.50, 0.40, 1.0)

const ROW_HEIGHT     := 30
const POPUP_WIDTH    := 240
const MAX_VISIBLE     := 7

var _panel: PanelContainer
var _vbox: VBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP  # eat click-away
	visible = false


## options: Array of { "id": String, "label": String, "sub": String }
## current_id: which option is currently equipped (highlighted)
## screen_pos: top-left anchor in this Control's coordinate space
func open_at(options: Array, current_id: String, screen_pos: Vector2) -> void:
	_clear()

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var row_count: int = min(options.size() + 1, MAX_VISIBLE)
	scroll.custom_minimum_size = Vector2(POPUP_WIDTH, row_count * ROW_HEIGHT)
	_panel.add_child(scroll)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 1)
	_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_vbox)

	# "None" row to unequip
	_add_row("", "— none —", "", current_id == "")
	for opt in options:
		var oid: String = opt.get("id", "")
		_add_row(oid, opt.get("label", oid), opt.get("sub", ""), oid == current_id)

	# Position, keeping it on-screen.
	visible = true
	await get_tree().process_frame
	var size_now := _panel.size
	var vp := get_viewport_rect().size
	var pos := screen_pos
	pos.x = clampf(pos.x, 4, vp.x - size_now.x - 4)
	pos.y = clampf(pos.y, 4, vp.y - size_now.y - 4)
	_panel.position = pos


func _add_row(id: String, label: String, sub: String, is_current: bool) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = label if sub.is_empty() else "%s   %s" % [label, sub]
	btn.add_theme_color_override("font_color", COLOR_TEXT)
	btn.add_theme_font_size_override("font_size", 13)

	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_CURRENT if is_current else Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = COLOR_ROW_HOV
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)

	btn.pressed.connect(func():
		option_chosen.emit(id)
		close()
	)
	_vbox.add_child(btn)


func close() -> void:
	visible = false
	_clear()


func _clear() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	_vbox = null


func _gui_input(event: InputEvent) -> void:
	# Click anywhere outside the panel closes without choosing.
	if event is InputEventMouseButton and event.pressed:
		if _panel == null or not _panel.get_global_rect().has_point(event.global_position):
			close()
			accept_event()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
