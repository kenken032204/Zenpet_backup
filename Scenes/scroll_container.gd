extends ScrollContainer

var velocity: float = 0.0
var damping: float = 0.85

func _unhandled_input(event):
	if event is InputEventScreenDrag:
		scroll_vertical -= event.relative.y
		velocity = -event.relative.y

func _process(delta):
	if abs(velocity) > 0.1:
		scroll_vertical += velocity
		velocity *= damping
