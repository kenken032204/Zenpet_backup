extends Area2D

var food_count := 5
var dragging := false
var is_feeding := false

@onready var start_position := global_position
@onready var food_left := $"food_value"

func _ready():
	food_left.text = str(food_count)
	start_position = global_position

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position()

		var near_pet := false
		for area in get_overlapping_areas():
			if area.is_in_group("pet"):
				near_pet = true
				if not is_feeding:
					is_feeding = true
					print("[DEBUG] 🐾 Food is near the pet — ready to feed.")
		if not near_pet:
			is_feeding = false

func _on_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if food_count <= 0:
				print("[DEBUG] ❌ No food left, removing.")
				queue_free()
				return
			dragging = true
			print("[DEBUG] 🍎 Started dragging food.")
		else:
			dragging = false
			print("[DEBUG] 🍽️ Released food.")

			var fed := false
			for area in get_overlapping_areas():
				if area.is_in_group("pet"):
					fed = true
					print("[DEBUG] 🐶 Food released near pet — feeding directly.")
					break

			if fed:
				# 🧮 Decrease food count and update label
				food_count -= 1
				food_left.text = str(food_count)
				Global.play_sound(load("res://Audio/crisps-mp3.mp3"), -5)
				print("[DEBUG] ✅ Pet fed successfully! Food left:", food_count)

				# 🍽️ Tween back to original position
				var tween = create_tween()
				tween.tween_property(self, "global_position", start_position, 0.4)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_OUT)

				# 🧼 Remove food node if none left
				if food_count <= 0:
					print("[DEBUG] 🗑️ All food used up — removing node.")
					await get_tree().create_timer(0.5).timeout
					queue_free()
			else:
				# 🌀 Return to original position
				print("[DEBUG] ⬅️ No pet nearby — returning food to start position.")
				var tween = create_tween()
				tween.tween_property(self, "global_position", start_position, 0.5)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_OUT)
