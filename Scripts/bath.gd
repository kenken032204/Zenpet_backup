extends Node2D

var dragging := false
var start_position := Vector2.ZERO
var draw_outline := false

@onready var sprite := $"Pet/Area2D/ChestSprite"

func _ready():
	start_position = global_position

func _draw():
	if draw_outline:
		var rect_size = get_node("Sprite2D").get_texture().get_size()
		draw_rect(Rect2(Vector2.ZERO, rect_size), Color.RED, false, 2)

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position()
		draw_outline = true
		queue_redraw()
	else:
		draw_outline = false
		queue_redraw()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
			else:
				dragging = false
				global_position = start_position  # Return to start when released
