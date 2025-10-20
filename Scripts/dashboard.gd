extends Control

@onready var zenpet_btn = $Panel/VBoxContainer/Zenpet_btn
@onready var zenbody_btn = $Panel/VBoxContainer/Zenbody_btn
@onready var zendiary_btn = $Panel/VBoxContainer/Zendiary_btn
@onready var zenai_btn = $Panel/VBoxContainer/Zenai_btn
@onready var animation = $AnimationPlayer
@onready var audio = $AudioStreamPlayer2D
@onready var label = $Label

func _ready():
	animation.play("fade_out")
	audio.stream.loop = true 
	audio.play()
	audio.finished.connect(_on_audio_finished)
	
	zenpet_btn.pressed.connect(_on_zenpet_pressed)
	zenbody_btn.pressed.connect(_on_zenbody_pressed)
	zendiary_btn.pressed.connect(_on_zendiary_pressed)
	zenai_btn.pressed.connect(_on_zenai_pressed)
	
func _on_audio_finished():
	audio.play()

# 🔹 Refactored button callbacks using loading screen
func _on_zenpet_pressed():
	go_to_scene_with_loading("res://Scenes/petmain.tscn")

func _on_zenbody_pressed():
	go_to_scene_with_loading("res://Scenes/zenbody.tscn")

func _on_zendiary_pressed():
	go_to_scene_with_loading("res://Scenes/zendiary.tscn")

func _on_zenai_pressed():
	go_to_scene_with_loading("res://Scenes/zenai.tscn")

# 🔹 Reusable function to switch scenes via loading screen
func go_to_scene_with_loading(target_scene_path: String, wait_time: float = 2.5) -> void:
	var loading_scene = load("res://Scenes/loading_screen.tscn").instantiate()
	loading_scene.next_scene_path = target_scene_path
	loading_scene.wait_time = wait_time
	get_tree().root.add_child(loading_scene)
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
