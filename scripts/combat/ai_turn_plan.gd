extends RefCounted
class_name AiTurnPlan

## One candidate action for an enemy unit's turn: where to stand, who to
## attack from there, and the facing to attack from. Produced and scored by
## EnemyTacticalAI; executed by the motion layer in battle_test_map.gd.

var destination_cell: CombatCell = null
var target: CombatActor = null
var facing: int = 0  # TacticalFacing direction
var is_ranged: bool = false
var score: float = 0.0
var reasons: Array[String] = []


func add_reason(text: String) -> void:
	reasons.append(text)


func describe() -> String:
	var dest := "stay" if destination_cell == null else str(destination_cell.grid_position)
	var tgt := "no target" if target == null else target.display_name
	var head := "AI plan -> move:%s attack:%s (score %.1f)" % [dest, tgt, score]
	if reasons.is_empty():
		return head
	return "%s | %s" % [head, ", ".join(reasons)]
