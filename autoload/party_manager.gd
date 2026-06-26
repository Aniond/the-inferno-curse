extends Node
## PartyManager — source of truth for who is in the active party.
## Add/remove characters by their CharacterSheet .tres path.

signal party_changed

const DEFAULT_PARTY := [
	"res://data/characters/guglielmo_da_siena.tres",
	"res://data/characters/marco_il_fornaio.tres",
]

var _members: Array[String] = []


func _ready() -> void:
	for path in DEFAULT_PARTY:
		_members.append(path)


func get_members() -> Array[String]:
	return _members.duplicate()


func get_sheets() -> Array[CharacterSheet]:
	var sheets: Array[CharacterSheet] = []
	for path in _members:
		var sheet := load(path) as CharacterSheet
		if sheet != null:
			sheets.append(sheet)
	return sheets


func add_member(sheet_path: String) -> void:
	if not _members.has(sheet_path):
		_members.append(sheet_path)
		party_changed.emit()


func remove_member(sheet_path: String) -> void:
	_members.erase(sheet_path)
	party_changed.emit()


func get_member_count() -> int:
	return _members.size()
