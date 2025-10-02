extends Control

@onready var animation = $AnimationPlayer

var next_scene_path: String = ""  # set by the caller
var wait_time: float = 2.0        # default delay

func _ready() -> void:
	animation.play("level_complete")
	_start_transition()

func _start_transition() -> void:
	await get_tree().create_timer(wait_time).timeout
	
	animation.play("fade_out")
	await animation.animation_finished 
	
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
