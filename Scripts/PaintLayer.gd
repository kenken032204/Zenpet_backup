extends Node2D

var paint_points: Array = []
var max_bubbles := 50
var fade_delay := 10.0  # seconds before fading starts
var fade_speed := 0.3

func add_point(global_pos: Vector2):
	var local_pos = to_local(global_pos)
	if paint_points.size() >= max_bubbles:
		paint_points.pop_front()  # remove oldest bubble to keep limit

	paint_points.append({
		"pos": local_pos,
		"alpha": 0.6,
		"radius": randf_range(6.0, 14.0),
		"velocity": Vector2(randf_range(-10, 10), randf_range(-30, -50)),
		"lifetime": 0.0  # time since creation
	})
	queue_redraw()

func get_point_count() -> int:
	return paint_points.size()

func get_point_position(index: int) -> Vector2:
	if index >= 0 and index < paint_points.size():
		return paint_points[index]["pos"]
	return Vector2.ZERO

func _draw():
	for point_data in paint_points:
		var pos = point_data["pos"]
		var alpha = point_data["alpha"]
		var radius = point_data["radius"]

		var color = Color(0.8, 0.9, 1.0, alpha)
		draw_circle(pos, radius + 3, Color(0.8, 0.9, 1.0, alpha * 0.3))
		draw_circle(pos, radius, color)


func _process(delta):
	for i in range(paint_points.size() - 1, -1, -1):
		var point = paint_points[i]
		point["lifetime"] += delta

		if point["lifetime"] > fade_delay:
			point["alpha"] -= delta * fade_speed
			point["pos"] += point["velocity"] * delta  # move upward

		if point["alpha"] <= 0:
			paint_points.remove_at(i)

	queue_redraw()
