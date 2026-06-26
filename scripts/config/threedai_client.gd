extends RefCounted
class_name ThreeDaiClient

const BASE_URL := "https://api.3daistudio.com"
const POLL_INTERVAL := 8.0

var _api_key: String = ""
var _scene_tree: SceneTree = null


func configure(api_key: String, scene_tree: SceneTree) -> void:
	_api_key = api_key
	_scene_tree = scene_tree


func is_configured() -> bool:
	return not _api_key.is_empty()


## Generate a 3D model from a text prompt using Tencent Hunyuan (fast).
## Calls back with local .glb path on success, "" on failure.
func generate_from_text(prompt: String, output_path: String, callback: Callable) -> void:
	var body := JSON.stringify({
		"prompt": prompt,
		"enable_pbr": true,
	})
	_post("/v1/3d-models/tencent/generate/rapid/", body, func(response: Dictionary):
		if not response.get("ok", false):
			push_warning("3DAI: generate_from_text failed: %s" % response.get("error", "unknown"))
			callback.call("")
			return
		var task_id: String = response.get("body", {}).get("task_id", "")
		if task_id == "":
			push_warning("3DAI: no task_id in response")
			callback.call("")
			return
		print("3DAI: task submitted — %s" % task_id)
		_poll_task(task_id, output_path, callback)
	)


## Poll task status until FINISHED or FAILED, then download the GLB.
func _poll_task(task_id: String, output_path: String, callback: Callable) -> void:
	_get("/v1/generation-request/%s/status/" % task_id, func(response: Dictionary):
		if not response.get("ok", false):
			push_warning("3DAI: poll failed: %s" % response.get("error", "unknown"))
			callback.call("")
			return
		var body: Dictionary = response.get("body", {})
		var status: String = body.get("status", "")
		print("3DAI: task %s — %s" % [task_id, status])
		match status:
			"FINISHED":
				var results: Array = body.get("results", [])
				var glb_url := ""
				for r in results:
					if r.get("asset_type", "") in ["glb", "model", "3d_model"]:
						glb_url = r.get("url", "")
						break
				if glb_url == "" and results.size() > 0:
					glb_url = results[0].get("url", "")
				if glb_url == "":
					push_warning("3DAI: no download URL in results")
					callback.call("")
					return
				_download_file(glb_url, output_path, callback)
			"FAILED":
				push_warning("3DAI: task %s failed" % task_id)
				callback.call("")
			_:
				if _scene_tree != null:
					await _scene_tree.create_timer(POLL_INTERVAL).timeout
				_poll_task(task_id, output_path, callback)
	)


func _download_file(url: String, output_path: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	_scene_tree.current_scene.add_child(http)
	http.request_completed.connect(func(result, code, _headers, body_bytes):
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			push_warning("3DAI: download failed (result=%d code=%d)" % [result, code])
			callback.call("")
			return
		var dir := output_path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_warning("3DAI: could not write to %s" % output_path)
			callback.call("")
			return
		file.store_buffer(body_bytes)
		file.close()
		print("3DAI: saved to %s" % output_path)
		callback.call(output_path)
	)
	http.request(url)


func _post(endpoint: String, body: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	_scene_tree.current_scene.add_child(http)
	var headers := [
		"Authorization: Bearer %s" % _api_key,
		"Content-Type: application/json",
	]
	http.request_completed.connect(func(result, code, _headers, body_bytes):
		http.queue_free()
		_handle_response(result, code, body_bytes, callback)
	)
	http.request(BASE_URL + endpoint, headers, HTTPClient.METHOD_POST, body)


func _get(endpoint: String, callback: Callable) -> void:
	var http := HTTPRequest.new()
	_scene_tree.current_scene.add_child(http)
	var headers := ["Authorization: Bearer %s" % _api_key]
	http.request_completed.connect(func(result, code, _headers, body_bytes):
		http.queue_free()
		_handle_response(result, code, body_bytes, callback)
	)
	http.request(BASE_URL + endpoint, headers, HTTPClient.METHOD_GET)


func _handle_response(result: int, code: int, body_bytes: PackedByteArray, callback: Callable) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		callback.call({"ok": false, "error": "HTTP request failed (result %d)" % result})
		return
	if code == 401:
		callback.call({"ok": false, "error": "Invalid 3DAI API key"})
		return
	if code == 429:
		callback.call({"ok": false, "error": "3DAI rate limit hit — max 3 req/min"})
		return
	if code >= 400:
		callback.call({"ok": false, "error": "HTTP %d: %s" % [code, body_bytes.get_string_from_utf8()]})
		return
	var json := JSON.new()
	if json.parse(body_bytes.get_string_from_utf8()) != OK:
		callback.call({"ok": false, "error": "JSON parse error"})
		return
	callback.call({"ok": true, "body": json.get_data()})
