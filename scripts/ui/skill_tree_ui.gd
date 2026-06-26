extends Control
class_name SkillTreeUI

signal skill_unlocked(skill_id: String, tier: int)

const NODE_W := 160
const NODE_H := 80
const TIER_SPACING := 100
const FAMILY_SPACING := 220
const PADDING := Vector2(40, 60)

const COLOR_LOCKED := Color(0.2, 0.2, 0.25, 1.0)
const COLOR_AVAILABLE := Color(0.35, 0.28, 0.15, 1.0)
const COLOR_OWNED := Color(0.18, 0.38, 0.22, 1.0)
const COLOR_MAXED := Color(0.45, 0.22, 0.08, 1.0)
const COLOR_TEXT := Color(0.92, 0.88, 0.78, 1.0)
const COLOR_LINE_LOCKED := Color(0.3, 0.3, 0.35, 0.6)
const COLOR_LINE_OPEN := Color(0.65, 0.55, 0.25, 0.9)

var _sheet: CharacterSheet = null
var _nodes: Array[SkillTreeNode] = []
var _panels: Dictionary = {}   # "skill_id_tier" -> PanelContainer
var _canvas: Control = null


func setup(sheet: CharacterSheet) -> void:
	_sheet = sheet
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	_panels.clear()

	_canvas = Control.new()
	_canvas.name = "Canvas"
	add_child(_canvas)

	_nodes = SkillTreeResolver.get_all_visible_nodes(_sheet)
	_draw_connections()
	_draw_nodes()


func _draw_connections() -> void:
	for node in _nodes:
		# Draw tier chain line (tier N to tier N+1 of same skill)
		if node.tier < 3:
			var next := SkillTreeResolver.get_node_for_tier(node.skill_id, node.tier + 1)
			if next != null:
				_add_line(node.tree_position, next.tree_position, _line_color(node, next))

		# Draw cross-branch unlock lines
		for unlocked_id in node.unlocks:
			var target_node := SkillTreeResolver.get_node_for_tier(unlocked_id, 1)
			if target_node != null:
				_add_line(node.tree_position, target_node.tree_position, COLOR_LINE_OPEN)


func _draw_nodes() -> void:
	for tree_node in _nodes:
		var key := "%s_%d" % [tree_node.skill_id, tree_node.tier]
		var panel := _make_node_panel(tree_node)
		_canvas.add_child(panel)
		panel.position = tree_node.tree_position + PADDING
		_panels[key] = panel


func _make_node_panel(tree_node: SkillTreeNode) -> PanelContainer:
	var current_tier: int = _sheet.unlocked_nodes.get(tree_node.skill_id, 0)
	var unlock_result := SkillTreeResolver.can_unlock(tree_node, _sheet)
	var is_owned := current_tier >= tree_node.tier
	var is_available := unlock_result == SkillTreeResolver.UnlockResult.OK
	var is_maxed := current_tier >= 3 and tree_node.tier == 3

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(NODE_W, NODE_H)

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2

	if is_maxed:
		style.bg_color = COLOR_MAXED
		style.border_color = Color(0.9, 0.5, 0.1, 1.0)
	elif is_owned:
		style.bg_color = COLOR_OWNED
		style.border_color = Color(0.4, 0.8, 0.4, 1.0)
	elif is_available:
		style.bg_color = COLOR_AVAILABLE
		style.border_color = Color(0.85, 0.72, 0.3, 1.0)
	else:
		style.bg_color = COLOR_LOCKED
		style.border_color = Color(0.35, 0.35, 0.4, 1.0)

	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var name_label := Label.new()
	name_label.text = tree_node.display_name
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var gem_count := _count_gems(tree_node.skill_id)
	var cost_label := Label.new()
	if is_owned:
		cost_label.text = "✓ Unlocked"
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.95, 0.55, 1.0))
	else:
		cost_label.text = "%d gem%s" % [tree_node.gem_cost, "s" if tree_node.gem_cost != 1 else ""]
		var has_enough := gem_count >= tree_node.gem_cost
		cost_label.add_theme_color_override("font_color",
			Color(0.9, 0.8, 0.3, 1.0) if has_enough else Color(0.6, 0.4, 0.4, 1.0))
	cost_label.add_theme_font_size_override("font_size", 10)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(cost_label)

	if not is_owned and is_available:
		var btn := Button.new()
		btn.text = "Unlock"
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_on_unlock_pressed.bind(tree_node))
		vbox.add_child(btn)

	if tree_node.new_effect_description != "" and tree_node.tier == 3:
		var effect_label := Label.new()
		effect_label.text = "★ New effect"
		effect_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.3, 1.0))
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(effect_label)

	return panel


func _line_color(from_node: SkillTreeNode, to_node: SkillTreeNode) -> Color:
	var from_tier: int = _sheet.unlocked_nodes.get(from_node.skill_id, 0)
	var to_tier: int = _sheet.unlocked_nodes.get(to_node.skill_id, 0)
	if from_tier >= from_node.tier and to_tier >= to_node.tier:
		return COLOR_LINE_OPEN
	return COLOR_LINE_LOCKED


func _add_line(from: Vector2, to: Vector2, color: Color) -> void:
	var line := Line2D.new()
	line.add_point(from + PADDING + Vector2(NODE_W * 0.5, NODE_H))
	line.add_point(to + PADDING + Vector2(NODE_W * 0.5, 0))
	line.width = 2.0
	line.default_color = color
	_canvas.add_child(line)


func _on_unlock_pressed(tree_node: SkillTreeNode) -> void:
	var result := SkillTreeResolver.unlock(tree_node, _sheet)
	if result == SkillTreeResolver.UnlockResult.OK:
		emit_signal("skill_unlocked", tree_node.skill_id, tree_node.tier)
		_rebuild()


func _count_gems(skill_id: String) -> int:
	var count := 0
	for gem in _sheet.soul_gems:
		if gem is SoulGem and gem.skill_id == skill_id:
			count += 1
	return count
