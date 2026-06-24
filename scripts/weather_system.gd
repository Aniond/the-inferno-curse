extends Node
class_name WeatherSystem

## Weather system for battles and world.
## Mixture of location (beach = hurricanes) and AI/random events (mid-battle changes).
## Affects visuals (env/fog/ambient), combat (move, LOS, accuracy, CT, height).
## Tie to stat_modifiers later. AI integration deferred.

enum WeatherType {
	CLEAR,
	OVERCAST,
	RAIN,
	THUNDERSTORM,
	FOG,
	HURRICANE,
	BLIZZARD,
	HEATWAVE
}

enum LocationType {
	TAVERN,
	BEACH,
	FOREST,
	PLAINS,
	MOUNTAIN
}

@export var current_location: LocationType = LocationType.TAVERN
@export var current_weather: WeatherType = WeatherType.CLEAR

# Probabilities per location [weather: weight]
var location_weather_probs := {
	LocationType.TAVERN: {WeatherType.CLEAR: 0.5, WeatherType.OVERCAST: 0.3, WeatherType.RAIN: 0.15, WeatherType.FOG: 0.05},
	LocationType.BEACH: {WeatherType.CLEAR: 0.2, WeatherType.RAIN: 0.2, WeatherType.THUNDERSTORM: 0.3, WeatherType.HURRICANE: 0.3},
	LocationType.FOREST: {WeatherType.CLEAR: 0.4, WeatherType.OVERCAST: 0.3, WeatherType.RAIN: 0.2, WeatherType.FOG: 0.1},
	LocationType.PLAINS: {WeatherType.CLEAR: 0.6, WeatherType.OVERCAST: 0.2, WeatherType.RAIN: 0.15, WeatherType.THUNDERSTORM: 0.05},
	LocationType.MOUNTAIN: {WeatherType.CLEAR: 0.3, WeatherType.OVERCAST: 0.2, WeatherType.BLIZZARD: 0.3, WeatherType.FOG: 0.2}
}

# Combat and visual modifiers per weather
var weather_data := {
	WeatherType.CLEAR: {
		"name": "Clear",
		"fog_density": 0.0045,
		"ambient_mult": 1.0,
		"move_cost_mult": 1.0,
		"los_mult": 1.0,
		"ranged_acc_mult": 1.0,
		"ct_gain_mult": 1.0,
		"height_cost_mult": 1.0,
		"damage_mult": 1.0
	},
	WeatherType.OVERCAST: {
		"name": "Overcast",
		"fog_density": 0.006,
		"ambient_mult": 0.9,
		"move_cost_mult": 1.0,
		"los_mult": 0.95,
		"ranged_acc_mult": 0.95,
		"ct_gain_mult": 1.0,
		"height_cost_mult": 1.0,
		"damage_mult": 1.0
	},
	WeatherType.RAIN: {
		"name": "Rain",
		"fog_density": 0.01,
		"ambient_mult": 0.75,
		"move_cost_mult": 1.2,
		"los_mult": 0.8,
		"ranged_acc_mult": 0.8,
		"ct_gain_mult": 0.9,
		"height_cost_mult": 1.3,
		"damage_mult": 0.95
	},
	WeatherType.THUNDERSTORM: {
		"name": "Thunderstorm",
		"fog_density": 0.015,
		"ambient_mult": 0.6,
		"move_cost_mult": 1.4,
		"los_mult": 0.7,
		"ranged_acc_mult": 0.7,
		"ct_gain_mult": 0.8,
		"height_cost_mult": 1.5,
		"damage_mult": 1.1  # lightning risk
	},
	WeatherType.FOG: {
		"name": "Fog",
		"fog_density": 0.025,
		"ambient_mult": 0.8,
		"move_cost_mult": 1.1,
		"los_mult": 0.4,
		"ranged_acc_mult": 0.5,
		"ct_gain_mult": 1.0,
		"height_cost_mult": 1.1,
		"damage_mult": 0.9
	},
	WeatherType.HURRICANE: {
		"name": "Hurricane",
		"fog_density": 0.03,
		"ambient_mult": 0.5,
		"move_cost_mult": 2.0,
		"los_mult": 0.5,
		"ranged_acc_mult": 0.4,
		"ct_gain_mult": 0.6,
		"height_cost_mult": 2.5,
		"damage_mult": 1.5
	},
	WeatherType.BLIZZARD: {
		"name": "Blizzard",
		"fog_density": 0.02,
		"ambient_mult": 0.7,
		"move_cost_mult": 1.8,
		"los_mult": 0.3,
		"ranged_acc_mult": 0.3,
		"ct_gain_mult": 0.7,
		"height_cost_mult": 2.0,
		"damage_mult": 1.2
	},
	WeatherType.HEATWAVE: {
		"name": "Heatwave",
		"fog_density": 0.003,
		"ambient_mult": 1.2,
		"move_cost_mult": 1.3,
		"los_mult": 1.0,
		"ranged_acc_mult": 0.9,
		"ct_gain_mult": 1.2,
		"height_cost_mult": 1.4,
		"damage_mult": 0.85
	}
}

var combat_state: Node = null  # set from battle map
signal weather_changed(new_weather: WeatherType, location: LocationType)

func _ready() -> void:
	# Demo: set initial based on current location
	set_weather_for_location(current_location)

func set_location(loc: LocationType) -> void:
	current_location = loc
	# Re-roll weather appropriate for new location
	set_weather_for_location(loc)

func set_weather_for_location(loc: LocationType, force: int = -1) -> void:
	if force >= 0:
		set_weather(force as WeatherType)
		return
	var probs = location_weather_probs.get(loc, location_weather_probs[LocationType.TAVERN])
	var total = 0.0
	for w in probs:
		total += probs[w]
	var roll = randf() * total
	var cum = 0.0
	for w in probs:
		cum += probs[w]
		if roll <= cum:
			set_weather(w as WeatherType)
			return

func set_weather(new_weather: WeatherType) -> void:
	if new_weather == current_weather:
		return
	current_weather = new_weather
	apply_environment_effects()
	apply_combat_effects()
	weather_changed.emit(current_weather, current_location)
	print("Weather changed to: ", weather_data[new_weather]["name"], " in ", LocationType.keys()[current_location])

func apply_environment_effects() -> void:
	# Integrate with existing day_night_cycle and WorldEnvironment
	var env = get_node_or_null("../WorldEnvironment")
	if not env or not env.environment:
		return
	var data = weather_data[current_weather]
	var base_fog = data["fog_density"]
	var base_ambient = data["ambient_mult"]
	# Compose with day/night if available (safe)
	var day_cycle = get_node_or_null("../DayNightCycle")
	var day_f := 0.5
	if day_cycle and "day_f" in day_cycle:  # rough check
		day_f = day_cycle.day_f if day_cycle.has("day_f") else 0.5
	base_fog *= lerp(0.8, 1.2, 1.0 - day_f)
	base_ambient *= lerp(0.7, 1.0, day_f)
	env.environment.fog_density = base_fog
	env.environment.ambient_light_energy *= base_ambient
	# Could adjust glow, sky colors etc. for weather

func get_combat_mod(mod_name: String) -> float:
	var data = weather_data.get(current_weather, weather_data[WeatherType.CLEAR])
	return data.get(mod_name, 1.0)

func apply_combat_effects() -> void:
	# Called to push mods to combat_state / actors if needed
	if combat_state and combat_state.has_method("apply_weather_mods"):
		combat_state.apply_weather_mods(self)

# Dynamic mid-battle change (called from battle map on turns)
func roll_for_weather_change() -> void:
	var probs = location_weather_probs.get(current_location, {})
	if probs.is_empty():
		return
	# Higher chance in extreme locations
	var change_chance = 0.15 if current_location == LocationType.BEACH else 0.08
	if randf() < change_chance:
		set_weather_for_location(current_location)

func get_description() -> String:
	var data = weather_data[current_weather]
	return "%s (%s)" % [data["name"], LocationType.keys()[current_location]]

# For stat modifiers integration later
func get_weather_modifiers() -> Dictionary:
	var data = weather_data[current_weather]
	return {
		"move": data["move_cost_mult"],
		"los": data["los_mult"],
		"ranged": data["ranged_acc_mult"],
		"ct": data["ct_gain_mult"],
		"height": data["height_cost_mult"]
	}
