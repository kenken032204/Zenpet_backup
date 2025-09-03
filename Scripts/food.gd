extends Area2D

var dragging := false
@onready var start_position := global_position
var is_feeding = false

func _ready():
	start_position = global_position

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position()

		for area in get_overlapping_areas():
			if area.name == "PetArea":
				if not is_feeding:
					Global.play_sound(load("res://Audio/cartoon-gulp-swallow-sound.mp3"), 0.0)
				is_feeding = true

func _on_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
		else:
			is_feeding = false
			dragging = false
			var tween = create_tween()
			tween.tween_property(self, "global_position", start_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
