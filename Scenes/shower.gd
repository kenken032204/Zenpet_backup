extends Area2D

var dragging := false
@onready var paint_layer = get_node("/root/Petmain/Bath/Node2D")
@onready var water_particles = $"CPUParticles2D"
@onready var water_effects = $"shower_sound_fx"
var start_position := Vector2.ZERO
var is_rinsing = false
var rinse_sound_cooldown := 0.0
var can_pick_up := true
var reward_given := false
var debug_radius := 60.0  # visible range for bubble removal

func _ready():
	water_particles.emitting = false
	start_position = global_position

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position()

		for area in get_overlapping_areas():
			if area.is_in_group("pet"):
				is_rinsing = true

				# Play water sound occasionally
				rinse_sound_cooldown -= delta
				if rinse_sound_cooldown <= 0:
					rinse_sound_cooldown = 1.0

				# 💧 Try to erase bubbles
				_erase_bubbles_under_shower()

	if is_rinsing:
		Global.cleanliness = clamp(Global.cleanliness + 15 * delta, 0, 100)
		Global.is_dirty = Global.cleanliness < 30

		if Global.cleanliness >= 99.9 and !reward_given:
			reward_given = true
			is_rinsing = false
			get_tree().call_group("petmain", "on_bath_completed")

	queue_redraw()  # Draw debug visuals

func _erase_bubbles_under_shower():
	if paint_layer.paint_points.size() == 0:
		return

	for i in range(paint_layer.paint_points.size() - 1, -1, -1):
		var point = paint_layer.paint_points[i]
		var global_bubble_pos = paint_layer.to_global(point["pos"])
		var distance = global_position.distance_to(global_bubble_pos)

		# Debug: Mark bubble red if inside range
		if distance < debug_radius:
			point["debug_hit"] = true
			point["alpha"] -= 0.1
			if point["alpha"] <= 0.05:
				paint_layer.paint_points.remove_at(i)
		else:
			point["debug_hit"] = false

	paint_layer.queue_redraw()

func _on_input_event(viewport, event, _shape_idx):
	if !can_pick_up:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and !dragging:
			dragging = true
			water_particles.emitting = true
			water_effects.play()
		elif dragging and !event.pressed:
			is_rinsing = false
			dragging = false
			water_particles.emitting = false
			water_effects.stop()

			var tween = create_tween()
			tween.tween_property(self, "global_position", start_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			can_pick_up = false
			await get_tree().create_timer(0).timeout
			can_pick_up = true
			reward_given = false
