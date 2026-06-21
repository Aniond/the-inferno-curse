extends StaticBody2D

@export var wall_size: Vector2 = Vector2(200, 20)
@export var wall_color: Color = Color(0.24, 0.19, 0.15, 1.0)

func _ready() -> void:
	# Physics collision
	var shape = RectangleShape2D.new()
	shape.size = wall_size
	var collision = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	# Visual
	var rect = ColorRect.new()
	rect.size = wall_size
	rect.color = wall_color
	add_child(rect)

	# Light occluder -- casts shadows from 2D point lights
	var occluder = LightOccluder2D.new()
	var occluder_poly = OccluderPolygon2D.new()
	var half: Vector2 = wall_size * 0.5
	occluder_poly.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2( half.x, -half.y),
		Vector2( half.x,  half.y),
		Vector2(-half.x,  half.y),
	])
	occluder.occluder = occluder_poly
	add_child(occluder)
