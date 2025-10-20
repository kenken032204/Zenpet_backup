extends Control

@onready var back_btn = $"back_button"
@onready var lvl_1 = $"ScrollContainer/CanvasLayer/level_1"
@onready var animation = $AnimationPlayer
@onready var exp_bar = $"Control/ProgressBar"
@onready var level_label = $"Control/level_label" 

func _ready() -> void:
	# Fade-in animation
	animation.play("fade_out")
	
	# Connect buttons
	back_btn.pressed.connect(_back_to_dashboard)
	lvl_1.pressed.connect(_on_level_1_pressed)
	
	# Attach EXP bar & optional level label to LevelManager
	LevelManager.attach_ui(exp_bar, level_label)
	
	# Load user level & EXP from backend
	var user_id = int(Global.User.get("id", 0))
	if user_id > 0:
		LevelManager.get_user_level(user_id)
	else:
		push_warning("⚠️ Invalid user ID in Global.User")

func _back_to_dashboard() -> void:
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)

func _on_level_1_pressed() -> void:
	
	animation.play("level_pressed")
	await animation.animation_finished
	
	var scene = load("res://Scenes/zenbody_level_1.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
