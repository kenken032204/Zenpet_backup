extends Control

@onready var rock_scene = preload("res://Scenes/rock.tscn")
@onready var spawn_timer = $Timer
@onready var spawn_point = Vector2(640, 150)  # adjust for center
@onready var ground_y = 550  # your ground position
var score = 0
var game_over = false

func _ready():
	spawn_timer.wait_time = 1.5
	spawn_timer.start()
	spawn_timer.timeout.connect(_on_spawn_rock)

func _on_spawn_rock():
	if game_over:
		return
	var rock = rock_scene.instantiate()

	# Connect the signal before adding to scene tree
	rock.connect("rock_landed", Callable(self, "_on_rock_landed"))

	add_child(rock)
	rock.position = spawn_point

func _on_rock_landed():
	if game_over:
		return

	score += 1
	print("Score: ", score)

	if score >= 10:
		_victory()
	else:
		spawn_timer.start()


func _victory():
	game_over = true
	spawn_timer.stop()
	print("Balance complete! 🪷")
