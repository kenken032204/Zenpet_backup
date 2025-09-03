extends Area2D

var dragging := false
@onready var paint_layer = get_node("/root/Petmain/Bath/Node2D")  # Adjust path if needed
var start_position := Vector2.ZERO

var is_bathing = false

func _ready():
	start_position = global_position

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position()

		for area in get_overlapping_areas():
			if area.name == "PetArea":  # Or better: use `is_in_group("pet")`
				paint_layer.add_point(global_position)
				Global.play_sound(load("res://Audio/bubble_iMw0wu6.mp3"), -20.0)
				is_bathing = true
			
	if is_bathing:
		# Restore cleanliness
		Global.cleanliness = clamp(Global.cleanliness + 1, 0, 100)  
		Global.is_dirty = Global.cleanliness < 30  # update flag

func _on_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
		else:
			is_bathing = false
			dragging = false
			# Tween back to original position
			var tween = create_tween()
			tween.tween_property(self, "global_position", start_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
