extends Resource
class_name JobSkill

enum SkillCategory { ACTIVE, PASSIVE }
enum TargetType { SELF, SINGLE_ALLY, SINGLE_ENEMY, AOE_ALLY, AOE_ENEMY, TILE }

@export var skill_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var flavor_text: String = ""
@export var category: SkillCategory = SkillCategory.ACTIVE
@export var job_id: String = ""           # e.g. "fornaro", "mugnaio"
@export var jp_cost: int = 0              # JP to unlock
@export var mp_cost: int = 0
@export var target: TargetType = TargetType.SINGLE_ENEMY
@export var range_cells: int = 1
@export var duration_turns: int = 0

# Damage / healing
@export var damage_formula: int = 0      # FormulaType enum from SkillData
@export var damage_value: float = 0.0
@export var healing_formula: int = 0
@export var healing_value: float = 0.0

# Status effect
@export var status_applied: String = ""
@export var stat_modifier_stat: String = ""
@export var stat_modifier_amount: int = 0

# Passive stat bonuses (applied while equipped as a trait)
@export var passive_hp_bonus: int = 0
@export var passive_mp_bonus: int = 0
@export var passive_str_bonus: int = 0
@export var passive_def_bonus: int = 0
@export var passive_spd_bonus: int = 0
@export var passive_fth_bonus: int = 0
@export var passive_pow_bonus: int = 0
@export var passive_mp_regen: int = 0    # MP gained per turn

# Special flags
@export var is_signature: bool = false   # Tier II signature ability
@export var requires_church_visit: bool = false
@export var aoe_radius: int = 0
@export var creates_item: String = ""    # item_id spawned (for Bake)
@export var ct_modifier: float = 0.0    # CT gain modifier applied to target
@export var vfx_scene_path: String = ""

@export var tags: Array[String] = []
