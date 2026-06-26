extends Node

const ENV_FILE_NAME := ".env.local"

var tactical_ai_api_key: String = ""
var pixellab_api_key: String = ""
var threedai_api_key: String = ""


func _ready() -> void:
	tactical_ai_api_key = _load_key("TACTICAL_AI_API_KEY")
	pixellab_api_key = _load_key("PIXELLAB_API_KEY")
	threedai_api_key = _load_key("THREEDAI_API_KEY")


func has_tactical_ai_key() -> bool:
	return not tactical_ai_api_key.is_empty()


func get_tactical_ai_api_key() -> String:
	return tactical_ai_api_key


func has_pixellab_key() -> bool:
	return not pixellab_api_key.is_empty()


func get_pixellab_api_key() -> String:
	return pixellab_api_key


func has_threedai_key() -> bool:
	return not threedai_api_key.is_empty()


func get_threedai_api_key() -> String:
	return threedai_api_key


func _load_key(key: String) -> String:
	var from_os := OS.get_environment(key)
	if not from_os.is_empty():
		return from_os.strip_edges()

	var env_path := ProjectSettings.globalize_path("res://").path_join(ENV_FILE_NAME)
	if not FileAccess.file_exists(env_path):
		push_warning("EnvSecrets: missing %s — tactical AI API disabled." % env_path)
		return ""

	var file := FileAccess.open(env_path, FileAccess.READ)
	if file == null:
		push_warning("EnvSecrets: could not read %s" % env_path)
		return ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if not line.contains("="):
			continue
		var parts := line.split("=", true, 1)
		if parts[0].strip_edges() == key:
			return parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")

	return ""