extends Resource
class_name SkillData

enum SkillType { SPELL, ABILITY, PASSIVE }
enum Tier { I, II, III, IV }
enum CastingTime { INSTANT, ONE_ROUND, TWO_ROUNDS }
enum Area { SINGLE, CONE, RADIUS, LINE, SELF }
enum TargetType { SINGLE_ENEMY, SINGLE_ALLY, SELF, AOE }
enum StatCheck { NO_ROLL, AUTO_HIT, INT_VS_POW, STR_VS_DEF, FTH_VS_POW, SPD_VS_SPD }
enum FormulaType { NONE, FLAT, PERCENT_MAX_HP, CASTER_POW }
enum AbsorptionTier { NORMAL, UNCOMMON, RARE }

# Identity
@export var skill_id: String = ""
@export var display_name: String = ""
@export var skill_type: SkillType = SkillType.ABILITY
@export var tier: Tier = Tier.I
@export var grimoire_source: String = ""
@export var flavor_text: String = ""

# Cost
@export var mp_cost: int = 0
@export var corruption_cost: float = 0.0

# Timing & Range
@export var casting_time: CastingTime = CastingTime.INSTANT
@export_range(0, 99) var range_cells: int = 1
@export var area: Area = Area.SINGLE

# Targeting
@export var target: TargetType = TargetType.SINGLE_ENEMY
@export var stat_check: StatCheck = StatCheck.NO_ROLL

# Effect
@export_multiline var primary_effect_description: String = ""
@export_range(0, 99) var duration_turns: int = 0
@export var status_applied: String = ""

# Damage formula
@export var damage_formula: FormulaType = FormulaType.NONE
@export var damage_value: float = 0.0

# Healing formula
@export var healing_formula: FormulaType = FormulaType.NONE
@export var healing_value: float = 0.0

# Stat modifier
@export var stat_modifier_stat: String = ""
@export var stat_modifier_amount: int = 0
@export var stat_modifier_duration: int = 0

# VFX
@export var vfx_scene_path: String = ""

# Absorption & tags
@export var absorption_tier: AbsorptionTier = AbsorptionTier.NORMAL
@export var tags: Array[String] = []
