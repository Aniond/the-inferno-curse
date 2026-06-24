extends CanvasLayer
class_name BattleOverlay

signal action_selected(action: String)
signal skill_selected(skill_name: String)
signal item_selected(item_name: String)

const PANEL_BG := Color(0.08, 0.06, 0.05, 0.88)
const PANEL_BORDER := Color(0.55, 0.42, 0.22, 1.0)
const TEXT_MAIN := Color(0.93, 0.88, 0.78, 1.0)
const TEXT_MUTED := Color(0.72, 0.66, 0.56, 1.0)
const ACCENT_MOVE := Color(0.28, 0.55, 0.95, 1.0)
const ACCENT_ROTATE := Color(0.95, 0.82, 0.2, 1.0)
const ACCENT_ATTACK := Color(0.92, 0.28, 0.2, 1.0)
const ACCENT_RANGED := Color(0.95, 0.55, 0.15, 1.0)
const ACCENT_SKILL := Color(0.35, 0.75, 0.55, 1.0)
const ACCENT_ITEM := Color(0.75, 0.55, 0.25, 1.0)
const ACCENT_DEFEND := Color(0.4, 0.55, 0.85, 1.0)
const ACCENT_WAIT := Color(0.5, 0.5, 0.5, 1.0)

var _root: Control
var _round_label: Label
var _turn_label: Label
var _phase_labels: Array[Label] = []
var _player_name_label: Label
var _player_hp_bar: ProgressBar
var _player_hp_value: Label
var _player_ct_bar: ProgressBar
var _player_ct_value: Label
var _player_mov_label: Label
var _enemy_name_label: Label
var _enemy_hp_bar: ProgressBar
var _enemy_hp_value: Label
var _enemy_ct_bar: ProgressBar
var _enemy_ct_value: Label
var _hint_label: RichTextLabel
var _action_label: Label
var _preview_panel: PanelContainer
var _preview_title: Label
var _preview_body: RichTextLabel
var _waiting_label: Label

# Action menu
var _action_menu_panel: PanelContainer
var _submenu_panel: PanelContainer
var _submenu_row: HBoxContainer
var _active_submenu: String = ""  # "skills" | "items" | ""


func _ready() -> void:
	layer = 90
	_build_ui()
	hide()


func _process(_delta: float) -> void:
	# CanvasLayer does not reliably notify its Control children on viewport
	# resize, so the anchored _root can stay (0,0) and never lay out its
	# children. Keep it pinned to the viewport size. Only writes on change.
	if _root == null:
		return
	var vp := get_viewport()
	if vp == null:
		return
	var vsize := vp.get_visible_rect().size
	if _root.size != vsize:
		_root.size = vsize


func show_pre_combat(message: String) -> void:
	show()
	_waiting_label.text = message
	_waiting_label.visible = true
	_root.visible = false


func show_combat() -> void:
	show()
	_waiting_label.visible = false
	_root.visible = true


func hide_combat() -> void:
	hide()
	clear_target_preview()


func update_display(data: Dictionary) -> void:
	if data.get("waiting_message", "") != "":
		show_pre_combat(str(data["waiting_message"]))
		return

	show_combat()
	_round_label.text = "Round %d" % int(data.get("round", 1))
	_turn_label.text = "Active: %s" % str(data.get("active_actor_name", "—"))

	var phase := int(data.get("player_phase", -1))
	_set_phase_highlight(phase, bool(data.get("use_ranged", false)))

	_player_name_label.text = str(data.get("player_name", "Player"))
	_enemy_name_label.text = str(data.get("enemy_name", "Enemy"))

	var player_hp := int(data.get("player_hp", 0))
	var player_max_hp := maxi(1, int(data.get("player_max_hp", 1)))
	var enemy_hp := int(data.get("enemy_hp", 0))
	var enemy_max_hp := maxi(1, int(data.get("enemy_max_hp", 1)))
	_player_hp_bar.max_value = player_max_hp
	_player_hp_bar.value = player_hp
	_player_hp_value.text = "%d / %d" % [player_hp, player_max_hp]
	_enemy_hp_bar.max_value = enemy_max_hp
	_enemy_hp_bar.value = enemy_hp
	_enemy_hp_value.text = "%d / %d" % [enemy_hp, enemy_max_hp]

	var threshold := maxi(1, int(data.get("ct_threshold", 100)))
	var player_ct := int(data.get("player_ct", 0))
	var enemy_ct := int(data.get("enemy_ct", 0))
	_player_ct_bar.max_value = threshold
	_player_ct_bar.value = player_ct
	_player_ct_value.text = "CT %d / %d" % [player_ct, threshold]
	_enemy_ct_bar.max_value = threshold
	_enemy_ct_bar.value = enemy_ct
	_enemy_ct_value.text = "CT %d / %d" % [enemy_ct, threshold]

	_player_mov_label.text = "MOV %d | Facing %s" % [
		int(data.get("player_mov", 0)),
		str(data.get("player_facing", "south")),
	]

	var hint := str(data.get("hint", ""))
	_hint_label.text = hint if hint != "" else " "
	var action := str(data.get("last_action", ""))
	_action_label.text = action if action != "" else "Awaiting orders..."
	_action_label.modulate = TEXT_MAIN if action != "" else TEXT_MUTED


func update_target_preview(preview: Dictionary) -> void:
	if preview.is_empty():
		clear_target_preview()
		return

	_preview_panel.visible = true
	_preview_title.text = "Target: %s" % str(preview.get("target_name", "Enemy"))
	var lines: PackedStringArray = []
	lines.append("Attack arc: [color=#f0c060]%s[/color]" % str(preview.get("arc_label", "front")))
	if bool(preview.get("is_ranged", false)):
		lines.append("Cover: [color=#8ec8ff]%s[/color]" % str(preview.get("cover_label", "No Cover")))
		var height_delta := int(preview.get("height_delta", 0))
		if height_delta > 0:
			lines.append("Height: [color=#7dffb0]+%d advantage[/color]" % height_delta)
		elif height_delta < 0:
			lines.append("Height: [color=#ff8a7d]%d disadvantage[/color]" % height_delta)
		else:
			lines.append("Height: even ground")
	lines.append("Est. damage: [color=#ff6b5e]%d[/color]" % int(preview.get("predicted_damage", 0)))
	_preview_body.text = "\n".join(lines)


func clear_target_preview() -> void:
	_preview_panel.visible = false
	_preview_title.text = "Target Preview"
	_preview_body.text = ""


func update_move_preview(data: Dictionary) -> void:
	_preview_panel.visible = true
	_preview_title.text = "Move Preview"
	if not data.get("reachable", true):
		_preview_body.text = "[color=#907060]Out of reach[/color]"
		return
	var lines: PackedStringArray = []
	var move_cost := int(data.get("move_cost", 0))
	if move_cost > 0:
		lines.append("MOV cost: [color=#f0c060]%d[/color]" % move_cost)
	var targets := data.get("targets", []) as Array
	if targets.is_empty():
		lines.append("[color=#907060]No enemies in range from here[/color]")
	else:
		for t in targets:
			var name_str := str(t.get("name", "Enemy"))
			var melee := bool(t.get("melee", false))
			var ranged := bool(t.get("ranged", false))
			var arc := str(t.get("arc_label", ""))
			var range_str := ""
			if melee:
				range_str = "[color=#7dffb0]melee[/color]"
				if arc != "":
					range_str += " (%s)" % arc
			elif ranged:
				range_str = "[color=#8ec8ff]ranged[/color]"
			else:
				range_str = "[color=#ff8a7d]out of range[/color]"
			lines.append("%s: %s" % [name_str, range_str])
	_preview_body.text = "\n".join(lines)


func clear_move_preview() -> void:
	_preview_panel.visible = false
	_preview_body.text = ""


func update_rotate_preview(data: Dictionary) -> void:
	_preview_panel.visible = true
	var facing := str(data.get("facing", "south")).capitalize()
	_preview_title.text = "Facing: %s" % facing
	var lines: PackedStringArray = []
	var targets := data.get("targets", []) as Array
	if targets.is_empty():
		lines.append("[color=#907060]No enemies visible[/color]")
	else:
		for t in targets:
			var name_str := str(t.get("name", "Enemy"))
			var arc := str(t.get("arc_label", "front"))
			var bonus := int(t.get("arc_bonus", 0))
			var arc_color := "#ff6b5e"
			if bonus >= 20:
				arc_color = "#cc88ff"
			elif bonus >= 10:
				arc_color = "#f0c060"
			var bonus_str := " (+%d%% hit)" % bonus if bonus > 0 else ""
			lines.append("%s: [color=%s]%s[/color]%s" % [name_str, arc_color, arc, bonus_str])
	_preview_body.text = "\n".join(lines)


func clear_rotate_preview() -> void:
	_preview_panel.visible = false
	_preview_body.text = ""


func _set_phase_highlight(player_phase: int, use_ranged: bool) -> void:
	var phases := ["MOVE", "ROTATE", "ATTACK"]
	for index in _phase_labels.size():
		var label := _phase_labels[index]
		var active := index == player_phase
		label.modulate = TEXT_MAIN if active else TEXT_MUTED
		if index == 0 and active:
			label.add_theme_color_override("font_color", ACCENT_MOVE)
		elif index == 1 and active:
			label.add_theme_color_override("font_color", ACCENT_ROTATE)
		elif index == 2 and active:
			var attack_color := ACCENT_RANGED if use_ranged else ACCENT_ATTACK
			label.add_theme_color_override("font_color", attack_color)
		else:
			label.add_theme_color_override("font_color", TEXT_MUTED if not active else TEXT_MAIN)
		if index == 2:
			label.text = "ATTACK (%s)" % ("RANGED" if use_ranged else "MELEE")


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	_root.offset_right = 0.0
	_root.offset_bottom = 0.0
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.clip_contents = false
	add_child(_root)

	_waiting_label = _make_label("Click or arrow keys to move on the grid. Approach the Training Brigand to fight.", 22)
	_waiting_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_waiting_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_waiting_label.set_anchors_preset(Control.PRESET_CENTER)
	_waiting_label.position = Vector2(-280, -20)
	_waiting_label.size = Vector2(560, 40)
	add_child(_waiting_label)

	var top_panel := _make_panel()
	top_panel.position = Vector2(16, 16)
	top_panel.size = Vector2(520, 72)
	_root.add_child(top_panel)
	var top_vbox := _make_vbox(10)
	top_panel.add_child(top_vbox)
	_round_label = _make_label("Round 1", 20)
	_turn_label = _make_label("Active: —", 18)
	top_vbox.add_child(_round_label)
	top_vbox.add_child(_turn_label)
	var phase_row := HBoxContainer.new()
	phase_row.add_theme_constant_override("separation", 12)
	top_vbox.add_child(phase_row)
	for phase_name in ["MOVE", "ROTATE", "ATTACK"]:
		var phase_label := _make_label(phase_name, 16)
		_phase_labels.append(phase_label)
		phase_row.add_child(phase_label)

	var player_panel := _make_panel()
	player_panel.position = Vector2(16, 100)
	player_panel.size = Vector2(280, 150)
	_root.add_child(player_panel)
	var player_vbox := _make_vbox(8)
	player_panel.add_child(player_vbox)
	_player_name_label = _make_label("Player", 18)
	player_vbox.add_child(_player_name_label)
	_player_hp_bar = _make_bar(ACCENT_MOVE)
	player_vbox.add_child(_player_hp_bar)
	_player_hp_value = _make_label("HP", 14)
	player_vbox.add_child(_player_hp_value)
	_player_ct_bar = _make_bar(ACCENT_ROTATE)
	player_vbox.add_child(_player_ct_bar)
	_player_ct_value = _make_label("CT", 14)
	player_vbox.add_child(_player_ct_value)
	_player_mov_label = _make_label("MOV", 14)
	player_vbox.add_child(_player_mov_label)

	var enemy_panel := _make_panel()
	enemy_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	enemy_panel.offset_left = -296
	enemy_panel.offset_top = 100
	enemy_panel.offset_right = -16
	enemy_panel.offset_bottom = 250
	_root.add_child(enemy_panel)
	var enemy_vbox := _make_vbox(8)
	enemy_panel.add_child(enemy_vbox)
	_enemy_name_label = _make_label("Enemy", 18)
	enemy_vbox.add_child(_enemy_name_label)
	_enemy_hp_bar = _make_bar(ACCENT_ATTACK)
	enemy_vbox.add_child(_enemy_hp_bar)
	_enemy_hp_value = _make_label("HP", 14)
	enemy_vbox.add_child(_enemy_hp_value)
	_enemy_ct_bar = _make_bar(Color(0.75, 0.35, 0.85, 1.0))
	enemy_vbox.add_child(_enemy_ct_bar)
	_enemy_ct_value = _make_label("CT", 14)
	enemy_vbox.add_child(_enemy_ct_value)

	var bottom_panel := _make_panel()
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_top = -190
	bottom_panel.offset_bottom = -16
	bottom_panel.offset_left = 16
	bottom_panel.offset_right = -16
	_root.add_child(bottom_panel)
	var bottom_vbox := _make_vbox(8)
	bottom_panel.add_child(bottom_vbox)
	_hint_label = RichTextLabel.new()
	_hint_label.fit_content = true
	_hint_label.scroll_active = false
	_hint_label.bbcode_enabled = true
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(0, 72)
	_hint_label.add_theme_color_override("default_color", TEXT_MAIN)
	_hint_label.add_theme_font_size_override("normal_font_size", 15)
	bottom_vbox.add_child(_hint_label)
	_action_label = _make_label("Awaiting orders...", 16)
	bottom_vbox.add_child(_action_label)

	_preview_panel = _make_panel()
	_preview_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_preview_panel.offset_left = -296
	_preview_panel.offset_top = 262
	_preview_panel.offset_right = -16
	_preview_panel.offset_bottom = 412
	_preview_panel.visible = false
	_root.add_child(_preview_panel)
	var preview_vbox := _make_vbox(6)
	_preview_panel.add_child(preview_vbox)
	_preview_title = _make_label("Target Preview", 17)
	preview_vbox.add_child(_preview_title)
	_preview_body = RichTextLabel.new()
	_preview_body.fit_content = true
	_preview_body.scroll_active = false
	_preview_body.bbcode_enabled = true
	_preview_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_body.custom_minimum_size = Vector2(0, 90)
	_preview_body.add_theme_color_override("default_color", TEXT_MAIN)
	_preview_body.add_theme_font_size_override("normal_font_size", 14)
	preview_vbox.add_child(_preview_body)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_vbox(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", TEXT_MAIN)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.12, 0.1, 1.0)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


# --- Action Menu ---

func show_action_menu(skills: Array, items: Array) -> void:
	_build_action_menu(skills, items)
	_action_menu_panel.visible = true
	_submenu_panel.visible = false
	_active_submenu = ""


func hide_action_menu() -> void:
	if _action_menu_panel != null:
		_action_menu_panel.visible = false
	if _submenu_panel != null:
		_submenu_panel.visible = false
	_active_submenu = ""


func _build_action_menu(skills: Array, items: Array) -> void:
	if _action_menu_panel != null:
		_action_menu_panel.queue_free()
		_action_menu_panel = null
	if _submenu_panel != null:
		_submenu_panel.queue_free()
		_submenu_panel = null

	# Submenu panel (skills/items row) — sits just above the action menu
	_submenu_panel = _make_panel()
	_submenu_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_submenu_panel.offset_left = 16
	_submenu_panel.offset_right = -16
	_submenu_panel.offset_top = -290
	_submenu_panel.offset_bottom = -216
	_submenu_panel.visible = false
	_root.add_child(_submenu_panel)
	_submenu_row = HBoxContainer.new()
	_submenu_row.add_theme_constant_override("separation", 10)
	_submenu_panel.add_child(_submenu_row)

	# Main action menu panel
	_action_menu_panel = _make_panel()
	_action_menu_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_action_menu_panel.offset_left = 16
	_action_menu_panel.offset_right = -16
	_action_menu_panel.offset_top = -210
	_action_menu_panel.offset_bottom = -196
	_root.add_child(_action_menu_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_action_menu_panel.add_child(row)

	_add_action_btn(row, "Attack", ACCENT_ATTACK, func():
		hide_action_menu()
		action_selected.emit("attack")
	)
	_add_action_btn(row, "Skills", ACCENT_SKILL, func():
		_toggle_submenu("skills", skills, ACCENT_SKILL)
	)
	_add_action_btn(row, "Items", ACCENT_ITEM, func():
		_toggle_submenu("items", items, ACCENT_ITEM)
	)
	_add_action_btn(row, "Defend", ACCENT_DEFEND, func():
		hide_action_menu()
		action_selected.emit("defend")
	)
	_add_action_btn(row, "Wait", ACCENT_WAIT, func():
		hide_action_menu()
		action_selected.emit("wait")
	)


func _toggle_submenu(kind: String, entries: Array, accent: Color) -> void:
	if _active_submenu == kind:
		_submenu_panel.visible = false
		_active_submenu = ""
		return

	_active_submenu = kind
	for child in _submenu_row.get_children():
		child.queue_free()

	if entries.is_empty():
		var empty_lbl := _make_label("(none)", 15)
		empty_lbl.modulate = TEXT_MUTED
		_submenu_row.add_child(empty_lbl)
	else:
		for entry in entries:
			var entry_name := str(entry)
			_add_action_btn(_submenu_row, entry_name, accent, func():
				hide_action_menu()
				if kind == "skills":
					skill_selected.emit(entry_name)
				else:
					item_selected.emit(entry_name)
			)

	_submenu_panel.visible = true


func _add_action_btn(parent: Control, label: String, accent: Color, callback: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(100, 42)
	btn.add_theme_font_size_override("font_size", 16)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r * 0.25, accent.g * 0.25, accent.b * 0.25, 0.92)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(accent.r * 0.45, accent.g * 0.45, accent.b * 0.45, 0.95)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(5)
	hover.content_margin_left = 8
	hover.content_margin_right = 8
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.pressed.connect(callback)
	parent.add_child(btn)