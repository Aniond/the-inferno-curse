extends RefCounted
class_name AbsorptionResolver

const BASE_CHANCE_COMMON: float = 1.0
const BASE_CHANCE_UNCOMMON: float = 0.5
const BASE_CHANCE_PASSIVE: float = 0.1
const FLOOR_CHANCE: float = 0.10
const PASSIVE_FLOOR: float = 0.10

class AbsorptionResult:
	var skill_id: String = ""
	var skill_resource: Resource = null
	var succeeded: bool = false
	var roll: float = 0.0
	var chance: float = 0.0
	var soul_gem: SoulGem = null


static func resolve(monster_sheet: MonsterSheet, character_sheet: CharacterSheet) -> AbsorptionResult:
	var result := AbsorptionResult.new()

	var candidate := _pick_skill_candidate(monster_sheet)
	if candidate.is_empty():
		return result

	result.skill_id = candidate["skill_id"]
	result.skill_resource = candidate["skill_resource"]

	var absorb_count: int = character_sheet.absorbed_skills.get(result.skill_id, 0)
	var tier: int = candidate["tier"]
	result.chance = _calculate_chance(tier, absorb_count)
	result.roll = randf()
	result.succeeded = result.roll < result.chance

	if result.succeeded:
		character_sheet.absorbed_skills[result.skill_id] = absorb_count + 1
		var gem := SoulGem.new()
		gem.skill_id = result.skill_id
		gem.skill_resource = result.skill_resource
		gem.absorbed_from = monster_sheet.monster_id
		character_sheet.soul_gems.append(gem)
		result.soul_gem = gem

	return result


static func _pick_skill_candidate(monster_sheet: MonsterSheet) -> Dictionary:
	var pool: Array[Dictionary] = []

	var skill_refs := {
		"normal": monster_sheet.normal_ability,
		"uncommon": monster_sheet.uncommon_ability,
		"rare": monster_sheet.rare_ability,
	}

	for tier_key in skill_refs:
		var skill_id: String = skill_refs[tier_key]
		if skill_id == "":
			continue
		var tier_val := _tier_int(tier_key)
		var weight := _tier_weight(tier_val)
		for i in range(weight):
			pool.append({
				"skill_id": skill_id,
				"tier": tier_val,
				"skill_resource": _load_skill(skill_id),
			})

	if pool.is_empty():
		return {}

	return pool[randi() % pool.size()]


static func _calculate_chance(tier: int, absorb_count: int) -> float:
	var base: float
	match tier:
		0:  # Common
			base = BASE_CHANCE_COMMON
		1:  # Uncommon
			base = BASE_CHANCE_UNCOMMON
		2:  # Passive
			return BASE_CHANCE_PASSIVE  # flat, no halving
		_:
			base = BASE_CHANCE_COMMON

	# Halve for each previous absorption, floor at 10%
	var chance := base / pow(2.0, absorb_count)
	return maxf(chance, FLOOR_CHANCE)


static func _tier_int(tier_key: String) -> int:
	match tier_key:
		"normal": return 0
		"uncommon": return 1
		"rare": return 2
	return 0


static func _tier_weight(tier: int) -> int:
	# Higher weight = more likely to be picked from the pool
	match tier:
		0: return 4  # Common picked most often
		1: return 2  # Uncommon less often
		2: return 1  # Passive rarely
	return 1


static func _load_skill(skill_id: String) -> Resource:
	var path := "res://data/skills/%s.tres" % skill_id
	if ResourceLoader.exists(path):
		return load(path)
	return null


static func get_chance_preview(tier: int, absorb_count: int) -> String:
	var chance := _calculate_chance(tier, absorb_count)
	return "%d%%" % roundi(chance * 100.0)
