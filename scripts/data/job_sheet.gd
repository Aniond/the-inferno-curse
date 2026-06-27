extends Resource
class_name JobSheet

# One JobSheet per job per character — tracks JP and unlock state for that job.
@export var job_id: String = ""
@export var display_name: String = ""
@export var tier: int = 1                       # 1 = base, 2 = advanced
@export var required_job_id: String = ""        # Tier II requires this Tier I job

@export var job_level: int = 0                  # 0-10, raised by earning JP
@export var jp_earned: int = 0                  # total JP ever earned in this job
@export var jp_spent: int = 0                   # total JP spent on skills
@export var unlocked_skills: Array[String] = [] # skill_ids unlocked

# Stat bonuses granted per job level (applied while this is active job)
@export var level_hp_per_level: int = 0
@export var level_mp_per_level: int = 0
@export var level_str_per_level: int = 0
@export var level_def_per_level: int = 0
@export var level_spd_per_level: int = 0
@export var level_fth_per_level: int = 0
@export var level_pow_per_level: int = 0

@export var flavor_text: String = ""
@export var icon_path: String = ""


func get_jp_available() -> int:
	return jp_earned - jp_spent


func can_unlock(skill: JobSkill) -> bool:
	if unlocked_skills.has(skill.skill_id):
		return false
	return get_jp_available() >= skill.jp_cost


func unlock_skill(skill: JobSkill) -> bool:
	if not can_unlock(skill):
		return false
	jp_spent += skill.jp_cost
	unlocked_skills.append(skill.skill_id)
	_recalculate_job_level()
	return true


func earn_jp(amount: int) -> void:
	jp_earned += amount
	_recalculate_job_level()


func _recalculate_job_level() -> void:
	# Every 100 JP earned raises job level, cap at 10
	job_level = mini(jp_earned / 100.0, 10)
