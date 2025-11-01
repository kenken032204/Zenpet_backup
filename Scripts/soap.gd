extends Area2D

var dragging := false
@onready var paint_layer = get_node("/root/Petmain/Bath/Node2D")
var start_position := Vector2.ZERO
var is_bathing = false
var bubble_cooldown := 0.0
var can_pick_up := true  # cooldown for soap pickup

func _ready():
	start_position = global_position

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position()

		for area in get_overlapping_areas():
			if area.is_in_group("pet"):
				# Add scrub mark if moved enough
				if paint_layer.get_point_count() == 0 or \
				global_position.distance_to(paint_layer.get_point_position(paint_layer.get_point_count() - 1)) > 10:
					paint_layer.add_point(global_position)

				# Play bubble sound with cooldown
				bubble_cooldown -= delta
				if bubble_cooldown <= 0:
					Global.play_sound(load("res://Audio/bubble_iMw0wu6.mp3"), -20.0)
					bubble_cooldown = 1

				is_bathing = true

func _on_input_event(viewport, event, _shape_idx):
	if !can_pick_up:
		return  # 🚫 Ignore clicks if soap is cooling down

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and !dragging:
			dragging = true
		elif dragging and !event.pressed:
			is_bathing = false
			dragging = false

			# Tween back to original position
			var tween = create_tween()
			tween.tween_property(self, "global_position", start_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			# 🚫 Disable pickup until cooldown ends
			can_pick_up = false
			await get_tree().create_timer(1).timeout
			can_pick_up = true
