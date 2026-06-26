extends Node
## SanityEventLibrary — loads all SanityEvent .tres files at startup.
## Query with get_event(event_id) — returns null if not found.

const SANITY_DATA_PATH := "res://data/sanity/"

var _events: Dictionary = {}


func _ready() -> void:
	_load_recursive(SANITY_DATA_PATH)


func get_event(event_id: String) -> SanityEvent:
	return _events.get(event_id, null)


func get_all_ids() -> Array:
	return _events.keys()


func _load_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("SanityEventLibrary: cannot open path %s" % path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			_load_recursive(path + entry + "/")
		elif entry.ends_with(".tres"):
			var full_path := path + entry
			var res := load(full_path)
			if res is SanityEvent:
				_events[res.event_id] = res
		entry = dir.get_next()
	dir.list_dir_end()
