extends RigidBody2D
signal rock_landed

var landed := false
var settle_timer := 0.0

func _ready():
	await get_tree().process_frame

func _physics_process(delta):
	# Wait a bit before checking to avoid instant triggers when spawned
	if position.y > 200:  
		if linear_velocity.length() < 2 and !landed:
			settle_timer += delta
			if settle_timer > 0.5:  # must stay still for half a second
				landed = true
				print("Rock landed!")  # ✅ Debug message
				emit_signal("rock_landed")
		else:
			settle_timer = 0.0
