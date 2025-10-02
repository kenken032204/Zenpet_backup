extends Area2D

var dragging := false
@onready var paint_layer = get_node("/root/Petmain/Bath/Node2D")
var start_position := Vector2.ZERO
var is_bathing = false
var bubble_cooldown := 0.0
var reward_given := false   # ✅ reward only once per bath
var can_pick_up := true     # ✅ cooldown for soap pickup

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
	
	if is_bathing:
		if Global.cleanliness <= 100:
			Global.cleanliness = clamp(Global.cleanliness + 20 * delta, 0, 100)  
			Global.is_dirty = Global.cleanliness < 30  

			# ✅ Reward once per bath when pet reaches full cleanliness
			if Global.cleanliness >= 99.9 and !reward_given:
				reward_given = true
				is_bathing = false
				get_tree().call_group("petmain", "on_bath_completed")
		else:
			# Too clean → stop bathing
			is_bathing = false

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
			await get_tree().create_timer(2.5).timeout
			can_pick_up = true

			# ✅ Reset reward so next bath can give EXP again
			reward_given = false
