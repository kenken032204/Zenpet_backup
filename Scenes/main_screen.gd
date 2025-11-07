extends Control

@onready var login_btn = $HBoxContainer/login_btn
@onready var register_btn = $HBoxContainer/register_btn
@onready var loading_menu_control = $loading_menu_screen
@onready var progress_bar = $loading_menu_screen/HBoxContainer/ProgressBar
@onready var animation = $loading_menu_screen/CenterContainer/AnimationPlayer
@onready var audio = $AudioStreamPlayer2D
func _ready():
	randomize()

	print("✅ UI nodes loaded:", login_btn, register_btn, loading_menu_control, progress_bar, animation)
	audio.play()
	Global.check_server_connection()
	
	# Hide main menu buttons initially
	login_btn.visible = false
	register_btn.visible = false

	# Wait a frame to ensure get_tree() and nodes are fully ready
	await get_tree().process_frame

	# Start simulated loading sequence
	await _start_loading_sequence()


func _start_loading_sequence():
	progress_bar.value = 0
	await _simulate_progress()


func _simulate_progress():
	# Ensure tree is ready before creating timers
	while get_tree() == null:
		await Engine.get_main_loop().process_frame

	while progress_bar.value < 100:
		var increment = randf_range(3, 12)
		progress_bar.value = clamp(progress_bar.value + increment, 0, 100)

		# Random delay — sometimes it “holds”
		var delay = randf_range(0.05, 0.5)
		if randi() % 5 == 0:
			delay = randf_range(0.8, 2.0)

		await get_tree().create_timer(delay).timeout

	# Small pause after reaching 100%
	await get_tree().create_timer(0.8).timeout
	_fade_out_loading()


func _fade_out_loading():
	var tween = create_tween()
	tween.tween_property(loading_menu_control, "modulate:a", 0.0, 1.5)
	tween.connect("finished", Callable(self, "_on_loading_complete"))


func _on_loading_complete():
	# Hide loading menu, show buttons
	loading_menu_control.visible = false
	login_btn.visible = true
	register_btn.visible = true

	get_tree().change_scene_to_file("res://Scenes/login.tscn")

func _enable_buttons():
	Global.add_button_effects(login_btn)
	Global.add_button_effects(register_btn)
	login_btn.pressed.connect(_on_login_pressed)
	register_btn.pressed.connect(_on_register_pressed)

func _on_login_pressed():
	get_tree().change_scene_to_file("res://Scenes/login.tscn")

func _on_register_pressed():
	get_tree().change_scene_to_file("res://Scenes/registration.tscn")
