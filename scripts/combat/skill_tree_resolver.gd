extends RefCounted
class_name SkillTreeResolver

const SKILL_TREE_DIR := "res://data/skill_tree/"

enum UnlockResult {
	OK,
	INSUFFICIENT_GEMS,
	REQUIRES_NOT_MET,
	ALREADY_MAXED,
}


static func can_unlock(node: SkillTreeNode, sheet: CharacterSheet) -> UnlockResult:
	var current_tier: int = sheet.unlocked_nodes.get(node.skill_id, 0)

	if current_tier >= 3:
		return UnlockResult.ALREADY_MAXED

	# Must unlock tiers in order
	if node.tier != current_tier + 1:
		return UnlockResult.REQUIRES_NOT_MET

	# Check cross-skill requirements
	for req_id in node.requires:
		if sheet.unlocked_nodes.get(req_id, 0) < 1:
			return UnlockResult.REQUIRES_NOT_MET

	# Count unspent gems of this skill_id
	var gem_count := _count_gems(node.skill_id, sheet)
	if gem_count < node.gem_cost:
		return UnlockResult.INSUFFICIENT_GEMS

	return UnlockResult.OK


static func unlock(node: SkillTreeNode, sheet: CharacterSheet) -> UnlockResult:
	var result := can_unlock(node, sheet)
	if result != UnlockResult.OK:
		return result

	# Spend gems
	_spend_gems(node.skill_id, node.gem_cost, sheet)

	# Increment tier
	sheet.unlocked_nodes[node.skill_id] = node.tier

	# Fire cross-branch unlocks — add to equipped if newly available
	for unlocked_id in node.unlocks:
		if not sheet.unlocked_nodes.has(unlocked_id):
			sheet.unlocked_nodes[unlocked_id] = 0  # mark as visible/available

	return UnlockResult.OK


static func get_effective_skill(skill_id: String, sheet: CharacterSheet) -> SkillData:
	var base := _load_base_skill(skill_id)
	if base == null:
		return null

	var current_tier: int = sheet.unlocked_nodes.get(skill_id, 0)
	if current_tier == 0:
		return base

	# Apply deltas from each unlocked tier cumulatively
	var effective := base.duplicate() as SkillData
	for tier in range(1, current_tier + 1):
		var node := _load_node(skill_id, tier)
		if node == null:
			continue
		effective.damage_value += node.damage_multiplier_bonus
		effective.healing_value += node.healing_bonus
		effective.mp_cost = maxi(0, effective.mp_cost - node.mp_cost_reduction)
		effective.range_cells += node.range_bonus
		if node.new_status_applied != "":
			effective.status_applied = node.new_status_applied
			effective.duration_turns = node.new_status_duration

	return effective


static func get_node_for_tier(skill_id: String, tier: int) -> SkillTreeNode:
	return _load_node(skill_id, tier)


static func get_all_visible_nodes(sheet: CharacterSheet) -> Array[SkillTreeNode]:
	var visible: Array[SkillTreeNode] = []
	var dir := DirAccess.open(SKILL_TREE_DIR)
	if dir == null:
		return visible
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var node := load(SKILL_TREE_DIR + file_name) as SkillTreeNode
			if node != null and _is_visible(node, sheet):
				visible.append(node)
		file_name = dir.get_next()
	return visible


static func _is_visible(node: SkillTreeNode, sheet: CharacterSheet) -> bool:
	# Tier 1 nodes are visible if the skill is in soul_gems or already unlocked
	if node.tier == 1:
		return sheet.unlocked_nodes.has(node.skill_id) or _count_gems(node.skill_id, sheet) > 0
	# Higher tiers visible if previous tier is unlocked
	var current_tier: int = sheet.unlocked_nodes.get(node.skill_id, 0)
	if node.tier == current_tier + 1:
		return true
	# Cross-branch: visible if a node that unlocks this skill_id is purchased
	for res_id in sheet.unlocked_nodes:
		var prev_node := _load_node(res_id, sheet.unlocked_nodes[res_id])
		if prev_node != null and node.skill_id in prev_node.unlocks:
			return true
	return false


static func _count_gems(skill_id: String, sheet: CharacterSheet) -> int:
	var count := 0
	for gem in sheet.soul_gems:
		if gem is SoulGem and gem.skill_id == skill_id:
			count += 1
	return count


static func _spend_gems(skill_id: String, amount: int, sheet: CharacterSheet) -> void:
	var spent := 0
	var remaining: Array[Resource] = []
	for gem in sheet.soul_gems:
		if gem is SoulGem and gem.skill_id == skill_id and spent < amount:
			spent += 1
		else:
			remaining.append(gem)
	sheet.soul_gems = remaining


static func _load_base_skill(skill_id: String) -> SkillData:
	var path := "res://data/skills/%s.tres" % skill_id
	if ResourceLoader.exists(path):
		return load(path) as SkillData
	return null


static func _load_node(skill_id: String, tier: int) -> SkillTreeNode:
	var path := "%s%s_tier%d.tres" % [SKILL_TREE_DIR, skill_id, tier]
	if ResourceLoader.exists(path):
		return load(path) as SkillTreeNode
	return null
