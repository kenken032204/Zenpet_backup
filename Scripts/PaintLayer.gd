extends Node2D

var paint_points: Array = []

func add_point(global_pos: Vector2):
	var local_pos = to_local(global_pos)
	paint_points.append({
		"pos": local_pos,
		"alpha": 0.6,
		"radius": randf_range(6.0, 14.0),
		"velocity": Vector2(randf_range(-10, 10), randf_range(-30, -50))  # upward drift
	})
	queue_redraw()

func _draw():
	for point_data in paint_points:
		var pos = point_data["pos"]
		var alpha = point_data["alpha"]
		var radius = point_data["radius"]

		# Bubble glow
		draw_circle(pos, radius + 3, Color(0.8, 0.9, 1.0, alpha * 0.3))
		# Core
		draw_circle(pos, radius, Color(0.8, 0.9, 1.0, alpha))

func _process(delta):
	var fade_speed = 0.3
	for i in range(paint_points.size() - 1, -1, -1):
		var point = paint_points[i]
		point["alpha"] -= delta * fade_speed
		point["pos"] += point["velocity"] * delta  # move the bubble upward
		if point["alpha"] <= 0:
			paint_points.remove_at(i)
	queue_redraw()
