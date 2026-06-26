extends CanvasLayer
## CharacterScreen — 4-tab character detail screen.
## Opened by PartySelectUI when a portrait card is clicked.
## Tabs: STATUS / EQUIP / JOBS / SKILLS

const BG_IMAGE     := preload("res://assets/summer/5446dd57-b67b-47c3-9274-2c0572d27fe5/2026-06-25/UsPTPk0OW0cwr0BmWwM50_rbMUJKpP.png")

const STATUS_ICONS := {
	"Physical": preload("res://assets/ui/status_icons/physical.png"),
	"Poison":   preload("res://assets/ui/status_icons/poison.png"),
	"Bleed":    preload("res://assets/ui/status_icons/bleed.png"),
	"Paralyze": preload("res://assets/ui/status_icons/paralyze.png"),
	"Holy":     preload("res://assets/ui/status_icons/holy.png"),
	"Corruption": preload("res://assets/ui/status_icons/corruption.png"),
}

const COLOR_INK      := Color(0.13, 0.10, 0.06, 1.0)
const COLOR_HEADER   := Color(0.35, 0.22, 0.08, 1.0)
const COLOR_MUTED    := Color(0.40, 0.34, 0.24, 1.0)
const COLOR_GOLD     := Color(0.72, 0.55, 0.25, 1.0)
const COLOR_TAB_ACT  := Color(0.20, 0.15, 0.08, 0.85)
const COLOR_TAB_IDLE := Color(0.10, 0.08, 0.04, 0.55)
const COLOR_HP       := Color(0.25, 0.50, 0.80, 1.0)
const COLOR_MP       := Color(0.70, 0.28, 0.28, 1.0)
const COLOR_CT       := Color(0.50, 0.50, 0.50, 1.0)
const COLOR_BAR_BG   := Color(0.18, 0.14, 0.09, 0.8)
const COLOR_EQUIPPED := Color(0.25, 0.55, 0.25, 1.0)
const COLOR_LOCKED   := Color(0.38, 0.32, 0.24, 1.0)

const TABS := ["STATUS", "EQUIP", "JOBS", "SKILLS"]

var _sheet: CharacterSheet = null
var _active_tab: int = 0
var _selected_job_id: String = ""
var _is_open: bool = false

var _root: Control
var _bg: TextureRect
var _tab_btns: Array[Button] = []
var _content: Control

# Jobs tab state
var _job_skill_list: VBoxContainer
var _job_detail: Label


func _ready() -> void:
	layer = 101
	visible = false
	_build_chrome()


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_right"):
		_switch_tab((_active_tab + 1) % TABS.size())
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_focus_prev") or event.is_action_pressed("ui_left"):
		_switch_tab((_active_tab - 1 + TABS.size()) % TABS.size())
		get_viewport().set_input_as_handled()


func open(sheet: CharacterSheet) -> void:
	_sheet = sheet
	_is_open = true
	visible = true
	_switch_tab(0)


func close() -> void:
	_is_open = false
	visible = false


# ── Chrome (background + tabs) ──────────────────────────────────────────────

func _build_chrome() -> void:
	const MARGIN := 48

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	_bg = TextureRect.new()
	_bg.texture = BG_IMAGE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.offset_left = MARGIN
	_bg.offset_right = -MARGIN
	_bg.offset_top = MARGIN
	_bg.offset_bottom = -MARGIN
	add_child(_bg)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = MARGIN
	_root.offset_right = -MARGIN
	_root.offset_top = MARGIN
	_root.offset_bottom = -MARGIN
	add_child(_root)

	# Tab bar
	var tab_y := 8.0
	var tab_x := 8.0
	var tab_w := 110.0
	var tab_h := 30.0
	_tab_btns = []
	for i in TABS.size():
		var btn := Button.new()
		btn.text = TABS[i]
		btn.position = Vector2(tab_x + i * (tab_w + 4), tab_y)
		btn.size = Vector2(tab_w, tab_h)
		btn.add_theme_color_override("font_color", COLOR_INK)
		btn.pressed.connect(_switch_tab.bind(i))
		_root.add_child(btn)
		_tab_btns.append(btn)

	# Content area — anchored so it fills _root below the tab bar
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.offset_top = tab_y + tab_h + 8
	_content.offset_left = 8
	_content.offset_right = -8
	_content.offset_bottom = -24
	_root.add_child(_content)

	# Close hint
	var hint := Label.new()
	hint.text = "[ESC] close   [←→] switch tab"
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -240
	hint.offset_right = 0
	hint.offset_top = -20
	hint.offset_bottom = 0
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	hint.add_theme_font_size_override("font_size", 11)
	_root.add_child(hint)


func _switch_tab(index: int) -> void:
	_active_tab = index
	for i in _tab_btns.size():
		_tab_btns[i].modulate = Color(1, 1, 1, 1.0) if i == index else Color(1, 1, 1, 0.55)

	for child in _content.get_children():
		child.queue_free()

	match index:
		0: _build_status_tab()
		1: _build_equip_tab()
		2: _build_jobs_tab()
		3: _build_skills_tab()


# ── STATUS tab ───────────────────────────────────────────────────────────────

func _build_status_tab() -> void:
	if _sheet == null:
		return
	var s := _sheet
	var w := _content.size.x
	var col_split := 220.0

	# Portrait box
	var portrait_bg := ColorRect.new()
	portrait_bg.color = Color(0.08, 0.07, 0.06, 0.6)
	portrait_bg.position = Vector2(8, 4)
	portrait_bg.size = Vector2(col_split - 16, 180)
	_content.add_child(portrait_bg)

	if s.portrait_path != "":
		var tex := load(s.portrait_path) as Texture2D
		if tex != null:
			var portrait := TextureRect.new()
			portrait.texture = tex
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.clip_contents = true
			portrait.position = portrait_bg.position
			portrait.size = portrait_bg.size
			portrait.custom_minimum_size = portrait_bg.size
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_content.add_child(portrait)

	# Gold border around portrait
	var frame := Panel.new()
	frame.position = portrait_bg.position - Vector2(2, 2)
	frame.size = portrait_bg.size + Vector2(4, 4)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0)
	frame_style.border_color = COLOR_GOLD
	frame_style.set_border_width_all(2)
	frame.add_theme_stylebox_override("panel", frame_style)
	_content.add_child(frame)

	# Name / job / level
	_ink_label(s.display_name, Vector2(col_split, 4), 18, true)
	_ink_label(s.job_title, Vector2(col_split, 26), 13)
	_ink_label("Lv. %d" % s.level, Vector2(col_split, 42), 12)

	# HP / MP / CT bars
	_stat_bar("HP", s.get_max_hp(), s.get_max_hp(), COLOR_HP, Vector2(col_split, 65))
	_stat_bar("MP", s.get_max_mp(), s.get_max_mp(), COLOR_MP, Vector2(col_split, 85))

	# Core stats grid
	var stats_x := col_split
	var stats_y := 115.0
	var col2 := stats_x + 180
	_stat_row("STR", s.get_core_stat("STR"), Vector2(stats_x, stats_y))
	_stat_row("SPD", s.get_core_stat("SPD"), Vector2(stats_x, stats_y + 18))
	_stat_row("INT", s.get_core_stat("INT"), Vector2(stats_x, stats_y + 36))
	_stat_row("FTH", s.get_core_stat("FTH"), Vector2(stats_x, stats_y + 54))
	_stat_row("CRT", s.get_core_stat("CRT"), Vector2(stats_x, stats_y + 72))
	_stat_row("PRS", s.get_core_stat("PRS"), Vector2(stats_x, stats_y + 90))

	_stat_row("ATK", s.get_power(),    Vector2(col2, stats_y))
	_stat_row("DEF", s.get_defense(),  Vector2(col2, stats_y + 18))
	_stat_row("MOV", s.get_movement(), Vector2(col2, stats_y + 36))
	_stat_row("JMP", s.get_jump(),     Vector2(col2, stats_y + 54))
	_stat_row("EVD", s.get_evasion_rate(), Vector2(col2, stats_y + 72))
	_stat_row("CRI", s.get_critical_rate(), Vector2(col2, stats_y + 90))

	# Divider
	_divider(Vector2(8, 215), w - 16)
	_ink_label("RESISTANCES", Vector2(8, 222), 11, true)

	# Resistances
	var resist_x := 8.0
	for res_name in STATUS_ICONS.keys():
		var icon_tex := STATUS_ICONS[res_name] as Texture2D
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.position = Vector2(resist_x, 240)
		icon.size = Vector2(20, 20)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_content.add_child(icon)
		_muted_label(res_name.left(4), Vector2(resist_x, 262), 9)
		_muted_label("0%%", Vector2(resist_x + 2, 274), 9)
		resist_x += 90


# ── EQUIP tab ────────────────────────────────────────────────────────────────

func _build_equip_tab() -> void:
	if _sheet == null:
		return
	var s := _sheet

	_ink_label("EQUIPMENT", Vector2(8, 4), 14, true)

	var slots := [
		["Weapon",    s.weapon],
		["Shield",    s.shield],
		["Head",      s.head],
		["Body",      s.body],
		["Feet",      s.feet],
		["Accessory", s.accessory],
	]

	var y := 32.0
	for slot_data in slots:
		var slot_name: String = slot_data[0]
		var item_name: String = slot_data[1]

		var row_bg := ColorRect.new()
		row_bg.color = Color(0.12, 0.10, 0.07, 0.45)
		row_bg.position = Vector2(8, y)
		row_bg.size = Vector2(_content.size.x - 16, 34)
		_content.add_child(row_bg)

		_muted_label(slot_name.to_upper(), Vector2(16, y + 4), 10)
		if item_name != "":
			_ink_label(item_name, Vector2(120, y + 8), 13)
		else:
			_muted_label("— empty —", Vector2(120, y + 10), 11)

		_divider(Vector2(8, y + 34), _content.size.x - 16)
		y += 38


# ── JOBS tab ─────────────────────────────────────────────────────────────────

func _build_jobs_tab() -> void:
	if _sheet == null:
		return

	var split := 200.0
	_ink_label("GUILDS", Vector2(8, 4), 14, true)
	_ink_label("SKILLS", Vector2(split + 8, 4), 14, true)

	# Job list (left column)
	var job_scroll := ScrollContainer.new()
	job_scroll.position = Vector2(8, 28)
	job_scroll.size = Vector2(split - 12, _content.size.y - 32)
	job_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(job_scroll)

	var job_vbox := VBoxContainer.new()
	job_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	job_scroll.add_child(job_vbox)

	for job_res in _sheet.job_sheets:
		if not job_res is JobSheet:
			continue
		var js := job_res as JobSheet

		var req_met := true
		if js.required_job_id != "":
			var req := _sheet.get_job_sheet(js.required_job_id)
			req_met = req != null and req.job_level >= 5

		var is_active := js.job_id == _sheet.active_job_id
		var tier_mark := " ✦" if js.tier == 2 else ""

		var btn := Button.new()
		btn.text = "%s%s" % [js.display_name, tier_mark]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.disabled = not req_met
		btn.add_theme_color_override("font_color", COLOR_GOLD if is_active else COLOR_INK)
		btn.pressed.connect(_on_job_selected.bind(js.job_id))
		job_vbox.add_child(btn)

		var jp_lbl := Label.new()
		jp_lbl.text = "  Lv.%d  %dJP available" % [js.job_level, js.get_jp_available()]
		jp_lbl.add_theme_color_override("font_color", COLOR_MUTED)
		jp_lbl.add_theme_font_size_override("font_size", 10)
		job_vbox.add_child(jp_lbl)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 4)
		job_vbox.add_child(spacer)

	# Skill list (right column, populated on job select)
	var skill_scroll := ScrollContainer.new()
	skill_scroll.name = "SkillScroll"
	skill_scroll.position = Vector2(split + 4, 28)
	skill_scroll.size = Vector2(_content.size.x - split - 8, _content.size.y - 32)
	skill_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(skill_scroll)

	_job_skill_list = VBoxContainer.new()
	_job_skill_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_scroll.add_child(_job_skill_list)

	# Auto-select active job
	if _selected_job_id == "" and _sheet.active_job_id != "":
		_selected_job_id = _sheet.active_job_id
	if _selected_job_id != "":
		_populate_job_skills(_selected_job_id)


func _on_job_selected(job_id: String) -> void:
	_selected_job_id = job_id
	_populate_job_skills(job_id)


func _populate_job_skills(job_id: String) -> void:
	if _job_skill_list == null:
		return
	for child in _job_skill_list.get_children():
		child.queue_free()

	var job_sheet := _sheet.get_job_sheet(job_id)
	if job_sheet == null:
		return

	var skills_dir := "res://data/jobs/marco/"
	var dir := DirAccess.open(skills_dir)
	if dir == null:
		return

	var skills: Array[JobSkill] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with(job_id + "_") and fname.ends_with(".tres"):
			var skill := load(skills_dir + fname) as JobSkill
			if skill != null:
				skills.append(skill)
		fname = dir.get_next()
	dir.list_dir_end()
	skills.sort_custom(func(a, b): return a.jp_cost < b.jp_cost)

	for skill in skills:
		var is_unlocked := job_sheet.unlocked_skills.has(skill.skill_id)
		var can_afford: bool = job_sheet.get_jp_available() >= skill.jp_cost

		var row := HBoxContainer.new()
		_job_skill_list.add_child(row)

		var btn := Button.new()
		btn.text = skill.display_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var col := COLOR_EQUIPPED if is_unlocked else (COLOR_INK if can_afford else COLOR_LOCKED)
		btn.add_theme_color_override("font_color", col)
		btn.pressed.connect(_on_skill_clicked.bind(skill, job_sheet))
		row.add_child(btn)

		var cost := Label.new()
		cost.text = "✓" if is_unlocked else ("%dJP" % skill.jp_cost)
		cost.add_theme_color_override("font_color", COLOR_EQUIPPED if is_unlocked else COLOR_MUTED)
		cost.add_theme_font_size_override("font_size", 11)
		cost.custom_minimum_size = Vector2(52, 0)
		row.add_child(cost)

		var desc := Label.new()
		desc.text = skill.description
		desc.add_theme_color_override("font_color", COLOR_MUTED)
		desc.add_theme_font_size_override("font_size", 10)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_job_skill_list.add_child(desc)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 6)
		_job_skill_list.add_child(spacer)


func _on_skill_clicked(skill: JobSkill, job_sheet: JobSheet) -> void:
	if job_sheet.unlocked_skills.has(skill.skill_id):
		return
	if job_sheet.unlock_skill(skill):
		_populate_job_skills(job_sheet.job_id)


# ── SKILLS tab ────────────────────────────────────────────────────────────────

func _build_skills_tab() -> void:
	if _sheet == null:
		return

	var split := _content.size.x * 0.55
	_ink_label("LEARNED SKILLS", Vector2(8, 4), 14, true)
	_ink_label("EQUIPPED", Vector2(split + 8, 4), 14, true)

	# All unlocked skills pool
	var pool_scroll := ScrollContainer.new()
	pool_scroll.position = Vector2(8, 28)
	pool_scroll.size = Vector2(split - 12, _content.size.y - 32)
	pool_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(pool_scroll)

	var pool_vbox := VBoxContainer.new()
	pool_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_scroll.add_child(pool_vbox)

	# Gather all unlocked skills across all jobs
	var all_unlocked: Array[JobSkill] = []
	for job_res in _sheet.job_sheets:
		if not job_res is JobSheet:
			continue
		var js := job_res as JobSheet
		var skills_dir := "res://data/jobs/marco/"
		var dir := DirAccess.open(skills_dir)
		if dir == null:
			continue
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.begins_with(js.job_id + "_") and fname.ends_with(".tres"):
				var skill := load(skills_dir + fname) as JobSkill
				if skill != null and js.unlocked_skills.has(skill.skill_id):
					all_unlocked.append(skill)
			fname = dir.get_next()
		dir.list_dir_end()

	if all_unlocked.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No skills unlocked yet.\nVisit the Jobs tab to spend JP."
		empty_lbl.add_theme_color_override("font_color", COLOR_MUTED)
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pool_vbox.add_child(empty_lbl)
	else:
		for skill in all_unlocked:
			var is_active := _sheet.equipped_skills.has(skill.skill_id)
			var is_trait := _sheet.equipped_traits.has(skill.skill_id)
			var is_equipped := is_active or is_trait

			var row := HBoxContainer.new()
			pool_vbox.add_child(row)

			var btn := Button.new()
			var cat_mark := "[P] " if skill.category == JobSkill.SkillCategory.PASSIVE else ""
			btn.text = cat_mark + skill.display_name
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_color_override("font_color", COLOR_EQUIPPED if is_equipped else COLOR_INK)
			btn.pressed.connect(_on_equip_skill.bind(skill))
			row.add_child(btn)

			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 3)
			pool_vbox.add_child(spacer)

	# Equipped slots (right side)
	var slots_x := split + 8
	var y := 28.0

	_muted_label("ACTIVE  (4 slots)", Vector2(slots_x, y), 11)
	y += 18
	for i in CharacterSheet.MAX_SKILL_SLOTS:
		_slot_row(i, false, slots_x, y)
		y += 34

	y += 12
	_muted_label("PASSIVE  (4 slots)", Vector2(slots_x, y), 11)
	y += 18
	for i in CharacterSheet.MAX_TRAIT_SLOTS:
		_slot_row(i, true, slots_x, y)
		y += 34


func _slot_row(index: int, is_trait: bool, x: float, y: float) -> void:
	var arr := _sheet.equipped_traits if is_trait else _sheet.equipped_skills
	var filled := index < arr.size()

	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.10, 0.07, 0.5) if filled else Color(0.08, 0.07, 0.05, 0.35)
	bg.position = Vector2(x, y)
	bg.size = Vector2(_content.size.x - x - 8, 28)
	_content.add_child(bg)

	var lbl := Label.new()
	lbl.text = arr[index] if filled else "— empty —"
	lbl.position = Vector2(x + 8, y + 6)
	lbl.add_theme_color_override("font_color", COLOR_EQUIPPED if filled else COLOR_LOCKED)
	lbl.add_theme_font_size_override("font_size", 12)
	_content.add_child(lbl)

	if filled:
		var remove_btn := Button.new()
		remove_btn.text = "✕"
		remove_btn.position = Vector2(_content.size.x - 32, y + 2)
		remove_btn.size = Vector2(24, 24)
		remove_btn.add_theme_color_override("font_color", COLOR_MUTED)
		remove_btn.pressed.connect(_on_unequip.bind(index, is_trait))
		_content.add_child(remove_btn)


func _on_equip_skill(skill: JobSkill) -> void:
	var is_passive := skill.category == JobSkill.SkillCategory.PASSIVE
	if is_passive:
		if _sheet.equipped_traits.has(skill.skill_id):
			_sheet.unequip_trait(skill.skill_id)
		else:
			_sheet.equip_trait(skill.skill_id)
	else:
		if _sheet.equipped_skills.has(skill.skill_id):
			_sheet.unequip_skill(skill.skill_id)
		else:
			_sheet.equip_skill(skill.skill_id)
	_build_skills_tab()


func _on_unequip(index: int, is_trait: bool) -> void:
	if is_trait:
		if index < _sheet.equipped_traits.size():
			_sheet.equipped_traits.remove_at(index)
	else:
		if index < _sheet.equipped_skills.size():
			_sheet.equipped_skills.remove_at(index)
	_build_skills_tab()


# ── Helpers ───────────────────────────────────────────────────────────────────

func _ink_label(text: String, pos: Vector2, size: int, bold: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_color_override("font_color", COLOR_INK)
	lbl.add_theme_font_size_override("font_size", size)
	_content.add_child(lbl)


func _muted_label(text: String, pos: Vector2, size: int) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_color_override("font_color", COLOR_MUTED)
	lbl.add_theme_font_size_override("font_size", size)
	_content.add_child(lbl)


func _stat_bar(label: String, current: int, maximum: int, color: Color, pos: Vector2) -> void:
	var bar_w := 200.0
	_muted_label(label, pos, 11)
	var bp := pos + Vector2(28, 2)
	var bg := ColorRect.new()
	bg.color = COLOR_BAR_BG
	bg.position = bp
	bg.size = Vector2(bar_w, 10)
	_content.add_child(bg)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = bp
	fill.size = Vector2(bar_w * clampf(float(current) / float(maxi(maximum, 1)), 0.0, 1.0), 10)
	_content.add_child(fill)
	_muted_label("%d/%d" % [current, maximum], bp + Vector2(bar_w + 4, -1), 11)


func _stat_row(label: String, value: int, pos: Vector2) -> void:
	_muted_label(label, pos, 11)
	_ink_label(str(value), pos + Vector2(36, 0), 12)


func _divider(pos: Vector2, width: float) -> void:
	var line := ColorRect.new()
	line.color = Color(0.35, 0.28, 0.18, 0.5)
	line.position = pos
	line.size = Vector2(width, 1)
	_content.add_child(line)
