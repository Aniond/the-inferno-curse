extends RefCounted
class_name PixelLabClient

const BASE_URL := "https://api.pixellab.ai/v2"
const POLL_INTERVAL := 5.0

var _api_key: String = ""
var _http: HTTPRequest = null
var _scene_tree: SceneTree = null


func configure(api_key: String, scene_tree: SceneTree) -> void:
	_api_key = api_key
	_scene_tree = scene_tree


func is_configured() -> bool:
	return not _api_key.is_empty()


## Generate 8 direction stills from a text description.
## Returns a Dictionary: { "south": Texture2D, "east": ..., ... } or {} on failure.
func create_character_8_directions(description: String, image_size: int, callback: Callable) -> void:
	var body := JSON.stringify({
		"description": description,
		"image_size": {"width": image_size, "height": image_size},
		"view": "side",
		"mode": "standard",
	})
	_post("/create-character-with-8-directions", body, func(response: Dictionary):
		if not response.get("ok", false):
			push_warning("PixelLab: create_character_8_directions failed: %s" % response.get("error", "unknown"))
			callback.call({})
			return
		var images: Dictionary = response.get("body", {}).get("images", {})
		var textures: Dictionary = {}
		for dir in images:
			var b64: String = images[dir].get("base64", "")
			if b64 == "":
				continue
			# Strip data URI prefix if present
			var comma := b64.find(",")
			if comma != -1:
				b64 = b64.substr(comma + 1)
			var bytes := Marshalls.base64_to_raw(b64)
			var img := Image.new()
			if img.load_png_from_buffer(bytes) == OK:
				textures[dir] = ImageTexture.create_from_image(img)
		callback.call(textures)
	)


## Request an animation for an existing character (by reference image).
## Returns list of background_job_ids via callback.
func create_animation(reference_image_base64: String, action: String, frame_count: int, directions: Array, callback: Callable) -> void:
	var body := JSON.stringify({
		"reference_image": {"type": "base64", "base64": reference_image_base64},
		"action_description": action,
		"frame_count": frame_count,
		"directions": directions,
		"mode": "v3",
	})
	_post("/characters/animations", body, func(response: Dictionary):
		if not response.get("ok", false):
			push_warning("PixelLab: create_animation failed: %s" % response.get("error", "unknown"))
			callback.call([])
			return
		var job_ids: Array = response.get("body", {}).get("background_job_ids", [])
		callback.call(job_ids)
	)


## Poll a background job until completed or failed. Returns frames via callback.
func poll_job(job_id: String, callback: Callable) -> void:
	_poll_loop(job_id, callback)


func _poll_loop(job_id: String, callback: Callable) -> void:
	_get("/background-jobs/%s" % job_id, func(response: Dictionary):
		if not response.get("ok", false):
			push_warning("PixelLab: poll_job failed: %s" % response.get("error", "unknown"))
			callback.call(null)
			return
		var body: Dictionary = response.get("body", {})
		var status: String = body.get("status", "")
		match status:
			"completed":
				callback.call(body.get("last_response", {}))
			"failed":
				push_warning("PixelLab: job %s failed: %s" % [job_id, body.get("last_response", {}).get("detail", "unknown")])
				callback.call(null)
			_:
				# Still processing — wait and retry
				if _scene_tree != null:
					await _scene_tree.create_timer(POLL_INTERVAL).timeout
				_poll_loop(job_id, callback)
	)


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
	var headers := [
		"Authorization: Bearer %s" % _api_key,
	]
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
		callback.call({"ok": false, "error": "Invalid Pixel Lab API key"})
		return
	if code == 402:
		callback.call({"ok": false, "error": "Insufficient Pixel Lab credits"})
		return
	if code >= 400:
		callback.call({"ok": false, "error": "HTTP %d" % code})
		return
	var json := JSON.new()
	if json.parse(body_bytes.get_string_from_utf8()) != OK:
		callback.call({"ok": false, "error": "JSON parse error"})
		return
	callback.call({"ok": true, "body": json.get_data()})
