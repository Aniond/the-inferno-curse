extends RefCounted
class_name CombatTurnController

enum Phase { MOVE, ROTATE, ACT, DONE }

var phase: int = Phase.MOVE
var has_moved: bool = false
var has_rotated: bool = false
var has_acted: bool = false


func reset() -> void:
	phase = Phase.MOVE
	has_moved = false
	has_rotated = false
	has_acted = false


func can_move() -> bool:
	return phase == Phase.MOVE and not has_moved


func can_rotate() -> bool:
	return (phase == Phase.MOVE or phase == Phase.ROTATE) and not has_acted


func can_act() -> bool:
	return phase == Phase.ACT and not has_acted


func skip_move() -> void:
	if phase == Phase.MOVE:
		phase = Phase.ROTATE


func finish_move() -> void:
	has_moved = true
	phase = Phase.ROTATE


func finish_rotate() -> void:
	has_rotated = true
	phase = Phase.ACT


func skip_rotate() -> void:
	if phase == Phase.ROTATE:
		phase = Phase.ACT


func finish_act() -> void:
	has_acted = true
	phase = Phase.DONE


func is_done() -> bool:
	return phase == Phase.DONE