extends Node
## SanityEventBus — single source of truth for all sanity roll logic.
## Scenes call trigger(event_id) or recover(source). Everything else is internal.

signal sanity_changed(new_value: int, delta: int)
signal band_changed(new_band: int)
signal natural_twenty  # brief positive flash signal for ShaderController

# Recovery amounts
const INN_RESTORE := 5
const CLERGY_RESTORE_SUCCESS := 8
const CLERGY_RESTORE_FAIL := 3
const CLERGY_DC := 8
const GUILD_RESTORE := 10

var _last_band: int = 4


func _ready() -> void:
	# Cache starting band once PlayerData is ready
	await get_tree().process_frame
	_last_band = _get_sanity_sheet().get_band() if _get_sanity_sheet() else 4


## Fire a sanity event by ID. Looks up the event, rolls Perception, applies result.
func trigger(event_id: String) -> void:
	var event: SanityEvent = SanityEventLibrary.get_event(event_id)
	if event == null:
		push_warning("SanityEventBus: unknown event_id '%s'" % event_id)
		return

	var sheet := _get_sanity_sheet()
	if sheet == null:
		return

	var perception := _get_perception()
	var modifier := int((perception - 10) / 2.0)
	var repeat_penalty := -2 if sheet.has_witnessed(event_id) else 0

	var raw_roll := randi_range(1, 20)
	var result := raw_roll + modifier + repeat_penalty

	sheet.log_event(event_id)

	if raw_roll == 20:
		natural_twenty.emit()
		return

	if raw_roll == 1 or result < event.roll_difficulty:
		var cost := event.sanity_cost * 2 if raw_roll == 1 else event.sanity_cost
		_apply_sanity_delta(-cost, sheet)
	# else: resisted — no delta, event already logged


## Restore sanity from a recovery source.
## source: "inn" | "clergy" | "guild"
func recover(source: String) -> void:
	var sheet := _get_sanity_sheet()
	if sheet == null:
		return

	match source:
		"inn":
			_apply_sanity_delta(INN_RESTORE, sheet)
		"clergy":
			var perception := _get_perception()
			var clergy_modifier := int((perception - 10) / 2.0)
			var roll := randi_range(1, 20) + clergy_modifier
			var amount := CLERGY_RESTORE_SUCCESS if roll >= CLERGY_DC else CLERGY_RESTORE_FAIL
			_apply_sanity_delta(amount, sheet)
		"guild":
			_apply_sanity_delta(GUILD_RESTORE, sheet)
		_:
			push_warning("SanityEventBus: unknown recovery source '%s'" % source)


func get_current_sanity() -> int:
	var sheet := _get_sanity_sheet()
	return sheet.sanity_current if sheet else 100


func get_current_band() -> int:
	var sheet := _get_sanity_sheet()
	return sheet.get_band() if sheet else 4


# ── Internals ────────────────────────────────────────────────────────────────

func _apply_sanity_delta(delta: int, sheet: SanitySheet) -> void:
	var prev_band := sheet.get_band()
	var new_value := sheet.apply_delta(delta)
	sanity_changed.emit(new_value, delta)
	var new_band := sheet.get_band()
	if new_band != prev_band:
		_last_band = new_band
		band_changed.emit(new_band)


func _get_sanity_sheet() -> SanitySheet:
	var cs = PlayerData.character_sheet
	if cs == null:
		return null
	var s = cs.get("sanity")
	if s is SanitySheet:
		return s
	return null


func _get_perception() -> int:
	# Perception maps to Presence (PRS) — the stat that reads people and situations
	return PlayerData.PRS
