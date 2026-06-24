extends RefCounted
class_name TacticalAiClient

const DEFAULT_MODEL := "grok-2-latest"
const CHAT_COMPLETIONS_URL := "https://api.x.ai/v1/chat/completions"

var _api_key: String = ""


func configure(api_key: String) -> void:
	_api_key = api_key.strip_edges()


func is_configured() -> bool:
	return not _api_key.is_empty()


func request_tactical_advice(prompt: String, callback: Callable) -> void:
	if not is_configured():
		callback.call_deferred({"ok": false, "error": "Tactical AI API key not configured."})
		return

	var body := {
		"model": DEFAULT_MODEL,
		"messages": [
			{
				"role": "system",
				"content": "You are a tactical combat advisor for a grid-based RPG. Reply with concise JSON only.",
			},
			{
				"role": "user",
				"content": prompt,
			},
		],
		"temperature": 0.2,
	}

	var http := HTTPRequest.new()
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		callback.call_deferred({"ok": false, "error": "No scene tree available for HTTPRequest."})
		return

	tree.root.add_child(http)
	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, response_body: PackedByteArray) -> void:
		var payload := {
			"ok": result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300,
			"status": response_code,
			"body": response_body.get_string_from_utf8(),
		}
		http.queue_free()
		callback.call(payload)
	)

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % _api_key,
	])
	var json_body := JSON.stringify(body)
	var error := http.request(CHAT_COMPLETIONS_URL, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		http.queue_free()
		callback.call_deferred({"ok": false, "error": "HTTP request failed to start: %s" % error})
