extends CanvasLayer
## CharacterSheetUI - Full-screen character status overlay.
## Toggle with the "open_character_sheet" action (C key).
## Reads all data from PlayerData autoload.
## Background: res://assets/images/edited-blank-ui-bars.png

const BG_IMAGE := preload("res://assets/images/edited-blank-ui-bars.png")
var _overlay: ColorRect
var _bg_rect: TextureRect
var _labels: Control
var _bars: Control

# Gauge fill ColorRects (HP, MP, CT)
var _hp_fill: ColorRect
var _mp_fill: ColorRect
var _ct_fill: ColorRect

# Elemental resistance fills
var _resist_fills: Dictionary = {}

var _is_open: bool = false
var _player_data: Node


func _ready() -> void:
	layer = 100
	get_viewport().size_changed.connect(_position_sheet_root)

	# Dark backdrop overlay
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# Background image - the art is square, so the overlay controls live in
	# the same square coordinate space instead of the full viewport.
	_bg_rect = TextureRect.new()
	_bg_rect.name = "Background"
	_bg_rect.texture = BG_IMAGE
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	# Bars render under text, but above the parchment template.
	_bars = Control.new()
	_bars.name = "Bars"
	_bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars.z_index = 1
	_bg_rect.add_child(_bars)

	# Containers for positioned labels and bars.
	_labels = Control.new()
	_labels.name = "Labels"
	_labels.set_anchors_preset(Control.PRESET_FULL_RECT)
	_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_labels.z_index = 2
	_bg_rect.add_child(_labels)

	_player_data = get_node_or_null("/root/PlayerData")
	if _player_data == null:
		push_error("CharacterSheetUI requires the PlayerData autoload.")
		hide_sheet()
		return

	_player_data.stats_changed.connect(_on_stats_changed)
	hide_sheet()

	# Wait for Controls to get their layout size before positioning children.
	await get_tree().process_frame
	_position_sheet_root()
	_create_gauge_fills()
	_create_all_labels()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_open:
		hide_sheet()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("open_character_sheet"):
		if _is_open:
			hide_sheet()
		else:
			show_sheet()
		get_viewport().set_input_as_handled()


func show_sheet() -> void:
	_is_open = true
	visible = true
	_refresh_all()


func hide_sheet() -> void:
	_is_open = false
	visible = false


# ----------------------------------------------------------------- helpers


func _position_sheet_root() -> void:
	if _bg_rect == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var sheet_size := minf(viewport_size.x, viewport_size.y) * 0.96
	_bg_rect.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_bg_rect.size = Vector2(sheet_size, sheet_size)
	_bg_rect.position = (viewport_size - _bg_rect.size) * 0.5


func _xf(f: float) -> float:
	return _bg_rect.size.x * f


func _yf(f: float) -> float:
	return _bg_rect.size.y * f


func _make_label(text: String, xf: float, yf: float, h_align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.13, 0.10, 0.06, 1.0))
	lbl.horizontal_alignment = h_align
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = Vector2(_xf(xf), _yf(yf))
	lbl.size = Vector2(_xf(0.12), _yf(0.035))
	_labels.add_child(lbl)
	return lbl


func _make_heading(text: String, xf: float, yf: float, wf: float) -> Label:
	var lbl := _make_label(text, xf, yf)
	lbl.size = Vector2(_xf(wf), _yf(0.040))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.28, 0.16, 0.07, 1.0))
	return lbl


func _make_fill(color: Color, xf: float, yf: float, wf: float, hf: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = Vector2(_xf(xf), _yf(yf))
	r.size = Vector2(_xf(wf), _yf(hf))
	_bars.add_child(r)
	return r


# ----------------------------------------------------------------- gauge fills

func _create_gauge_fills() -> void:
	# HP / MP / CT bars - left page, right of portrait
	_hp_fill = _make_fill(Color(0.16, 0.50, 0.78, 0.62), 0.300, 0.285, 0.145, 0.026)
	_mp_fill = _make_fill(Color(0.72, 0.15, 0.20, 0.62), 0.300, 0.350, 0.145, 0.026)
	_ct_fill = _make_fill(Color(0.55, 0.55, 0.62, 0.62), 0.300, 0.415, 0.145, 0.026)

	# Elemental resistance fills - far-right vertical strip
	var elems := ["Physical", "Fire", "Ice", "Thunder", "Holy", "Dark"]
	for i in range(elems.size()):
		var yf_pos := 0.415 + i * 0.065
		var fill := _make_fill(Color(0.30, 0.15, 0.10, 0.45), 0.895, yf_pos, 0.055, 0.014)
		_resist_fills[elems[i]] = fill


# ----------------------------------------------------------------- label creation

func _create_all_labels() -> void:
	var pd := _player_data
	if pd == null:
		return
	# The background is art-only. All readable text is generated here so no
	# stale template names, test values, or hallucinated text can leak through.

	# --- LEFT PAGE ---
	var lv_label := _make_label("Lv.", 0.315, 0.170)
	lv_label.name = "LevelLabel"
	var exp_label := _make_label("Exp.", 0.315, 0.225)
	exp_label.name = "ExpLabel"
	var hp_label := _make_label("Hp", 0.275, 0.280)
	hp_label.name = "HPLabel"
	var mp_label := _make_label("Mp", 0.275, 0.345)
	mp_label.name = "MPLabel"
	var ct_label := _make_label("CT", 0.275, 0.410)
	ct_label.name = "CTLabel"

	var lv_val := _make_label("", 0.385, 0.170, HORIZONTAL_ALIGNMENT_LEFT)
	lv_val.name = "LevelValue"
	var exp_val := _make_label("", 0.385, 0.225, HORIZONTAL_ALIGNMENT_LEFT)
	exp_val.name = "ExpValue"

	var hp_val := _make_label("", 0.300, 0.280, HORIZONTAL_ALIGNMENT_CENTER)
	hp_val.name = "HPValue"
	hp_val.size = Vector2(_xf(0.145), _yf(0.035))
	hp_val.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
	var mp_val := _make_label("", 0.300, 0.345, HORIZONTAL_ALIGNMENT_CENTER)
	mp_val.name = "MPValue"
	mp_val.size = Vector2(_xf(0.145), _yf(0.035))
	mp_val.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
	var ct_val := _make_label("", 0.300, 0.410, HORIZONTAL_ALIGNMENT_CENTER)
	ct_val.name = "CTValue"
	ct_val.size = Vector2(_xf(0.145), _yf(0.035))
	ct_val.add_theme_color_override("font_color", Color(0.16, 0.13, 0.09, 1.0))

	var attr_a := ["STR", "SPD", "INT", "FTH", "ATK", "DEF"]
	for i in attr_a.size():
		var y_row := 0.515 + i * 0.052
		var name := _make_label(attr_a[i], 0.085, y_row, HORIZONTAL_ALIGNMENT_LEFT)
		name.name = "Label_A_" + attr_a[i]
		var val := _make_label(str(pd.get_attribute(attr_a[i])), 0.112, y_row, HORIZONTAL_ALIGNMENT_CENTER)
		val.name = "Val_A_" + attr_a[i]

	var attr_b := ["CRT", "PRS", "POW", "DEF", "MOV", "JMP"]
	for i in attr_b.size():
		var y_row := 0.515 + i * 0.052
		var name := _make_label(attr_b[i], 0.325, y_row, HORIZONTAL_ALIGNMENT_LEFT)
		name.name = "Label_B_" + attr_b[i]
		var val := _make_label(str(pd.get_attribute(attr_b[i])), 0.365, y_row, HORIZONTAL_ALIGNMENT_CENTER)
		val.name = "Val_B_" + attr_b[i]

	# --- RIGHT PAGE ---
	# Character name + title in the info panel
	var name_lbl := _make_label(pd.character_name, 0.555, 0.135, HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.name = "CharName"
	name_lbl.size = Vector2(_xf(0.340), _yf(0.050))
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 0.32, 0.10, 1.0))

	var title_lbl := _make_label(pd.character_title, 0.555, 0.205, HORIZONTAL_ALIGNMENT_CENTER)
	title_lbl.name = "CharTitle"
	title_lbl.size = Vector2(_xf(0.340), _yf(0.040))
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.38, 0.32, 0.22, 1.0))

	var info_lbl := _make_label("", 0.555, 0.280, HORIZONTAL_ALIGNMENT_CENTER)
	info_lbl.name = "InfoLine"
	info_lbl.size = Vector2(_xf(0.340), _yf(0.040))

	var ability_heading := _make_heading("Ability", 0.535, 0.390, 0.190)
	ability_heading.name = "AbilityHeading"
	var at_heading := _make_label("AT", 0.735, 0.390, HORIZONTAL_ALIGNMENT_CENTER)
	at_heading.name = "ATHeading"
	var cev_heading := _make_label("C-EV", 0.795, 0.390, HORIZONTAL_ALIGNMENT_CENTER)
	cev_heading.name = "CEVHeading"

	# Ability rows (6 slots) - names and AT / C-EV values
	for i in range(6):
		var y_row := 0.455 + i * 0.065
		var ab_name := _make_label("", 0.535, y_row, HORIZONTAL_ALIGNMENT_LEFT)
		ab_name.name = "AbName_" + str(i)
		ab_name.size = Vector2(_xf(0.180), _yf(0.035))
		var ab_at := _make_label("", 0.735, y_row, HORIZONTAL_ALIGNMENT_CENTER)
		ab_at.name = "AbAT_" + str(i)
		ab_at.size = Vector2(_xf(0.050), _yf(0.035))
		var ab_cev := _make_label("", 0.795, y_row, HORIZONTAL_ALIGNMENT_CENTER)
		ab_cev.name = "AbCEV_" + str(i)
		ab_cev.size = Vector2(_xf(0.060), _yf(0.035))

	var resist_heading := _make_heading("Resist", 0.895, 0.350, 0.080)
	resist_heading.name = "ResistHeading"
	var elems := ["Physical", "Fire", "Ice", "Thunder", "Holy", "Dark"]
	for i in range(elems.size()):
		var y_pos := 0.388 + i * 0.065
		var elem_label := _make_label(elems[i], 0.895, y_pos, HORIZONTAL_ALIGNMENT_LEFT)
		elem_label.name = "ResistLabel_" + elems[i]
		elem_label.size = Vector2(_xf(0.090), _yf(0.030))


# ----------------------------------------------------------------- refresh

func _refresh_all() -> void:
	var pd := _player_data
	if pd == null:
		return

	_set_gauge(_hp_fill, float(pd.hp) / float(maxi(pd.max_hp, 1)), 0.145)
	_set_gauge(_mp_fill, float(pd.mp) / float(maxi(pd.max_mp, 1)), 0.145)
	_set_gauge(_ct_fill, float(pd.ct) / float(maxi(pd.max_ct, 1)), 0.145)

	_set_label("HPValue", "%d / %d" % [pd.hp, pd.max_hp])
	_set_label("MPValue", "%d / %d" % [pd.mp, pd.max_mp])
	_set_label("CTValue", "%d / %d" % [pd.ct, pd.max_ct])
	_set_label("LevelValue", "%02d" % pd.level)
	_set_label("ExpValue", "%d / %d" % [pd.experience, pd.exp_to_next])

	# Attributes
	for attr in ["STR", "SPD", "INT", "FTH", "ATK", "DEF"]:
		_set_label("Val_A_" + attr, str(pd.get_attribute(attr)))
	for attr in ["CRT", "PRS", "POW", "DEF", "MOV", "JMP"]:
		_set_label("Val_B_" + attr, str(pd.get_attribute(attr)))

	# Info panel
	_set_label("CharName", pd.character_name)
	_set_label("CharTitle", pd.character_title)
	_set_label("InfoLine", "Lv. %d    Exp  %d / %d    CRT %d%%" % [pd.level, pd.experience, pd.exp_to_next, pd.critical_rate])

	# Abilities
	for i in range(pd.abilities.size()):
		if i >= 6:
			break
		var ab: Dictionary = pd.abilities[i]
		var name_str: String = ab["name"]
		if not ab.get("unlocked", true):
			name_str += "  (Locked)"
		_set_label("AbName_" + str(i), name_str)
		_set_label("AbAT_" + str(i), str(ab["at_cost"]))
		_set_label("AbCEV_" + str(i), ab["cev"])

	# Elemental resistances
	for elem in ["Physical", "Fire", "Ice", "Thunder", "Holy", "Dark"]:
		if _resist_fills.has(elem):
			var frac := float(pd.get_resistance(elem)) / 100.0
			_set_gauge(_resist_fills[elem], frac, 0.055)


func _set_gauge(fill: ColorRect, fraction: float, full_wf: float) -> void:
	if fill == null:
		return
	fill.size.x = _xf(full_wf) * clampf(fraction, 0.0, 1.0)


func _set_label(node_name: String, text: String) -> void:
	var node := _labels.get_node_or_null(node_name)
	if node is Label:
		node.text = text


func _on_stats_changed() -> void:
	if _is_open:
		_refresh_all()
