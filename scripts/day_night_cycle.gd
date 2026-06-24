extends Node
class_name DayNightCycle

## Complete day/night cycle for the tavern (and future city nodes).
## Drives Sun (DirectionalLight), WorldEnvironment (ambient/fog/glow + sky),
## and local warm lights (torches get relative boost at night).
## Uses accelerated game time. Ortho camera + interior friendly.

@export_group("Time")
## 10 in-game minutes (a "block") passes roughly every 7.5–10 real seconds.
## This gives a natural-feeling accelerated day (full 24h day ≈ 18–24 real minutes).
@export var block_minutes: float = 10.0
@export var real_seconds_per_block: float = 8.75  # 7.5 to 10 range — tweak for faster/slower feel
@export_range(0.0, 1.0) var start_time: float = 0.28  # ~dawn

@export_group("Sun")
@export var sun_max_energy: float = 1.1
@export var sun_night_energy: float = 0.05
@export var sun_path_elevation_deg: float = 78.0   # max height at noon

@export_group("Lighting Response")
@export var torch_night_mult: float = 1.55   # how much stronger torches feel at night
@export var ambient_day_mult: float = 1.8

var time_of_day: float = 0.0  # 0.0 = midnight, 0.5 = noon
var _phase: String = "night"

signal time_changed(time_of_day: float, phase: String)

var sun: DirectionalLight3D
var world_env: WorldEnvironment
var _env: Environment
var _torches: Array[Node] = []

# Color palettes (lerped by time)
const COL_NIGHT := Color(0.04, 0.06, 0.12)
const COL_DAWN := Color(0.95, 0.55, 0.35)
const COL_DAY := Color(1.0, 0.97, 0.90)
const COL_DUSK := Color(0.98, 0.65, 0.30)

func _ready() -> void:
	time_of_day = start_time
	_resolve_nodes()
	_setup_sky_if_needed()
	_find_torches()
	_apply_initial_lighting()

func _process(delta: float) -> void:
	if real_seconds_per_block <= 0.0:
		return

	# Fraction of a full day represented by one block
	var fraction_per_block := block_minutes / (24.0 * 60.0)

	# How much of the day advances this frame
	var advance := (delta / real_seconds_per_block) * fraction_per_block
	time_of_day = fmod(time_of_day + advance, 1.0)

	_update_lighting(delta)

func _resolve_nodes() -> void:
	# Try common relative paths under the World root
	sun = get_node_or_null("../Sun") as DirectionalLight3D
	world_env = get_node_or_null("../WorldEnvironment") as WorldEnvironment
	if world_env and world_env.environment:
		# Duplicate so we don't mutate the shared .tres resource
		_env = world_env.environment.duplicate()
		world_env.environment = _env

func _setup_sky_if_needed() -> void:
	if _env == null:
		return
	if _env.sky == null:
		var sky := Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		_env.sky = sky
	# Reasonable defaults for our dark medieval look
	var psm := _env.sky.sky_material as ProceduralSkyMaterial
	if psm:
		psm.sky_top_color = Color(0.12, 0.16, 0.28)
		psm.sky_horizon_color = Color(0.55, 0.45, 0.35)
		psm.ground_horizon_color = Color(0.18, 0.15, 0.12)
		psm.sun_angle_max = 15.0
		psm.sun_curve = 0.08
		# sun disk color is driven primarily by the DirectionalLight (Sun) + sky horizon

func _find_torches() -> void:
	_torches.clear()
	_collect_nodes_with_script(get_tree().current_scene, "torch_light.gd", _torches)

func _collect_nodes_with_script(node: Node, script_name_ends: String, out: Array[Node]) -> void:
	var sc: Script = node.get_script()
	if sc and sc.resource_path.ends_with(script_name_ends):
		out.append(node)
	for child in node.get_children():
		_collect_nodes_with_script(child, script_name_ends, out)

func _apply_initial_lighting() -> void:
	_update_lighting(0.0, true)

func _update_lighting(_delta: float, force: bool = false) -> void:
	var t := time_of_day
	var prev_phase := _phase
	_phase = _get_phase(t)
	if _phase != prev_phase or force:
		time_changed.emit(t, _phase)

	# Day factor shared for sun/env/torches (0 = night, 1 = full day)
	var day_f: float = clampf(sin((t - 0.22) * TAU) * 0.5 + 0.5, 0.0, 1.0)

	# === SUN ===
	if sun:
		# Elevation peaks around t=0.5 (noon)
		var elev := sin((t - 0.25) * TAU) * sun_path_elevation_deg
		var azimuth := (t * 360.0) - 90.0   # rotate so "east" sunrise-ish
		sun.rotation_degrees = Vector3(-elev, azimuth, 0.0)

		# Energy: strong day, near-zero at night, ramps at dawn/dusk
		var day_energy := clampf(sin((t - 0.22) * TAU) * 0.5 + 0.5, 0.0, 1.0)
		var e: float = lerp(sun_night_energy, sun_max_energy, day_energy)
		sun.light_energy = e

		# Color temperature
		var sun_c: Color
		if t < 0.22 or t > 0.78:
			sun_c = COL_NIGHT
		elif t < 0.30:
			sun_c = COL_DAWN.lerp(COL_DAY, (t - 0.22) / 0.08)
		elif t < 0.70:
			sun_c = COL_DAY
		else:
			sun_c = COL_DAY.lerp(COL_DUSK, (t - 0.70) / 0.08)
		sun.light_color = sun_c

	# === WORLD ENVIRONMENT (ambient + fog + glow + sky) ===
	if _env:
		# Ambient
		_env.ambient_light_color = COL_NIGHT.lerp(Color(0.65, 0.62, 0.58), day_f * 0.6)
		_env.ambient_light_energy = lerp(0.28, 0.72, day_f) * ambient_day_mult

		# Fog (darker/warmer at night, slightly denser feel)
		_env.fog_light_color = Color(0.06, 0.05, 0.04).lerp(Color(0.55, 0.48, 0.38), day_f * 0.75)
		_env.fog_light_energy = lerp(0.25, 0.55, day_f)
		_env.fog_density = lerp(0.0065, 0.0038, day_f)

		# Glow subtle boost at night for cozy torch bloom
		_env.glow_intensity = lerp(0.42, 0.72, 1.0 - day_f * 0.7)

		# Sky (if using ProceduralSkyMaterial)
		if _env.sky and _env.sky.sky_material is ProceduralSkyMaterial:
			var psm: ProceduralSkyMaterial = _env.sky.sky_material
			if t < 0.22 or t > 0.78:
				psm.sky_top_color = Color(0.02, 0.03, 0.08)
				psm.sky_horizon_color = Color(0.12, 0.10, 0.14)
			elif t < 0.30:
				var f := (t - 0.22) / 0.08
				psm.sky_top_color = Color(0.12, 0.15, 0.32).lerp(Color(0.55, 0.65, 0.95), f)
				psm.sky_horizon_color = Color(0.55, 0.42, 0.32).lerp(Color(0.82, 0.78, 0.68), f)
			elif t < 0.70:
				psm.sky_top_color = Color(0.55, 0.65, 0.95)
				psm.sky_horizon_color = Color(0.82, 0.78, 0.68)
			else:
				var f := (t - 0.70) / 0.08
				psm.sky_top_color = Color(0.55, 0.65, 0.95).lerp(Color(0.18, 0.12, 0.22), f)
				psm.sky_horizon_color = Color(0.82, 0.78, 0.68).lerp(Color(0.55, 0.38, 0.25), f)

	# === TORCHES (and other warm lights) ===
	var torch_factor: float = lerp(0.65, torch_night_mult, 1.0 - day_f)
	for torch: Node in _torches:
		if torch.has_method("set_external_multiplier"):
			torch.set_external_multiplier(torch_factor)
		elif torch.has_method("set_night_factor"):   # fallback name
			torch.set_night_factor(torch_factor)

func _get_phase(t: float) -> String:
	if t < 0.20 or t > 0.82:
		return "night"
	elif t < 0.28:
		return "dawn"
	elif t < 0.72:
		return "day"
	else:
		return "dusk"
