extends CanvasLayer
## CharacterSheetUI - Full-screen character status overlay.
## Toggle with the "open_character_sheet" action (Ctrl+C).
## Reads all data from PlayerData autoload.
## Background: res://assets/summer/b6630f53-e376-42a0-9dea-dcdd6b8dd7ce/2026-06-22/JvLheMHJ7Vg9NahOuzTsY_dcaFSBTd.png

const BG_IMAGE := preload("res://assets/summer/b6630f53-e376-42a0-9dea-dcdd6b8dd7ce/2026-06-22/JvLheMHJ7Vg9NahOuzTsY_dcaFSBTd.png")
const EquipPopupScript := preload("res://scripts/ui/equip_popup.gd")
const EquipmentItemScript := preload("res://scripts/data/equipment_item.gd")
const STATUS_TYPES := ["Physical", "Poison", "Bleed", "Paralyze", "Holy", "Corruption"]
const TEXT_Y_OFFSET := -0.004
const STATUS_ICONS := {
	"Physical": preload("res://assets/ui/status_icons/physical.png"),
	"Poison": preload("res://assets/ui/status_icons/poison.png"),
	"Bleed": preload("res://assets/ui/status_icons/bleed.png"),
	"Paralyze": preload("res://assets/ui/status_icons/paralyze.png"),
	"Holy": preload("res://assets/ui/status_icons/holy.png"),
	"Corruption": preload("res://assets/ui/status_icons/corruption.png"),
}
var _overlay: ColorRect
var _bg_rect: TextureRect
var _labels: Control
var _bars: Control

# Gauge fill ColorRects (HP, MP, CT)
var _hp_fill: ColorRect
var _mp_fill: ColorRect
var _ct_fill: ColorRect
var _exp_fill: ColorRect
var _portrait: TextureRect

var _is_open: bool = false
var _player_data: Node
var _active_sheet: CharacterSheet = null  ## When set, refresh reads from this instead of PlayerData.
var _clicks: Control     ## Transparent button overlay for editable slot rows.
var _popup: Control   ## FFT-style picker (EquipPopup) shown over a clicked slot.


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

	# Clickable slot overlay (above labels). Buttons live here so the popup can fire.
	_clicks = Control.new()
	_clicks.name = "Clicks"
	_clicks.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clicks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clicks.z_index = 3
	_bg_rect.add_child(_clicks)

	# Popup picker sits at the top of the CanvasLayer so it overlays everything.
	_popup = EquipPopupScript.new()
	_popup.name = "EquipPopup"
	add_child(_popup)

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
	if event.is_action_pressed("open_character_sheet"):
		if _is_open:
			hide_sheet()
		else:
			show_sheet()
		get_viewport().set_input_as_handled()


func show_sheet() -> void:
	_active_sheet = null
	_is_open = true
	visible = true
	_refresh_all()


## Open the formatted sheet populated from an arbitrary CharacterSheet resource.
func show_sheet_for(sheet: CharacterSheet) -> void:
	_active_sheet = sheet
	_is_open = true
	visible = true
	_refresh_all()


func hide_sheet() -> void:
	_active_sheet = null
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
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = Vector2(_xf(xf), _yf(yf + TEXT_Y_OFFSET))
	lbl.size = Vector2(_xf(0.12), _yf(0.035))
	lbl.clip_text = true
	_labels.add_child(lbl)
	return lbl


func _make_fill(color: Color, xf: float, yf: float, wf: float, hf: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = Vector2(_xf(xf), _yf(yf))
	r.size = Vector2(_xf(wf), _yf(hf))
	_bars.add_child(r)
	return r


func _make_icon(texture: Texture2D, xf: float, yf: float, sf: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(_xf(xf), _yf(yf))
	icon.size = Vector2(_xf(sf), _yf(sf))
	_labels.add_child(icon)
	return icon


func _make_slot_icon(kind: String, xf: float, yf: float, sf: float) -> Control:
	var icon := Control.new()
	icon.name = kind + "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(_xf(xf), _yf(yf))
	var side := _xf(sf)
	icon.size = Vector2(side, side)
	_labels.add_child(icon)

	match kind:
		"Skill":
			_add_icon_diamond(icon, side, Color(0.95, 0.78, 0.28, 1.0))
		"Weapon":
			_add_icon_sword(icon, side)
		"Armor":
			_add_icon_armor(icon, side)
		"Trinket":
			_add_icon_trinket(icon, side)
	return icon


func _add_icon_line(parent: Control, points: PackedVector2Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.points = points
	line.default_color = color
	line.width = width
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	parent.add_child(line)


func _add_icon_diamond(parent: Control, side: float, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(side * 0.50, side * 0.12),
		Vector2(side * 0.64, side * 0.38),
		Vector2(side * 0.88, side * 0.50),
		Vector2(side * 0.64, side * 0.62),
		Vector2(side * 0.50, side * 0.88),
		Vector2(side * 0.36, side * 0.62),
		Vector2(side * 0.12, side * 0.50),
		Vector2(side * 0.36, side * 0.38),
	])
	poly.color = color
	parent.add_child(poly)
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.50, side * 0.12), Vector2(side * 0.64, side * 0.38), Vector2(side * 0.88, side * 0.50), Vector2(side * 0.64, side * 0.62), Vector2(side * 0.50, side * 0.88), Vector2(side * 0.36, side * 0.62), Vector2(side * 0.12, side * 0.50), Vector2(side * 0.36, side * 0.38), Vector2(side * 0.50, side * 0.12)]), Color(0.12, 0.08, 0.05, 1.0), maxf(2.0, side * 0.08))


func _add_icon_sword(parent: Control, side: float) -> void:
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.26, side * 0.78), Vector2(side * 0.76, side * 0.18)]), Color(0.12, 0.08, 0.05, 1.0), maxf(4.0, side * 0.16))
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.26, side * 0.78), Vector2(side * 0.76, side * 0.18)]), Color(0.78, 0.83, 0.86, 1.0), maxf(2.0, side * 0.08))
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.20, side * 0.56), Vector2(side * 0.43, side * 0.80)]), Color(0.82, 0.57, 0.22, 1.0), maxf(3.0, side * 0.12))
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.18, side * 0.84), Vector2(side * 0.28, side * 0.94)]), Color(0.38, 0.20, 0.12, 1.0), maxf(3.0, side * 0.10))


func _add_icon_armor(parent: Control, side: float) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(side * 0.22, side * 0.14),
		Vector2(side * 0.40, side * 0.14),
		Vector2(side * 0.50, side * 0.28),
		Vector2(side * 0.60, side * 0.14),
		Vector2(side * 0.78, side * 0.14),
		Vector2(side * 0.82, side * 0.82),
		Vector2(side * 0.18, side * 0.82),
	])
	poly.color = Color(0.61, 0.66, 0.70, 1.0)
	parent.add_child(poly)
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.22, side * 0.14), Vector2(side * 0.40, side * 0.14), Vector2(side * 0.50, side * 0.28), Vector2(side * 0.60, side * 0.14), Vector2(side * 0.78, side * 0.14), Vector2(side * 0.82, side * 0.82), Vector2(side * 0.18, side * 0.82), Vector2(side * 0.22, side * 0.14)]), Color(0.12, 0.08, 0.05, 1.0), maxf(2.0, side * 0.08))
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.32, side * 0.35), Vector2(side * 0.68, side * 0.35)]), Color(0.35, 0.39, 0.43, 1.0), maxf(2.0, side * 0.06))


func _add_icon_trinket(parent: Control, side: float) -> void:
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.32, side * 0.14), Vector2(side * 0.50, side * 0.32), Vector2(side * 0.68, side * 0.14)]), Color(0.78, 0.59, 0.24, 1.0), maxf(2.0, side * 0.08))
	var jewel := Polygon2D.new()
	jewel.polygon = PackedVector2Array([
		Vector2(side * 0.50, side * 0.30),
		Vector2(side * 0.76, side * 0.46),
		Vector2(side * 0.62, side * 0.78),
		Vector2(side * 0.38, side * 0.78),
		Vector2(side * 0.24, side * 0.46),
	])
	jewel.color = Color(0.55, 0.27, 0.75, 1.0)
	parent.add_child(jewel)
	_add_icon_line(parent, PackedVector2Array([Vector2(side * 0.50, side * 0.30), Vector2(side * 0.76, side * 0.46), Vector2(side * 0.62, side * 0.78), Vector2(side * 0.38, side * 0.78), Vector2(side * 0.24, side * 0.46), Vector2(side * 0.50, side * 0.30)]), Color(0.12, 0.08, 0.05, 1.0), maxf(2.0, side * 0.08))


# ----------------------------------------------------------------- gauge fills

func _create_gauge_fills() -> void:
	# HP / MP / CT fills sit inside the baked meter frames.
	_hp_fill = _make_fill(Color(0.16, 0.50, 0.78, 0.70), 0.440, 0.159, 0.176, 0.017)
	_mp_fill = _make_fill(Color(0.72, 0.15, 0.20, 0.70), 0.440, 0.199, 0.176, 0.017)
	_ct_fill = _make_fill(Color(0.55, 0.55, 0.62, 0.70), 0.440, 0.239, 0.176, 0.017)
	_exp_fill = _make_fill(Color(0.76, 0.58, 0.20, 0.55), 0.531, 0.626, 0.041, 0.023)

	# Portrait inside the PROFILE frame. Clipped to its box so it never overflows.
	_portrait = TextureRect.new()
	_portrait.name = "Portrait"
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.clip_contents = true
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.position = Vector2(_xf(0.092), _yf(0.150))
	_portrait.size = Vector2(_xf(0.180), _yf(0.230))
	_bars.add_child(_portrait)


# ----------------------------------------------------------------- label creation

func _create_all_labels() -> void:
	var pd := _player_data
	if pd == null:
		return

	var hp_val := _make_label("", 0.440, 0.150, HORIZONTAL_ALIGNMENT_CENTER)
	hp_val.name = "HPValue"
	hp_val.size = Vector2(_xf(0.176), _yf(0.035))
	hp_val.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
	var mp_val := _make_label("", 0.440, 0.190, HORIZONTAL_ALIGNMENT_CENTER)
	mp_val.name = "MPValue"
	mp_val.size = Vector2(_xf(0.176), _yf(0.035))
	mp_val.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 1.0))
	var ct_val := _make_label("", 0.440, 0.230, HORIZONTAL_ALIGNMENT_CENTER)
	ct_val.name = "CTValue"
	ct_val.size = Vector2(_xf(0.176), _yf(0.035))
	ct_val.add_theme_color_override("font_color", Color(0.16, 0.13, 0.09, 1.0))

	var stat_rows := ["STR", "SPD", "INT", "FTH", "POW", "DEF", "MOV", "JMP", "EXP"]
	for i in stat_rows.size():
		var stat_name: String = stat_rows[i]
		var val := _make_label("", 0.528, 0.282 + i * 0.040, HORIZONTAL_ALIGNMENT_CENTER)
		val.name = "StatValue_" + stat_name
		val.size = Vector2(_xf(0.052), _yf(0.034))
		val.add_theme_font_size_override("font_size", 13)

	var name_lbl := _make_label(pd.character_name, 0.066, 0.431, HORIZONTAL_ALIGNMENT_CENTER)
	name_lbl.name = "CharName"
	name_lbl.size = Vector2(_xf(0.260), _yf(0.052))
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 0.32, 0.10, 1.0))

	var title_lbl := _make_label(pd.character_title, 0.066, 0.504, HORIZONTAL_ALIGNMENT_CENTER)
	title_lbl.name = "CharTitle"
	title_lbl.size = Vector2(_xf(0.260), _yf(0.052))
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.add_theme_color_override("font_color", Color(0.38, 0.32, 0.22, 1.0))

	for i in range(STATUS_TYPES.size()):
		var elem: String = STATUS_TYPES[i]
		var y_pos := 0.155 + i * 0.072
		var icon := _make_icon(STATUS_ICONS[elem] as Texture2D, 0.692, y_pos, 0.045)
		icon.name = "ResistIcon_" + elem
		var elem_value := _make_label("", 0.760, y_pos + 0.004, HORIZONTAL_ALIGNMENT_CENTER)
		elem_value.name = "ResistValue_" + elem
		elem_value.size = Vector2(_xf(0.180), _yf(0.038))
		elem_value.add_theme_font_size_override("font_size", 14)

	for i in range(4):
		var y_row := 0.696 + i * 0.067
		_make_slot_icon("Skill", 0.066, y_row, 0.040).name = "SkillIcon_" + str(i)
		var skill_label := _make_label("", 0.136, y_row + 0.004, HORIZONTAL_ALIGNMENT_LEFT)
		skill_label.name = "SkillName_" + str(i)
		skill_label.size = Vector2(_xf(0.188), _yf(0.038))
		skill_label.add_theme_font_size_override("font_size", 13)
		_make_slot_button("Skill", str(i), 0.066, y_row, 0.300, 0.052)

	var equipment_slots := ["Weapon", "Armor", "Trinket"]
	for i in equipment_slots.size():
		var slot_name: String = equipment_slots[i]
		var y_row := 0.764 + i * 0.066
		_make_slot_icon(slot_name, 0.375, y_row, 0.040).name = "EquipmentIcon_" + slot_name
		var equipment_label := _make_label("", 0.438, y_row + 0.004, HORIZONTAL_ALIGNMENT_LEFT)
		equipment_label.name = "EquipmentName_" + slot_name
		equipment_label.size = Vector2(_xf(0.196), _yf(0.038))
		equipment_label.add_theme_font_size_override("font_size", 13)
		_make_slot_button("Equipment", slot_name, 0.375, y_row, 0.260, 0.050)

	for i in range(4):
		var y_row := 0.696 + i * 0.067
		var trait_label := _make_label("", 0.750, y_row + 0.004, HORIZONTAL_ALIGNMENT_LEFT)
		trait_label.name = "TraitName_" + str(i)
		trait_label.size = Vector2(_xf(0.196), _yf(0.038))
		trait_label.add_theme_font_size_override("font_size", 13)
		_make_slot_button("Trait", str(i), 0.692, y_row, 0.260, 0.052)


# ----------------------------------------------------------------- refresh

func _refresh_all() -> void:
	if _active_sheet != null:
		_refresh_from_sheet(_active_sheet)
		return

	var pd := _player_data
	if pd == null:
		return

	_set_gauge(_hp_fill, float(pd.hp) / float(maxi(pd.max_hp, 1)), 0.176)
	_set_gauge(_mp_fill, float(pd.mp) / float(maxi(pd.max_mp, 1)), 0.176)
	_set_gauge(_ct_fill, float(pd.ct) / float(maxi(pd.max_ct, 1)), 0.176)
	_set_gauge(_exp_fill, float(pd.experience) / float(maxi(pd.exp_to_next, 1)), 0.041)

	_set_label("HPValue", "%d / %d" % [pd.hp, pd.max_hp])
	_set_label("MPValue", "%d / %d" % [pd.mp, pd.max_mp])
	_set_label("CTValue", "%d / %d" % [pd.ct, pd.max_ct])
	for attr in ["STR", "SPD", "INT", "FTH", "POW", "DEF", "MOV", "JMP"]:
		_set_label("StatValue_" + attr, str(pd.get_attribute(attr)))
	_set_label("StatValue_EXP", str(pd.experience))

	# Info panel
	_set_label("CharName", pd.character_name)
	_set_label("CharTitle", pd.character_title)
	_set_portrait(pd.portrait_path)

	for i in range(4):
		var skill_text := ""
		if i < pd.abilities.size():
			var ab: Dictionary = pd.abilities[i]
			skill_text = ab["name"]
			if not ab.get("unlocked", true):
				skill_text += " (Locked)"
		_set_label("SkillName_" + str(i), skill_text)

	for row in pd.get_equipment_rows():
		var slot_name: String = row["slot"]
		_set_label("EquipmentName_" + slot_name, _format_equipment_label(slot_name, row["item"]))

	# Resistance/status values
	for elem_variant in STATUS_TYPES:
		var elem: String = elem_variant
		_set_label("ResistValue_" + elem, "%d%%" % pd.get_resistance(elem))


func _refresh_from_sheet(s: CharacterSheet) -> void:
	var max_hp := s.get_max_hp()
	var max_mp := s.get_max_mp()
	var max_ct := 100
	# A resource sheet has no live HP/MP/CT — show full bars at max.
	_set_gauge(_hp_fill, 1.0, 0.176)
	_set_gauge(_mp_fill, 1.0, 0.176)
	_set_gauge(_ct_fill, float(s.get_starting_ct()) / float(maxi(max_ct, 1)), 0.176)
	_set_gauge(_exp_fill, float(s.experience) / float(maxi(_exp_to_next(s.level), 1)), 0.041)

	_set_label("HPValue", "%d / %d" % [max_hp, max_hp])
	_set_label("MPValue", "%d / %d" % [max_mp, max_mp])
	_set_label("CTValue", "%d / %d" % [s.get_starting_ct(), max_ct])

	_set_label("StatValue_STR", str(s.get_core_stat("STR")))
	_set_label("StatValue_SPD", str(s.get_core_stat("SPD")))
	_set_label("StatValue_INT", str(s.get_core_stat("INT")))
	_set_label("StatValue_FTH", str(s.get_core_stat("FTH")))
	_set_label("StatValue_POW", str(s.get_power()))
	_set_label("StatValue_DEF", str(s.get_defense()))
	_set_label("StatValue_MOV", str(s.get_movement()))
	_set_label("StatValue_JMP", str(s.get_jump()))
	_set_label("StatValue_EXP", str(s.experience))

	_set_label("CharName", s.display_name)
	_set_label("CharTitle", s.job_title)
	_set_portrait(s.portrait_path)

	for i in range(4):
		var skill_text := ""
		if i < s.equipped_skills.size():
			skill_text = s.equipped_skills[i]
		_set_label("SkillName_" + str(i), skill_text)

	for i in range(4):
		var trait_text := ""
		if i < s.equipped_traits.size():
			trait_text = s.equipped_traits[i]
		_set_label("TraitName_" + str(i), trait_text)

	var armor := s.body
	if armor.strip_edges().is_empty():
		armor = _first_non_empty([s.shield, s.head, s.feet])
	_set_label("EquipmentName_Weapon", _format_equipment_label("Weapon", s.weapon))
	_set_label("EquipmentName_Armor", _format_equipment_label("Armor", armor))
	_set_label("EquipmentName_Trinket", _format_equipment_label("Trinket", s.accessory))

	for elem_variant in STATUS_TYPES:
		var elem: String = elem_variant
		_set_label("ResistValue_" + elem, "0%")


func _exp_to_next(level: int) -> int:
	return maxi(100, level * 100)


func _first_non_empty(values: Array) -> String:
	for v in values:
		var sv := String(v).strip_edges()
		if not sv.is_empty():
			return sv
	return ""


func _format_equipment_label(slot_name: String, item_name: String) -> String:
	var trimmed := item_name.strip_edges()
	if trimmed.is_empty():
		return slot_name
	return "%s: %s" % [slot_name, trimmed]


func _set_gauge(fill: ColorRect, fraction: float, full_wf: float) -> void:
	if fill == null:
		return
	fill.size.x = _xf(full_wf) * clampf(fraction, 0.0, 1.0)


func _set_label(node_name: String, text: String) -> void:
	var node := _labels.get_node_or_null(node_name)
	if node is Label:
		node.text = text


func _set_portrait(path: String) -> void:
	if _portrait == null:
		return
	if path.strip_edges().is_empty():
		_portrait.texture = null
		return
	_portrait.texture = load(path) as Texture2D


# ----------------------------------------------------------------- equip popup

func _make_slot_button(kind: String, key: String, xf: float, yf: float, wf: float, hf: float) -> void:
	var btn := Button.new()
	btn.name = "%sBtn_%s" % [kind, key]
	btn.flat = true
	btn.modulate = Color(1, 1, 1, 0)  # invisible hit area
	btn.position = Vector2(_xf(xf), _yf(yf))
	btn.size = Vector2(_xf(wf), _yf(hf))
	btn.pressed.connect(_on_slot_clicked.bind(kind, key, btn))
	_clicks.add_child(btn)


func _on_slot_clicked(kind: String, key: String, btn: Button) -> void:
	# Only the per-character editable sheet supports equipping.
	if _active_sheet == null or _popup == null:
		return

	var options: Array = []
	var current_id := ""

	match kind:
		"Equipment":
			current_id = _active_sheet.get_equipped_id(key)
			for item in _active_sheet.get_equippable(key):
				options.append({
					"id": item.item_id,
					"label": item.display_name,
					"sub": _equipment_summary(item),
				})
		"Skill", "Trait":
			var equipped: Array = _active_sheet.equipped_traits if kind == "Trait" else _active_sheet.equipped_skills
			var idx := int(key)
			current_id = equipped[idx] if idx < equipped.size() else ""
			for sid in _owned_skill_ids():
				options.append({"id": sid, "label": sid, "sub": ""})

	# Anchor the popup just below-left of the clicked row, in viewport space.
	var anchor := btn.get_global_rect().position + Vector2(0, btn.size.y)
	_popup.open_at(options, current_id, anchor)

	# Reconnect cleanly so only this slot receives the result.
	if _popup.option_chosen.is_connected(_on_option_chosen):
		_popup.option_chosen.disconnect(_on_option_chosen)
	_popup.option_chosen.connect(_on_option_chosen.bind(kind, key), CONNECT_ONE_SHOT)


func _on_option_chosen(chosen_id: String, kind: String, key: String) -> void:
	if _active_sheet == null:
		return
	match kind:
		"Equipment":
			_active_sheet.equip_item(key, chosen_id)
		"Skill":
			_set_slot_array(_active_sheet.equipped_skills, int(key), chosen_id, CharacterSheet.MAX_SKILL_SLOTS)
		"Trait":
			_set_slot_array(_active_sheet.equipped_traits, int(key), chosen_id, CharacterSheet.MAX_TRAIT_SLOTS)
	_refresh_all()


func _set_slot_array(arr: Array, idx: int, value: String, max_slots: int) -> void:
	# Pad to idx, then set or clear.
	while arr.size() <= idx and arr.size() < max_slots:
		arr.append("")
	if idx < arr.size():
		arr[idx] = value
	# Drop trailing empties so the list stays tidy.
	while arr.size() > 0 and String(arr[arr.size() - 1]).is_empty():
		arr.remove_at(arr.size() - 1)


func _owned_skill_ids() -> Array:
	if _active_sheet == null:
		return []
	return _active_sheet.get_all_unlocked_job_skills()


func _equipment_summary(item) -> String:
	var parts: Array[String] = []
	if item.weapon_power > 0: parts.append("PWR+%d" % item.weapon_power)
	if item.pow_bonus > 0:    parts.append("POW+%d" % item.pow_bonus)
	if item.def_bonus > 0:    parts.append("DEF+%d" % item.def_bonus)
	if item.hp_bonus > 0:     parts.append("HP+%d" % item.hp_bonus)
	if item.mp_bonus > 0:     parts.append("MP+%d" % item.mp_bonus)
	if item.spd_bonus > 0:    parts.append("SPD+%d" % item.spd_bonus)
	if item.evasion_bonus > 0 or item.weapon_evasion > 0:
		parts.append("EV+%d%%" % (item.evasion_bonus + item.weapon_evasion))
	return " ".join(parts)


func _on_stats_changed() -> void:
	if _is_open:
		_refresh_all()
