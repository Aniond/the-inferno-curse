extends CanvasLayer
## PartySelectUI — horizontal scrollable strip of portrait cards along the bottom.
## Press C to open/close. Click a card to open that character's full sheet.

signal character_selected(sheet: CharacterSheet)

const COLOR_BG        := Color(0.05, 0.04, 0.03, 0.88)
const COLOR_CARD      := Color(0.12, 0.10, 0.07, 1.0)
const COLOR_CARD_HOV  := Color(0.22, 0.18, 0.12, 1.0)
const COLOR_SELECTED  := Color(0.72, 0.55, 0.25, 1.0)
const COLOR_NAME      := Color(0.80, 0.75, 0.65, 1.0)
const COLOR_JOB       := Color(0.55, 0.50, 0.40, 1.0)
const COLOR_HP        := Color(0.25, 0.55, 0.80, 1.0)
const COLOR_MP        := Color(0.75, 0.30, 0.30, 1.0)
const COLOR_BAR_BG    := Color(0.15, 0.13, 0.10, 1.0)

const STRIP_HEIGHT    := 130
const CARD_WIDTH      := 160
const CARD_PAD        := 8
const PORTRAIT_SIZE   := 60

var _is_open: bool = false
var _strip: Control
var _scroll: HScrollBar
var _cards: Array[Control] = []
var _scroll_offset: float = 0.0
var _selected_index: int = -1


func _ready() -> void:
	layer = 99
	visible = false
	_build_strip()
	PartyManager.party_changed.connect(_rebuild_cards)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_party"):
		if _is_open:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	_is_open = true
	visible = true
	_rebuild_cards()


func close() -> void:
	_is_open = false
	visible = false


# ----- Build -----

func _build_strip() -> void:
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_top = -STRIP_HEIGHT
	bg.offset_bottom = 0
	bg.offset_left = 0
	bg.offset_right = 0
	add_child(bg)

	_strip = Control.new()
	_strip.anchor_left = 0.0
	_strip.anchor_right = 1.0
	_strip.anchor_top = 1.0
	_strip.anchor_bottom = 1.0
	_strip.offset_top = -STRIP_HEIGHT + CARD_PAD
	_strip.offset_bottom = -CARD_PAD
	_strip.offset_left = CARD_PAD
	_strip.offset_right = -CARD_PAD
	_strip.clip_contents = true
	add_child(_strip)

	var hint := Label.new()
	hint.text = "[P] close   [←→] scroll"
	hint.add_theme_color_override("font_color", COLOR_JOB)
	hint.add_theme_font_size_override("font_size", 11)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -180
	hint.offset_right = 0
	hint.offset_top = -18
	hint.offset_bottom = 0
	add_child(hint)


func _rebuild_cards() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()

	var sheets := PartyManager.get_sheets()
	for i in sheets.size():
		var card := _make_card(sheets[i], i)
		_strip.add_child(card)
		_cards.append(card)

	_apply_scroll()


func _make_card(sheet: CharacterSheet, index: int) -> Control:
	var card := Control.new()
	card.size = Vector2(CARD_WIDTH, STRIP_HEIGHT - CARD_PAD * 2)
	card.position = Vector2(index * (CARD_WIDTH + CARD_PAD), 0)

	var bg := ColorRect.new()
	bg.color = COLOR_CARD
	bg.size = card.size
	card.add_child(bg)

	# Portrait box
	var portrait_bg := ColorRect.new()
	portrait_bg.color = Color(0.08, 0.07, 0.05, 1.0)
	portrait_bg.position = Vector2(6, 6)
	portrait_bg.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	card.add_child(portrait_bg)

	if sheet.portrait_path != "":
		var tex := load(sheet.portrait_path) as Texture2D
		if tex != null:
			var portrait := TextureRect.new()
			portrait.texture = tex
			portrait.position = portrait_bg.position
			portrait.size = portrait_bg.size
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			card.add_child(portrait)

	# Gold border around portrait
	var border := Panel.new()
	border.position = portrait_bg.position - Vector2(2, 2)
	border.size = portrait_bg.size + Vector2(4, 4)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = COLOR_SELECTED
	style.set_border_width_all(2)
	border.add_theme_stylebox_override("panel", style)
	card.add_child(border)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = sheet.display_name
	name_lbl.position = Vector2(PORTRAIT_SIZE + 10, 6)
	name_lbl.size = Vector2(CARD_WIDTH - PORTRAIT_SIZE - 14, 20)
	name_lbl.add_theme_color_override("font_color", COLOR_NAME)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.clip_text = true
	card.add_child(name_lbl)

	# Job title
	var job_lbl := Label.new()
	job_lbl.text = sheet.job_title
	job_lbl.position = Vector2(PORTRAIT_SIZE + 10, 22)
	job_lbl.size = Vector2(CARD_WIDTH - PORTRAIT_SIZE - 14, 16)
	job_lbl.add_theme_color_override("font_color", COLOR_JOB)
	job_lbl.add_theme_font_size_override("font_size", 10)
	card.add_child(job_lbl)

	# HP bar
	var hp_max := sheet.get_max_hp()
	_add_bar(card, "HP", hp_max, hp_max, COLOR_HP, Vector2(PORTRAIT_SIZE + 10, 42))

	# MP bar
	var mp_max := sheet.get_max_mp()
	_add_bar(card, "MP", mp_max, mp_max, COLOR_MP, Vector2(PORTRAIT_SIZE + 10, 58))

	# Level
	var lv_lbl := Label.new()
	lv_lbl.text = "Lv.%d" % sheet.level
	lv_lbl.position = Vector2(6, PORTRAIT_SIZE + 10)
	lv_lbl.add_theme_color_override("font_color", COLOR_JOB)
	lv_lbl.add_theme_font_size_override("font_size", 10)
	card.add_child(lv_lbl)

	# Selected highlight overlay
	if index == _selected_index:
		var highlight := ColorRect.new()
		highlight.color = Color(COLOR_SELECTED.r, COLOR_SELECTED.g, COLOR_SELECTED.b, 0.25)
		highlight.size = card.size
		card.add_child(highlight)

	# Click area
	var btn := Button.new()
	btn.flat = true
	btn.size = card.size
	btn.position = Vector2.ZERO
	btn.modulate = Color(1, 1, 1, 0)
	btn.pressed.connect(_on_card_pressed.bind(index))
	card.add_child(btn)

	return card


func _add_bar(parent: Control, label: String, current: int, maximum: int, color: Color, pos: Vector2) -> void:
	var bar_w := CARD_WIDTH - PORTRAIT_SIZE - 18
	var bar_h := 8

	var lbl := Label.new()
	lbl.text = label
	lbl.position = pos
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 9)
	parent.add_child(lbl)

	var bar_pos := pos + Vector2(18, 2)

	var bar_bg := ColorRect.new()
	bar_bg.color = COLOR_BAR_BG
	bar_bg.position = bar_pos
	bar_bg.size = Vector2(bar_w, bar_h)
	parent.add_child(bar_bg)

	var fill_w := bar_w * clampf(float(current) / float(maxi(maximum, 1)), 0.0, 1.0)
	var bar_fill := ColorRect.new()
	bar_fill.color = color
	bar_fill.position = bar_pos
	bar_fill.size = Vector2(fill_w, bar_h)
	parent.add_child(bar_fill)

	var val_lbl := Label.new()
	val_lbl.text = "%d/%d" % [current, maximum]
	val_lbl.position = bar_pos + Vector2(bar_w + 2, -1)
	val_lbl.add_theme_color_override("font_color", COLOR_JOB)
	val_lbl.add_theme_font_size_override("font_size", 9)
	parent.add_child(val_lbl)


# ----- Scrolling -----

func _apply_scroll() -> void:
	for i in _cards.size():
		_cards[i].position.x = i * (CARD_WIDTH + CARD_PAD) - _scroll_offset


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_right"):
		_scroll_offset = clampf(_scroll_offset + CARD_WIDTH + CARD_PAD, 0, _max_scroll())
		_apply_scroll()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_scroll_offset = clampf(_scroll_offset - CARD_WIDTH - CARD_PAD, 0, _max_scroll())
		_apply_scroll()
		get_viewport().set_input_as_handled()


func _max_scroll() -> float:
	var total := _cards.size() * (CARD_WIDTH + CARD_PAD)
	var visible_w := _strip.size.x
	return maxf(0.0, total - visible_w)


# ----- Callbacks -----

func _on_card_pressed(index: int) -> void:
	_selected_index = index
	_rebuild_cards()
	var sheets := PartyManager.get_sheets()
	if index < sheets.size():
		character_selected.emit(sheets[index])
