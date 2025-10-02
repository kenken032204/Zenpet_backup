extends Control

@onready var back_btn = $"back_button"
@onready var start_btn = $"start_btn"
@onready var timer_label = $"Control/TimerLabel"
@onready var yogadescription = $"Control/YogaDescription"
@onready var progress_bar: ProgressBar = $"Control/ProgressBar"

@onready var animation = $AnimationPlayer

var messages: Array[String] = ["Ready...", "Set...", "Go!"]

var exp_gain: int = 10   # reward for completing this yoga session
var total_exp: int = 0   # track accumulated exp

func _ready() -> void:
	animation.play("fade_out")
	back_btn.pressed.connect(_back_to_zenbody)
	start_btn.pressed.connect(_start_level)
	
func _back_to_zenbody():
	var scene = load("res://Scenes/zenbody.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)

func _start_level() -> void:
	progress_bar.value = 0
	await show_messages(messages)  
	_increase_progress()        
	
func _increase_progress() -> void:
	var duration := 10.0 
	var steps := 100       
	var step_time := duration / float(steps)
	var increment: float = (progress_bar.max_value - progress_bar.min_value) / float(steps)

	for i in range(steps):
		progress_bar.value += increment
		
		# Show remaining time (countdown)
		var time_left := duration - (i * step_time)
		timer_label.text = str(round(time_left))  # round to whole seconds

		await get_tree().create_timer(step_time).timeout

	# Make sure final value is exact
	progress_bar.value = progress_bar.max_value
	start_btn.disabled = true
	timer_label.text = "0"
	
	# ✅ Increase EXP when progress finishes
	Global.total_exp += exp_gain
	print("EXP gained:", exp_gain, " | Total EXP:", Global.total_exp)
		
	# Switch to loading screen and tell it where to go
	var level_complete = load("res://Scenes/level_complete.tscn").instantiate()
	level_complete.next_scene_path = "res://Scenes/zenbody.tscn"
	level_complete.wait_time = 2.0   # you can tweak per case
			
	get_tree().root.add_child(level_complete)
	get_tree().current_scene.queue_free()  # remove old scene

func show_messages(msgs: Array[String]) -> void:
	await _run_messages(msgs)

func _run_messages(msgs: Array[String]) -> void:
	for text in msgs:
		yogadescription.text = text
		yogadescription.modulate.a = 0.0  # start invisible

		# Fade in
		var tween = create_tween()
		tween.tween_property(yogadescription, "modulate:a", 1.0, 0.5)
		await tween.finished

		# Hold for 1s
		await get_tree().create_timer(1.0).timeout

		# Fade out
		var tween2 = create_tween()
		tween2.tween_property(yogadescription, "modulate:a", 0.0, 0.5)
		await tween2.finished
