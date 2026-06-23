extends RefCounted
class_name TacticalFacing

enum Direction {
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST,
}

enum AttackArc {
	FRONT,
	RIGHT_FLANK,
	LEFT_FLANK,
	BACK,
}

const DIRECTION_VECTORS := {
	Direction.NORTH: Vector2i(0, -1),
	Direction.NORTH_EAST: Vector2i(1, -1),
	Direction.EAST: Vector2i(1, 0),
	Direction.SOUTH_EAST: Vector2i(1, 1),
	Direction.SOUTH: Vector2i(0, 1),
	Direction.SOUTH_WEST: Vector2i(-1, 1),
	Direction.WEST: Vector2i(-1, 0),
	Direction.NORTH_WEST: Vector2i(-1, -1),
}

const VISUAL_NAMES: Array[String] = [
	"north",
	"north_east",
	"east",
	"south_east",
	"south",
	"south_west",
	"west",
	"north_west",
]


static func direction_from_visual(name: String) -> int:
	var index := VISUAL_NAMES.find(name)
	if index < 0:
		return Direction.SOUTH
	return index


static func visual_from_direction(direction: int) -> String:
	if direction < 0 or direction >= VISUAL_NAMES.size():
		return "south"
	return VISUAL_NAMES[direction]


static func vector_from_direction(direction: int) -> Vector2i:
	return DIRECTION_VECTORS.get(direction, Vector2i(0, 1))


static func direction_from_vector(delta: Vector2i) -> int:
	if delta == Vector2i.ZERO:
		return Direction.SOUTH
	var best_dir := Direction.SOUTH
	var best_dot := -999.0
	for direction in DIRECTION_VECTORS.keys():
		var basis: Vector2i = DIRECTION_VECTORS[direction]
		var dot := float(basis.x * delta.x + basis.y * delta.y)
		if dot > best_dot:
			best_dot = dot
			best_dir = direction
	return best_dir


static func angle_degrees(direction: int) -> float:
	match direction:
		Direction.EAST:
			return 0.0
		Direction.NORTH_EAST:
			return 45.0
		Direction.NORTH:
			return 90.0
		Direction.NORTH_WEST:
			return 135.0
		Direction.WEST:
			return 180.0
		Direction.SOUTH_WEST:
			return 225.0
		Direction.SOUTH:
			return 270.0
		Direction.SOUTH_EAST:
			return 315.0
	return 270.0


static func classify_attack_arc(defender_facing: int, attack_delta: Vector2i) -> int:
	var attack_dir := direction_from_vector(attack_delta)
	var defender_angle := angle_degrees(defender_facing)
	var attack_angle := angle_degrees(attack_dir)
	var diff := fposmod(attack_angle - defender_angle + 180.0, 360.0) - 180.0
	if absf(diff) <= 45.0:
		return AttackArc.FRONT
	if diff > 45.0 and diff <= 135.0:
		return AttackArc.RIGHT_FLANK
	if diff < -45.0 and diff >= -135.0:
		return AttackArc.LEFT_FLANK
	return AttackArc.BACK


static func opposite_arc(arc: int) -> int:
	match arc:
		AttackArc.FRONT:
			return AttackArc.BACK
		AttackArc.BACK:
			return AttackArc.FRONT
		AttackArc.RIGHT_FLANK:
			return AttackArc.LEFT_FLANK
		AttackArc.LEFT_FLANK:
			return AttackArc.RIGHT_FLANK
	return AttackArc.FRONT


static func arc_label(arc: int) -> String:
	match arc:
		AttackArc.FRONT:
			return "front"
		AttackArc.RIGHT_FLANK:
			return "right flank"
		AttackArc.LEFT_FLANK:
			return "left flank"
		AttackArc.BACK:
			return "back"
	return "front"


static func rotate_direction(direction: int, step: int) -> int:
	var count := VISUAL_NAMES.size()
	return posmod(direction + step, count)


static func yaw_radians(direction: int) -> float:
	var vec := vector_from_direction(direction)
	return atan2(float(vec.x), float(vec.y))