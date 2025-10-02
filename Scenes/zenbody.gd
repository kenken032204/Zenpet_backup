extends Control

@onready var back_btn = $"back_button"
@onready var lvl_1 = $"ScrollContainer/CanvasLayer/level_1"
@onready var animation = $AnimationPlayer

@onready var exp_bar = $"Control/ProgressBar"

func update_exp_bar():
	var tween = create_tween()
	tween.tween_property(exp_bar, "value", Global.total_exp, 0.5)

func _ready() -> void:
	update_exp_bar()
	animation.play("fade_out")
	
	back_btn.pressed.connect(_back_to_dashboard)
	lvl_1.pressed.connect(go_to_level1)
	
func _back_to_dashboard():
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)

func go_to_level1():
	animation.play("level_pressed")
	await animation.animation_finished
	var scene = load("res://Scenes/zenbody_level_1.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
