extends CanvasLayer
class_name CityMapScreen

signal node_travel_requested(node_data: CityNodeData)

const NODE_COLOR := Color(0.85, 0.65, 0.15, 1.0)
const NODE_HOVER_COLOR := Color(1.0, 0.88, 0.4, 1.0)
const NODE_SECRET_COLOR := Color(0.55, 0.2, 0.75, 1.0)
const PANEL_BG := Color(0.06, 0.05, 0.04, 0.94)
const PANEL_BORDER := Color(0.55, 0.42, 0.22, 1.0)
const TEXT_MAIN := Color(0.93, 0.88, 0.78, 1.0)
const TEXT_MUTED := Color(0.65, 0.58, 0.48, 1.0)

# Set this to the imported map image path
const MAP_IMAGE_PATH := "res://assets/summer/b6af84dd-0aac-4492-b1c4-4edf80a6221a/2026-06-24/HYk6L7nUdhjbMX7f12qS4_pvawYw6I.png"

const NODE_RADIUS := 14.0
const NODE_PULSE_SPEED := 2.0

var _nodes: Array[CityNodeData] = []
var _root: Control
var _map_texture: TextureRect
var _node_layer: Control
var _detail_panel: PanelContainer
var _detail_name: Label
var _detail_district: Label
var _detail_desc: RichTextLabel
var _detail_preview: TextureRect
var _travel_btn: Button
var _close_btn: Button
var _selected_node: CityNodeData = null
var _node_buttons: Dictionary = {}  # CityNodeData -> Button
var _pulse_time: float = 0.0


func _ready() -> void:
	layer = 95  # above BattleOverlay (90) and all other HUD layers
	_build_ui()
	hide()


func _process(delta: float) -> void:
	_pulse_time += delta * NODE_PULSE_SPEED
	_update_node_pulse()


func open(nodes: Array[CityNodeData]) -> void:
	_nodes = nodes
	_populate_nodes()
	_clear_detail()
	show()


func close() -> void:
	hide()
	_selected_node = null


func unlock_node(node_id: String) -> void:
	for node in _nodes:
		if node.id == node_id:
			node.unlocked = true
			_refresh_node_button(node)
			return


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	# Dark overlay behind everything
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	# Map image — fills most of the screen, centered
	_map_texture = TextureRect.new()
	_map_texture.name = "MapTexture"
	_map_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_map_texture.offset_right = -320  # leave room for detail panel on right
	_map_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_map_texture)

	var tex := load(MAP_IMAGE_PATH) if ResourceLoader.exists(MAP_IMAGE_PATH) else null
	if tex != null:
		_map_texture.texture = tex

	# Node dot layer — sits on top of the map at the same rect
	_node_layer = Control.new()
	_node_layer.name = "NodeLayer"
	_node_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_node_layer.offset_right = -320
	_node_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_node_layer)

	# Detail panel on the right — wraps its content, anchored top-right
	_detail_panel = _make_panel()
	_detail_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_detail_panel.offset_left = -310
	_detail_panel.offset_top = 60
	_detail_panel.offset_right = -16
	_detail_panel.offset_bottom = 60  # grows downward with content via size_flags
	_detail_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_root.add_child(_detail_panel)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 10)
	detail_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.add_child(detail_vbox)

	var city_title := Label.new()
	city_title.text = "FIRENZE"
	city_title.add_theme_font_size_override("font_size", 22)
	city_title.add_theme_color_override("font_color", Color(0.85, 0.65, 0.15, 1.0))
	city_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_vbox.add_child(city_title)

	var divider := HSeparator.new()
	detail_vbox.add_child(divider)

	_detail_preview = TextureRect.new()
	_detail_preview.custom_minimum_size = Vector2(0, 160)
	_detail_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_detail_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_preview.visible = false
	detail_vbox.add_child(_detail_preview)

	_detail_name = Label.new()
	_detail_name.text = "Select a location"
	_detail_name.add_theme_font_size_override("font_size", 16)
	_detail_name.add_theme_color_override("font_color", TEXT_MAIN)
	_detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_vbox.add_child(_detail_name)

	_detail_district = Label.new()
	_detail_district.text = ""
	_detail_district.add_theme_font_size_override("font_size", 13)
	_detail_district.add_theme_color_override("font_color", TEXT_MUTED)
	detail_vbox.add_child(_detail_district)

	_detail_desc = RichTextLabel.new()
	_detail_desc.bbcode_enabled = true
	_detail_desc.fit_content = true
	_detail_desc.scroll_active = false
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.add_theme_color_override("default_color", TEXT_MAIN)
	_detail_desc.add_theme_font_size_override("normal_font_size", 14)
	_detail_desc.text = "[color=#a09080]Choose a location on the map to read its description.[/color]"
	detail_vbox.add_child(_detail_desc)

	_travel_btn = _make_button("Travel Here", Color(0.65, 0.35, 0.12, 1.0))
	_travel_btn.visible = false
	_travel_btn.pressed.connect(_on_travel_pressed)
	detail_vbox.add_child(_travel_btn)

	# Close button top-right
	_close_btn = _make_button("Close Map  [M]", Color(0.3, 0.3, 0.3, 1.0))
	_close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_close_btn.offset_left = -140
	_close_btn.offset_top = 16
	_close_btn.offset_right = -16
	_close_btn.offset_bottom = 52
	_close_btn.pressed.connect(close)
	_root.add_child(_close_btn)


func _populate_nodes() -> void:
	for child in _node_layer.get_children():
		child.queue_free()
	_node_buttons.clear()

	for node in _nodes:
		if not node.unlocked and not node.is_secret:
			continue
		if not node.unlocked and node.is_secret:
			continue  # secret + locked = invisible
		_create_node_dot(node)


func _create_node_dot(node: CityNodeData) -> void:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(NODE_RADIUS * 2, NODE_RADIUS * 2)
	btn.position = node.map_position - Vector2(NODE_RADIUS, NODE_RADIUS)

	var normal := StyleBoxFlat.new()
	normal.bg_color = NODE_SECRET_COLOR if node.is_secret else NODE_COLOR
	normal.set_corner_radius_all(int(NODE_RADIUS))
	normal.set_border_width_all(2)
	normal.border_color = Color(1, 1, 1, 0.5)

	var hover := StyleBoxFlat.new()
	hover.bg_color = NODE_HOVER_COLOR
	hover.set_corner_radius_all(int(NODE_RADIUS))
	hover.set_border_width_all(3)
	hover.border_color = Color(1, 1, 1, 0.9)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.text = ""
	btn.tooltip_text = node.display_name
	btn.pressed.connect(_on_node_pressed.bind(node))
	_node_layer.add_child(btn)
	_node_buttons[node] = btn


func _refresh_node_button(node: CityNodeData) -> void:
	if _node_buttons.has(node):
		return
	if node.unlocked:
		_create_node_dot(node)


func _on_node_pressed(node: CityNodeData) -> void:
	_selected_node = node
	_detail_name.text = node.display_name
	_detail_district.text = node.district.capitalize() if node.district != "" else ""
	_detail_desc.text = node.description

	if node.preview_image_path != "":
		var tex := load(node.preview_image_path) if ResourceLoader.exists(node.preview_image_path) else null
		if tex != null:
			_detail_preview.texture = tex
			_detail_preview.visible = true
		else:
			_detail_preview.visible = false
	else:
		_detail_preview.visible = false

	_travel_btn.visible = node.scene_path != ""


func _clear_detail() -> void:
	_selected_node = null
	_detail_name.text = "Select a location"
	_detail_district.text = ""
	_detail_desc.text = "[color=#a09080]Choose a location on the map to read its description.[/color]"
	_detail_preview.visible = false
	_travel_btn.visible = false


func _on_travel_pressed() -> void:
	if _selected_node == null or _selected_node.scene_path == "":
		return
	node_travel_requested.emit(_selected_node)
	close()


func _update_node_pulse() -> void:
	var pulse := 0.5 + 0.5 * sin(_pulse_time)
	for node in _node_buttons.keys():
		var btn := _node_buttons[node] as Button
		if btn == null:
			continue
		var base := NODE_SECRET_COLOR if node.is_secret else NODE_COLOR
		var style := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if style != null:
			style.border_color = Color(1, 1, 1, 0.25 + pulse * 0.5)


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_button(label: String, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_size_override("font_size", 15)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(accent.r * 0.3, accent.g * 0.3, accent.b * 0.3, 0.95)
	normal.border_color = accent
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(accent.r * 0.55, accent.g * 0.55, accent.b * 0.55, 1.0)
	hover.border_color = accent
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(5)
	hover.content_margin_left = 10
	hover.content_margin_right = 10
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", TEXT_MAIN)
	return btn
