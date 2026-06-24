extends RefCounted
class_name AiDirective

## A commander's instruction to one subordinate for the coming round. The unit
## scorer (EnemyTacticalAI) reads these as biases, not orders: a high-INT unit
## may still reject a suicidal directive. All fields are optional; an empty
## directive is a no-op.

enum Posture {
	PRESS,    # player vulnerable -> commit together, accept exposure
	HOLD,     # player strong -> take cover, wait for an opening
	HARASS,   # chip and maneuver, favor ranged / flanks
}

enum Slot {
	NONE,
	SCREEN,        # stand between the player and the commander
	FLANK_LEFT,    # take the left side of the focus target
	FLANK_RIGHT,   # take the right side of the focus target
	ANCHOR,        # hold near the commander / anchor cell
}

var posture: int = Posture.HARASS
var formation_slot: int = Slot.NONE
var focus_target: CombatActor = null
var anchor_cell: CombatCell = null


func posture_name() -> String:
	match posture:
		Posture.PRESS: return "PRESS"
		Posture.HOLD: return "HOLD"
		_: return "HARASS"


func slot_name() -> String:
	match formation_slot:
		Slot.SCREEN: return "screen"
		Slot.FLANK_LEFT: return "flank-L"
		Slot.FLANK_RIGHT: return "flank-R"
		Slot.ANCHOR: return "anchor"
		_: return "free"
