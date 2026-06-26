extends CanvasLayer
## JobSkillUI — Displays Marco's job tree and lets the player equip skills/traits.
## Toggle with the "open_job_skills" action (J key).
## Only shows when a character with job_sheets is selected/active.

const COLOR_BG        := Color(0.05, 0.04, 0.03, 0.92)
const COLOR_PANEL     := Color(0.10, 0.08, 0.06, 1.0)
const COLOR_HEADER    := Color(0.72, 0.55, 0.25, 1.0)
const COLOR_BODY      := Color(0.80, 0.75, 0.65, 1.0)
const COLOR_MUTED     := Color(0.50, 0.46, 0.38, 1.0)
const COLOR_EQUIPPED  := Color(0.35, 0.65, 0.35, 1.0)
const COLOR_LOCKED    := Color(0.35, 0.30, 0.25, 1.0)
const COLOR_UNLOCKED  := Color(0.60, 0.55, 0.42, 1.0)
const COLOR_SELECTED  := Color(0.72, 0.55, 0.25, 0.3)
const COLOR_ACTIVE_JOB := Color(0.72, 0.55, 0.25, 1.0)
const COLOR_TIER2     := Color(0.65, 0.40, 0.60, 1.0)

var _is_open: bool = false
var _sheet: CharacterSheet = null

# Panels
var _overlay: ColorRect
var _root: Control
var _job_list: VBoxContainer
var _skill_panel: VBoxContainer
var _equip_panel: VBoxContainer

# State
var _selected_job_id: String = ""
var _all_skills: Array = []    # Array[JobSkill] for selected job
var _selected_skill: JobSkill = null

# Slot displays
var _skill_slots: Array[Button] = []
var _trait_slots: Array[Button] = []
var _skill_detail: Label
var _status_label: Label


func _ready() -> void:
	layer = 102
	visible = false
	_build_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_open:
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("open_job_skills"):
		if _is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open(sheet: CharacterSheet = null) -> void:
	if sheet != null:
		_sheet = sheet
	elif _sheet == null:
		_sheet = _find_player_sheet()
	if _sheet == null:
		return
	_is_open = true
	visible = true
	_refresh()


func close() -> void:
	_is_open = false
	visible = false


func _find_player_sheet() -> CharacterSheet:
	var marco = load("res://data/characters/marco_il_fornaio.tres")
	return marco as CharacterSheet


# ----- UI Construction -----

func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.color = COLOR_BG
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var vp := get_viewport().get_visible_rect().size if get_viewport() else Vector2(1280, 720)
	var margin := Vector2(60, 40)
	var panel_rect := Rect2(margin, vp - margin * 2)

	# Title
	var title := Label.new()
	title.text = "GUILDS & SKILLS"
	title.add_theme_color_override("font_color", COLOR_HEADER)
	title.add_theme_font_size_override("font_size", 20)
	title.position = Vector2(panel_rect.position.x, panel_rect.position.y)
	_root.add_child(title)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", COLOR_MUTED)
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.position = Vector2(panel_rect.position.x + 300, panel_rect.position.y + 4)
	_root.add_child(_status_label)

	# Three-column layout
	var col_y := panel_rect.position.y + 36
	var col_h := panel_rect.size.y - 50
	var col_x := [panel_rect.position.x, panel_rect.position.x + 220, panel_rect.position.x + 560]
	var col_w := [200.0, 320.0, 360.0]

	_build_job_column(Vector2(col_x[0], col_y), Vector2(col_w[0], col_h))
	_build_skill_column(Vector2(col_x[1], col_y), Vector2(col_w[1], col_h))
	_build_equip_column(Vector2(col_x[2], col_y), Vector2(col_w[2], col_h))

	# Close hint
	var hint := Label.new()
	hint.text = "[J / ESC] close"
	hint.add_theme_color_override("font_color", COLOR_MUTED)
	hint.add_theme_font_size_override("font_size", 11)
	hint.position = Vector2(panel_rect.position.x, panel_rect.position.y + col_h + 8)
	_root.add_child(hint)


func _build_job_column(pos: Vector2, size: Vector2) -> void:
	var header := _make_label("GUILD", pos, COLOR_HEADER, 13)
	_root.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.position = pos + Vector2(0, 20)
	scroll.size = size - Vector2(0, 20)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)

	_job_list = VBoxContainer.new()
	_job_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_job_list)


func _build_skill_column(pos: Vector2, size: Vector2) -> void:
	var header := _make_label("SKILLS", pos, COLOR_HEADER, 13)
	_root.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.position = pos + Vector2(0, 20)
	scroll.size = size - Vector2(0, 20)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root.add_child(scroll)

	_skill_panel = VBoxContainer.new()
	_skill_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_skill_panel)


func _build_equip_column(pos: Vector2, size: Vector2) -> void:
	var header := _make_label("EQUIPPED", pos, COLOR_HEADER, 13)
	_root.add_child(header)

	var panel_pos := pos + Vector2(0, 20)

	var slots_label := _make_label("Active Skills (4 slots)", panel_pos, COLOR_MUTED, 11)
	_root.add_child(slots_label)
	panel_pos.y += 18

	_skill_slots = []
	for i in 4:
		var btn := Button.new()
		btn.position = panel_pos
		btn.size = Vector2(size.x - 8, 28)
		btn.text = "— empty —"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color", COLOR_MUTED)
		btn.pressed.connect(_on_unequip_skill.bind(i, false))
		_root.add_child(btn)
		_skill_slots.append(btn)
		panel_pos.y += 32

	panel_pos.y += 12
	var traits_label := _make_label("Passive Traits (4 slots)", panel_pos, COLOR_MUTED, 11)
	_root.add_child(traits_label)
	panel_pos.y += 18

	_trait_slots = []
	for i in 4:
		var btn := Button.new()
		btn.position = panel_pos
		btn.size = Vector2(size.x - 8, 28)
		btn.text = "— empty —"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color", COLOR_MUTED)
		btn.pressed.connect(_on_unequip_skill.bind(i, true))
		_root.add_child(btn)
		_trait_slots.append(btn)
		panel_pos.y += 32

	panel_pos.y += 20
	_skill_detail = Label.new()
	_skill_detail.position = panel_pos
	_skill_detail.size = Vector2(size.x - 8, 160)
	_skill_detail.add_theme_color_override("font_color", COLOR_BODY)
	_skill_detail.add_theme_font_size_override("font_size", 11)
	_skill_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_skill_detail)


# ----- Refresh -----

func _refresh() -> void:
	if _sheet == null:
		return

	_status_label.text = "%s   Active Job: %s" % [
		_sheet.display_name,
		_sheet.active_job_id if _sheet.active_job_id != "" else "none"
	]

	_refresh_job_list()
	_refresh_skill_panel()
	_refresh_equip_slots()


func _refresh_job_list() -> void:
	for child in _job_list.get_children():
		child.queue_free()

	if _sheet == null:
		return

	for sheet in _sheet.job_sheets:
		if not sheet is JobSheet:
			continue
		var js := sheet as JobSheet

		# Tier II — check requirement
		var req_met := true
		if js.required_job_id != "":
			var req := _sheet.get_job_sheet(js.required_job_id)
			req_met = req != null and req.job_level >= 5

		var btn := Button.new()
		var tier_mark := " ✦" if js.tier == 2 else ""
		btn.text = "%s%s  Lv.%d  (%dJP)" % [js.display_name, tier_mark, js.job_level, js.get_jp_available()]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.disabled = not req_met
		var col := COLOR_ACTIVE_JOB if js.job_id == _sheet.active_job_id else (COLOR_TIER2 if js.tier == 2 else COLOR_BODY)
		btn.add_theme_color_override("font_color", col)
		btn.pressed.connect(_on_select_job.bind(js.job_id))
		_job_list.add_child(btn)

		var jp_bar := ColorRect.new()
		jp_bar.size = Vector2(clampf(float(js.jp_earned) / 500.0, 0.0, 1.0) * 180, 3)
		jp_bar.color = col
		_job_list.add_child(jp_bar)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 4)
		_job_list.add_child(spacer)


func _refresh_skill_panel() -> void:
	for child in _skill_panel.get_children():
		child.queue_free()
	_all_skills = []

	if _sheet == null or _selected_job_id == "":
		return

	var job_sheet := _sheet.get_job_sheet(_selected_job_id)
	if job_sheet == null:
		return

	# Load all skill .tres files for this job
	var skills_dir := "res://data/jobs/marco/"
	var dir := DirAccess.open(skills_dir)
	if dir == null:
		return

	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with(_selected_job_id + "_") and fname.ends_with(".tres"):
			var skill = load(skills_dir + fname)
			if skill is JobSkill:
				_all_skills.append(skill)
		fname = dir.get_next()
	dir.list_dir_end()

	# Sort by JP cost
	_all_skills.sort_custom(func(a, b): return a.jp_cost < b.jp_cost)

	var header_active := _make_label("Active Skills", Vector2.ZERO, COLOR_HEADER, 12)
	_skill_panel.add_child(header_active)

	var header_passive: Label = null
	var passive_added := false

	for skill in _all_skills:
		if skill.category == JobSkill.SkillCategory.PASSIVE and not passive_added:
			passive_added = true
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 8)
			_skill_panel.add_child(spacer)
			header_passive = _make_label("Passive Traits", Vector2.ZERO, COLOR_HEADER, 12)
			_skill_panel.add_child(header_passive)

		var is_unlocked := job_sheet.unlocked_skills.has(skill.skill_id)
		var is_equipped := _sheet.equipped_skills.has(skill.skill_id) or _sheet.equipped_traits.has(skill.skill_id)
		var can_afford: bool = job_sheet.get_jp_available() >= skill.jp_cost

		var row := HBoxContainer.new()
		_skill_panel.add_child(row)

		var btn := Button.new()
		btn.text = skill.display_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		if is_equipped:
			btn.add_theme_color_override("font_color", COLOR_EQUIPPED)
		elif is_unlocked:
			btn.add_theme_color_override("font_color", COLOR_UNLOCKED)
		else:
			btn.add_theme_color_override("font_color", COLOR_LOCKED if not can_afford else COLOR_BODY)

		btn.pressed.connect(_on_select_skill.bind(skill))
		row.add_child(btn)

		var cost_label := Label.new()
		cost_label.text = "%dJP" % skill.jp_cost if not is_unlocked else "✓"
		cost_label.add_theme_color_override("font_color", COLOR_EQUIPPED if is_unlocked else (COLOR_MUTED if not can_afford else COLOR_BODY))
		cost_label.add_theme_font_size_override("font_size", 11)
		cost_label.custom_minimum_size = Vector2(50, 0)
		row.add_child(cost_label)


func _refresh_equip_slots() -> void:
	if _sheet == null:
		return

	for i in 4:
		var slot := _skill_slots[i]
		if i < _sheet.equipped_skills.size():
			slot.text = _sheet.equipped_skills[i]
			slot.add_theme_color_override("font_color", COLOR_EQUIPPED)
		else:
			slot.text = "— empty —"
			slot.add_theme_color_override("font_color", COLOR_MUTED)

	for i in 4:
		var slot := _trait_slots[i]
		if i < _sheet.equipped_traits.size():
			slot.text = _sheet.equipped_traits[i]
			slot.add_theme_color_override("font_color", COLOR_EQUIPPED)
		else:
			slot.text = "— empty —"
			slot.add_theme_color_override("font_color", COLOR_MUTED)


# ----- Callbacks -----

func _on_select_job(job_id: String) -> void:
	_selected_job_id = job_id
	_selected_skill = null
	_skill_detail.text = ""
	_refresh_skill_panel()


func _on_select_skill(skill: JobSkill) -> void:
	_selected_skill = skill
	_show_skill_detail(skill)

	if _sheet == null or _selected_job_id == "":
		return
	var job_sheet := _sheet.get_job_sheet(_selected_job_id)
	if job_sheet == null:
		return

	var is_unlocked := job_sheet.unlocked_skills.has(skill.skill_id)

	if is_unlocked:
		# Toggle equip/unequip
		var is_passive := skill.category == JobSkill.SkillCategory.PASSIVE
		if is_passive:
			if _sheet.equipped_traits.has(skill.skill_id):
				_sheet.unequip_trait(skill.skill_id)
			else:
				if not _sheet.equip_trait(skill.skill_id):
					_status_label.text = "Trait slots full (max 4)"
		else:
			if _sheet.equipped_skills.has(skill.skill_id):
				_sheet.unequip_skill(skill.skill_id)
			else:
				if not _sheet.equip_skill(skill.skill_id):
					_status_label.text = "Skill slots full (max 4)"
	else:
		# Attempt to unlock
		if job_sheet.unlock_skill(skill):
			_status_label.text = "Unlocked: %s" % skill.display_name
		else:
			_status_label.text = "Need %dJP (have %d)" % [skill.jp_cost, job_sheet.get_jp_available()]

	_refresh()


func _on_unequip_skill(slot_index: int, is_trait: bool) -> void:
	if _sheet == null:
		return
	if is_trait:
		if slot_index < _sheet.equipped_traits.size():
			_sheet.equipped_traits.remove_at(slot_index)
	else:
		if slot_index < _sheet.equipped_skills.size():
			_sheet.equipped_skills.remove_at(slot_index)
	_refresh_equip_slots()


func _show_skill_detail(skill: JobSkill) -> void:
	var lines := []
	lines.append(skill.display_name.to_upper())
	lines.append("")
	lines.append(skill.description)
	if skill.flavor_text != "":
		lines.append("")
		lines.append('"%s"' % skill.flavor_text)
	lines.append("")
	if skill.mp_cost > 0:
		lines.append("MP Cost: %d" % skill.mp_cost)
	if skill.jp_cost > 0:
		lines.append("JP Cost to Unlock: %d" % skill.jp_cost)
	if skill.duration_turns > 0 and skill.duration_turns < 99:
		lines.append("Duration: %d turns" % skill.duration_turns)
	if skill.range_cells > 0:
		lines.append("Range: %d cells" % skill.range_cells)
	if skill.aoe_radius > 0:
		lines.append("AOE Radius: %d" % skill.aoe_radius)
	if skill.status_applied != "":
		lines.append("Applies: %s" % skill.status_applied)
	if skill.requires_church_visit:
		lines.append("[Requires recent Church visit]")
	_skill_detail.text = "\n".join(lines)


# ----- Helpers -----

func _make_label(text: String, pos: Vector2, color: Color, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	return lbl
