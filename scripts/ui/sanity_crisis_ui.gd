extends CanvasLayer
## SanityCrisisUI — shown when sanity hits Band 1 (Breaking).
## Player chooses: Seek Asylum (sanity restored, sanity_max reduced permanently)
## or Press On (no change, manifestations continue).

signal crisis_resolved

const ASYLUM_RESTORE := 50
const ASYLUM_MAX_PENALTY := 20

@onready var _asylum_btn: Button = $Panel/VBox/Buttons/AsylumButton
@onready var _press_on_btn: Button = $Panel/VBox/Buttons/PressOnButton

var _shown := false


func _ready() -> void:
	hide()
	SanityEventBus.band_changed.connect(_on_band_changed)
	_asylum_btn.pressed.connect(_on_asylum)
	_press_on_btn.pressed.connect(_on_press_on)


func _on_band_changed(new_band: int) -> void:
	if new_band == 1 and not _shown:
		_show_crisis()
	elif new_band > 1 and _shown:
		_hide_crisis()


func _show_crisis() -> void:
	_shown = true
	show()
	get_tree().paused = true


func _hide_crisis() -> void:
	_shown = false
	hide()
	get_tree().paused = false


func _on_asylum() -> void:
	var sheet := _get_sanity_sheet()
	if sheet != null:
		sheet.sanity_max = max(20, sheet.sanity_max - ASYLUM_MAX_PENALTY)
		sheet.apply_delta(ASYLUM_RESTORE)
		SanityEventBus.sanity_changed.emit(sheet.sanity_current, ASYLUM_RESTORE)
		var new_band := sheet.get_band()
		SanityEventBus.band_changed.emit(new_band)
	_hide_crisis()
	crisis_resolved.emit()


func _on_press_on() -> void:
	_hide_crisis()
	crisis_resolved.emit()


func _get_sanity_sheet() -> SanitySheet:
	var cs = PlayerData.character_sheet
	if cs == null:
		return null
	var s = cs.get("sanity")
	if s is SanitySheet:
		return s
	return null
