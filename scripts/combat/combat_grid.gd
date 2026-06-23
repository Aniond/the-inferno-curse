extends Node3D
class_name CombatGrid

@export var columns: int = 10
@export var rows: int = 10
@export var cell_width: float = 1.0
@export var cell_depth: float = 1.0
@export var origin: Vector3 = Vector3.ZERO
@export var default_height_level: int = 0
@export var allow_diagonal_movement: bool = true

var cells: Dictionary = {}

func _ready() -> void:
	build_grid()

func build_grid() -> void:
	cells.clear()
	for x in range(columns):
		for y in range(rows):
			var coord: Vector2i = Vector2i(x, y)
			var cell: CombatCell = CombatCell.new()
			cell.grid_position = coord
			cell.world_position = grid_to_world(coord)
			cell.height_level = default_height_level
			cell.walkable = true
			cell.cover_level = CombatCell.CoverLevel.NONE
			cell.obstruction = false
			cells[coord] = cell

func get_cell(coord: Vector2i) -> CombatCell:
	if cells.has(coord):
		return cells[coord]
	return null

func grid_to_world(coord: Vector2i, height_level: int = -1) -> Vector3:
	var y = origin.y
	if height_level >= 0:
		y += float(height_level) * cell_width
	return origin + Vector3(coord.x * cell_width, y, coord.y * cell_depth)

func world_to_grid(world_position: Vector3) -> Vector2i:
	var local = world_position - origin
	var x = int(floor(local.x / cell_width))
	var y = int(floor(local.z / cell_depth))
	return Vector2i(x, y)

func get_neighbors(cell: CombatCell, include_diagonals: bool = false) -> Array[CombatCell]:
	var neighbors: Array[CombatCell] = []
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	if include_diagonals:
		offsets += [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
	for offset in offsets:
		var candidate = get_cell(cell.grid_position + offset)
		if candidate != null:
			neighbors.append(candidate)
	return neighbors

func is_line_of_sight_clear(from_cell: CombatCell, to_cell: CombatCell) -> bool:
	if from_cell == null or to_cell == null:
		return false
	var start = from_cell.world_position + Vector3(0, 1.25, 0)
	var end = to_cell.world_position + Vector3(0, 1.25, 0)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = start
	query.to = end
	query.exclude = [self]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result = space_state.intersect_ray(query)
	return result.size() == 0

func is_grid_line_of_sight_clear(from_cell: CombatCell, to_cell: CombatCell, full_cover_blocks: bool = true) -> bool:
	if from_cell == null or to_cell == null:
		return false
	for cell in get_cells_between(from_cell.grid_position, to_cell.grid_position):
		if cell.obstruction or cell.blocks_line_of_sight:
			return false
		if full_cover_blocks and cell.cover_level == CombatCell.CoverLevel.FULL:
			return false
	return true


func get_cells_between(from_coord: Vector2i, to_coord: Vector2i) -> Array[CombatCell]:
	var between: Array[CombatCell] = []
	var delta: Vector2i = to_coord - from_coord
	var steps: int = max(abs(delta.x), abs(delta.y))
	if steps <= 1:
		return between

	for index in range(1, steps):
		var t := float(index) / float(steps)
		var coord := Vector2i(
			int(round(lerp(float(from_coord.x), float(to_coord.x), t))),
			int(round(lerp(float(from_coord.y), float(to_coord.y), t)))
		)
		var cell := get_cell(coord)
		if cell != null and not between.has(cell):
			between.append(cell)
	return between


func get_cover_modifier_for_cell(cell: CombatCell) -> int:
	if cell == null:
		return 0
	return cell.get_cover_bonus()


func get_directional_cover_modifier(from_cell: CombatCell, to_cell: CombatCell) -> int:
	if from_cell == null or to_cell == null:
		return 0

	var strongest_cover: int = 0
	for cell in get_cells_between(from_cell.grid_position, to_cell.grid_position):
		strongest_cover = max(strongest_cover, cell.get_cover_bonus())
		if cell.blocks_ranged_line_of_sight():
			return 999

	return max(strongest_cover, to_cell.get_cover_bonus())

func get_height_modifier(from_cell: CombatCell, to_cell: CombatCell) -> int:
	if from_cell == null or to_cell == null:
		return 0
	var delta = from_cell.get_effective_height_level() - to_cell.get_effective_height_level()
	return clamp(delta * 4, -12, 16)

func get_ranged_height_modifier(from_cell: CombatCell, to_cell: CombatCell) -> int:
	if from_cell == null or to_cell == null:
		return 0
	var delta = from_cell.get_effective_height_level() - to_cell.get_effective_height_level()
	return clamp(delta * 5, -15, 20)


func get_range_bonus_from_height(from_cell: CombatCell, to_cell: CombatCell) -> int:
	if from_cell == null or to_cell == null:
		return 0
	return max(0, from_cell.get_effective_height_level() - to_cell.get_effective_height_level())


func get_attack_arc(attacker: CombatActor, target: CombatActor) -> int:
	if attacker == null or target == null:
		return TacticalFacing.AttackArc.FRONT
	var attack_delta := attacker.get_grid_position() - target.get_grid_position()
	return TacticalFacing.classify_attack_arc(target.get_tactical_facing(), attack_delta)


func get_flank_bonus(attacker: Node, target: Node) -> int:
	if not (attacker is CombatActor and target is CombatActor):
		return 0
	var arc := get_attack_arc(attacker as CombatActor, target as CombatActor)
	match arc:
		TacticalFacing.AttackArc.BACK:
			return 20
		TacticalFacing.AttackArc.RIGHT_FLANK, TacticalFacing.AttackArc.LEFT_FLANK:
			return 10
		_:
			return 0


func get_pincer_bonus(attacker: CombatActor, target: CombatActor, allied_actors: Array[CombatActor]) -> int:
	if attacker == null or target == null:
		return 0
	var attacker_arc := get_attack_arc(attacker, target)
	var opposite_arc := TacticalFacing.opposite_arc(attacker_arc)

	for ally in allied_actors:
		if ally == null or ally == attacker or not ally.is_alive() or ally.current_cell == null:
			continue
		if ally.faction != attacker.faction:
			continue
		if get_attack_arc(ally, target) != opposite_arc:
			continue
		if not _is_adjacent_cardinal_or_diagonal(ally.current_cell, target.current_cell):
			continue
		return 10
	return 0

func get_obstruction_cells() -> Array:
	var obstruction_cells: Array = []
	for cell in cells.values():
		if cell.obstruction or cell.blocks_line_of_sight or cell.cover_level != CombatCell.CoverLevel.NONE:
			obstruction_cells.append(cell)
	return obstruction_cells

func mark_cover(cell: CombatCell, cover_level: int) -> void:
	if cell == null:
		return
	cell.cover_level = cover_level

func mark_obstruction(cell: CombatCell, is_blocking: bool = true) -> void:
	if cell == null:
		return
	cell.obstruction = is_blocking
	cell.walkable = not is_blocking
	cell.blocks_line_of_sight = is_blocking


func apply_terrain_to_cell(cell: CombatCell, terrain: Node) -> void:
	if cell == null or terrain == null:
		return
	cell.walkable = not bool(terrain.get("block_movement"))
	cell.cover_level = int(terrain.get("cover_level"))
	cell.obstruction = bool(terrain.get("is_obstruction"))
	cell.blocks_line_of_sight = bool(terrain.get("blocks_line_of_sight"))
	cell.movement_cost = int(terrain.get("movement_cost"))
	cell.terrain_height_delta = int(terrain.get("height_level"))
	cell.terrain_tags = terrain.get("terrain_tags")
	if terrain.get("terrain_id") != "":
		cell.temporary_effect_ids.append(str(terrain.get("terrain_id")))


func clear_terrain_from_cell(cell: CombatCell) -> void:
	if cell == null:
		return
	cell.walkable = true
	cell.cover_level = CombatCell.CoverLevel.NONE
	cell.obstruction = false
	cell.blocks_line_of_sight = false
	cell.movement_cost = 1
	cell.terrain_height_delta = 0
	cell.terrain_tags.clear()
	cell.temporary_effect_ids.clear()


func _axis_direction(delta: Vector2i) -> Vector2i:
	if delta == Vector2i.ZERO:
		return Vector2i.ZERO
	if abs(delta.x) > abs(delta.y):
		return Vector2i(int(sign(delta.x)), 0)
	if abs(delta.y) > abs(delta.x):
		return Vector2i(0, int(sign(delta.y)))
	if delta.y != 0:
		return Vector2i(0, int(sign(delta.y)))
	return Vector2i(int(sign(delta.x)), 0)


func _is_adjacent_cardinal_or_diagonal(a: CombatCell, b: CombatCell) -> bool:
	if a == null or b == null:
		return false
	var delta: Vector2i = a.grid_position - b.grid_position
	return max(abs(delta.x), abs(delta.y)) == 1
