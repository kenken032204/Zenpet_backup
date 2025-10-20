extends Control

@onready var back_btn = $"back_button"
@onready var start_btn = $"start_btn"
@onready var timer_label = $"Control/TimerLabel"
@onready var yogadescription = $"Control/YogaDescription"
@onready var progress_bar: ProgressBar = $"Control/ProgressBar"
@onready var animation = $AnimationPlayer

# 💫 Config
var exp_gain: int = 20
var total_duration: float = 10.0
var steps: int = 100

# 🗨️ Messages shown before the yoga starts
var messages: Array[String] = [
	"Take a deep breath...",
	"Relax your shoulders...",
	"Find your balance...",
	"Ready...",
	"Set...",
	"Go!"
]

func _ready() -> void:
	animation.play("fade_out")
	back_btn.pressed.connect(_back_to_zenbody)
	start_btn.pressed.connect(_start_level)

func _back_to_zenbody() -> void:
	var scene = load("res://Scenes/zenbody.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)

func _start_level() -> void:
	start_btn.disabled = true
	progress_bar.value = 0
	await show_messages(messages)
	await _increase_progress()

	# ✅ Grant EXP when session completes
	var user_id = Global.User.get("id", 0)
	if user_id != 0:
		await LevelManager.add_exp(exp_gain, user_id)
	
	# 🎉 Show completion screen
	_show_level_complete()

func _increase_progress() -> void:
	var step_time: float = total_duration / float(steps)
	var increment: float = (progress_bar.max_value - progress_bar.min_value) / float(steps)

	for i in range(steps):
		progress_bar.value += increment
		var time_left := total_duration - (i * step_time)
		timer_label.text = str(round(time_left))
		await get_tree().create_timer(step_time).timeout

	progress_bar.value = progress_bar.max_value
	timer_label.text = "0"

func show_messages(msgs: Array[String]) -> void:
	await _run_messages(msgs)

func _run_messages(msgs: Array[String]) -> void:
	for text in msgs:
		yogadescription.text = text
		yogadescription.modulate.a = 0.0

		var fade_in = create_tween()
		fade_in.tween_property(yogadescription, "modulate:a", 1.0, 0.5)
		await fade_in.finished

		await get_tree().create_timer(1.0).timeout

		var fade_out = create_tween()
		fade_out.tween_property(yogadescription, "modulate:a", 0.0, 0.5)
		await fade_out.finished

func _show_level_complete() -> void:
	var level_complete = load("res://Scenes/level_complete.tscn").instantiate()
	level_complete.next_scene_path = "res://Scenes/zenbody.tscn"
	level_complete.wait_time = 2.0
	get_tree().root.add_child(level_complete)
	get_tree().current_scene.queue_free()
