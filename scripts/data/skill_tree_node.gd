extends Resource
class_name SkillTreeNode

@export var skill_id: String = ""
@export var display_name: String = ""
@export_range(1, 3) var tier: int = 1
@export var gem_cost: int = 1
@export var family: String = ""  # e.g. "limbo", "martial", "divine"

# Stat deltas applied on top of base SkillData at this tier
@export var damage_multiplier_bonus: float = 0.0   # added to base damage_value
@export var healing_bonus: float = 0.0             # added to base healing_value
@export var mp_cost_reduction: int = 0             # subtracted from base mp_cost
@export var range_bonus: int = 0                   # added to base range_cells

# Tier III qualitative effect
@export_multiline var new_effect_description: String = ""
@export var new_status_applied: String = ""
@export var new_status_duration: int = 0

# Tree connections
@export var requires: Array[String] = []   # skill_ids that must be tier >= 1 to see this node
@export var unlocks: Array[String] = []    # skill_ids made available when this node is purchased

# UI layout hint (procedural positioning)
@export var tree_position: Vector2 = Vector2.ZERO
