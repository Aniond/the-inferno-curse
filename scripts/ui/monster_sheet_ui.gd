extends CanvasLayer
## MonsterSheetUI - Test monster status overlay.
## Toggle with the "open_monster_sheet" action (N key).

const BG_IMAGE := preload("res://assets/summer/426cd36b-2c1f-45fa-bde8-163fa2e6bee1/2026-06-23/Y8CAUAYVP5s73_3qixj5Y_wYMRS1pG.png")
const FALLBACK_MONSTER: MonsterSheet = preload("res://data/monsters/training_brigand.tres")
const RESISTANCE_ROWS := ["Physical", "Poison", "Bleed", "Paralyze", "Holy", "Corruption"]
const RESISTANCE_ICONS := {
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
var _is_open: bool = false
var _monster: MonsterSheet


func _ready() -> void:
	layer = 101
	get_viewport().size_changed.connect(_position_sheet_root)

	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_bg_rect = TextureRect.new()
	_bg_rect.name = "Background"
	_bg_rect.texture = BG_IMAGE
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_labels = Control.new()
	_labels.name = "Labels"
	_labels.set_anchors_preset(Control.PRESET_FULL_RECT)
	_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_rect.add_child(_labels)

	hide_sheet()
	await get_tree().process_frame
	_position_sheet_root()
	_create_labels()
	_refresh_all()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_open:
		hide_sheet()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("open_monster_sheet"):
		if _is_open:
			hide_sheet()
		else:
			show_sheet()
		get_viewport().set_input_as_handled()


func show_sheet() -> void:
	_is_open = true
	visible = true
	_refresh_all()


func set_monster(monster: MonsterSheet) -> void:
	_monster = monster
	if _labels != null:
		_refresh_all()


func clear_monster() -> void:
	set_monster(FALLBACK_MONSTER)


func hide_sheet() -> void:
	_is_open = false
	visible = false


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


func _make_label(node_name: String, xf: float, yf: float, wf: float, font_size: int = 18, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl := Label.new()
	lbl.name = node_name
	lbl.position = Vector2(_xf(xf), _yf(yf))
	lbl.size = Vector2(_xf(wf), _yf(0.040))
	lbl.horizontal_alignment = align
	lbl.clip_text = true
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", Color(0.12, 0.08, 0.04, 1.0))
	_labels.add_child(lbl)
	return lbl


func _make_icon(node_name: String, texture: Texture2D, xf: float, yf: float, sf: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = node_name
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(_xf(xf), _yf(yf))
	icon.size = Vector2(_xf(sf), _yf(sf))
	_labels.add_child(icon)
	return icon


func _create_labels() -> void:
	# Unit profile block.
	_make_label("MonsterName", 0.064, 0.304, 0.245, 20, HORIZONTAL_ALIGNMENT_CENTER)
	_make_label("MonsterLevel", 0.245, 0.367, 0.064, 18, HORIZONTAL_ALIGNMENT_CENTER)
	_make_label("MonsterFamily", 0.178, 0.430, 0.125, 18)

	# Combat values layered over the existing template columns.
	var stat_rows := ["HP", "MP", "CT", "Power", "Defense", "Speed", "Strength", "Intellect", "Faith", "XP"]
	for i in range(stat_rows.size()):
		_make_label("Stat_" + stat_rows[i], 0.580, 0.102 + i * 0.039, 0.058, 16, HORIZONTAL_ALIGNMENT_CENTER)

	for i in range(RESISTANCE_ROWS.size()):
		var resistance_name: String = RESISTANCE_ROWS[i]
		_make_icon("ResistanceIcon_" + resistance_name, RESISTANCE_ICONS[resistance_name] as Texture2D, 0.701, 0.107 + i * 0.066, 0.034)
		_make_label("Resistance_" + str(i), 0.750, 0.112 + i * 0.066, 0.178, 13)

	# Ability cards.
	for i in range(4):
		_make_label("Ability_" + str(i), 0.103 + (i % 2) * 0.199, 0.578 + int(i / 2) * 0.196, 0.132, 14)

	# AI tags fit the passive/active utility columns for now.
	for i in range(6):
		_make_label("Tag_" + str(i), 0.530, 0.577 + i * 0.048, 0.115, 13)

	for i in range(6):
		_make_label("Reward_" + str(i), 0.760, 0.590 + i * 0.066, 0.185, 14)


func _refresh_all() -> void:
	var monster := _get_monster()
	if monster == null:
		return

	_set_label("MonsterName", monster.display_name)
	_set_label("MonsterLevel", str(monster.level))
	_set_label("MonsterFamily", monster.family)

	_set_label("Stat_HP", str(monster.max_hp))
	_set_label("Stat_MP", str(monster.max_mp))
	_set_label("Stat_CT", str(monster.starting_ct))
	_set_label("Stat_Power", str(monster.get_power()))
	_set_label("Stat_Defense", str(monster.get_defense()))
	_set_label("Stat_Speed", str(monster.get_speed()))
	_set_label("Stat_Strength", str(monster.core_stats.get_stat("STR")))
	_set_label("Stat_Intellect", str(monster.core_stats.get_stat("INT")))
	_set_label("Stat_Faith", str(monster.core_stats.get_stat("FTH")))
	_set_label("Stat_XP", str(monster.reward_experience))

	for i in range(RESISTANCE_ROWS.size()):
		_set_label("Resistance_" + str(i), "%s  0%%" % RESISTANCE_ROWS[i])

	for i in range(4):
		var ability_text := ""
		if i < monster.abilities.size():
			ability_text = monster.abilities[i]
		_set_label("Ability_" + str(i), ability_text)

	for i in range(6):
		var tag_text := ""
		if i < monster.ai_tags.size():
			tag_text = monster.ai_tags[i].capitalize()
		_set_label("Tag_" + str(i), tag_text)

	var rewards: Array[String] = []
	rewards.append("XP " + str(monster.reward_experience))
	rewards.append("Coin " + str(monster.reward_coin))
	for drop in monster.drop_table:
		rewards.append(drop.capitalize())

	for i in range(6):
		var reward_text := ""
		if i < rewards.size():
			reward_text = rewards[i]
		_set_label("Reward_" + str(i), reward_text)


func _set_label(node_name: String, text: String) -> void:
	var node := _labels.get_node_or_null(node_name)
	if node is Label:
		node.text = text


func _get_monster() -> MonsterSheet:
	if _monster != null:
		return _monster
	return FALLBACK_MONSTER
