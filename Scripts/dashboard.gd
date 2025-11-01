extends Control

@onready var zenpet_btn: Button = $Panel/VBoxContainer/Zenpet_btn
@onready var zenbody_btn: Button = $Panel/VBoxContainer/Zenbody_btn
@onready var zendiary_btn: Button = $Panel/VBoxContainer/Zendiary_btn
@onready var zenai_btn: Button = $Panel/VBoxContainer/Zenai_btn
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var label: Label = $Label

var hover_tweens: Dictionary = {}

func _ready() -> void:
	animation.play("fade_out")
	audio.stream.loop = true
	audio.play()
	audio.finished.connect(_on_audio_finished)
	
	Global.add_button_effects(zenpet_btn)
	Global.add_button_effects(zenbody_btn)
	Global.add_button_effects(zendiary_btn)
	Global.add_button_effects(zenai_btn)
	
	# Connect button actions
	zenpet_btn.pressed.connect(_on_zenpet_pressed)
	zenbody_btn.pressed.connect(_on_zenbody_pressed)
	zendiary_btn.pressed.connect(_on_zendiary_pressed)
	zenai_btn.pressed.connect(_on_zenai_pressed)

func _on_audio_finished() -> void:
	audio.play()

# 🔹 Button actions
func _on_zenpet_pressed() -> void:
	go_to_scene_with_loading("res://Scenes/petmain.tscn")

func _on_zenbody_pressed() -> void:
	go_to_scene_with_loading("res://Scenes/zenbody.tscn")

func _on_zendiary_pressed() -> void:
	go_to_scene_with_loading("res://Scenes/zendiary.tscn")

func _on_zenai_pressed() -> void:
	go_to_scene_with_loading("res://Scenes/zenai.tscn")

# 🔹 Safe loading-screen transition
func go_to_scene_with_loading(target_scene_path: String, wait_time: float = 2.5) -> void:
	var packed_scene: PackedScene = load("res://Scenes/loading_screen.tscn") as PackedScene
	if packed_scene == null:
		push_error("❌ Failed to load loading_screen.tscn")
		return

	var loading_scene: Node = packed_scene.instantiate()
	
	# Safely assign if variables exist
	if "next_scene_path" in loading_scene:
		loading_scene.next_scene_path = target_scene_path
	if "wait_time" in loading_scene:
		loading_scene.wait_time = wait_time

	get_tree().root.add_child(loading_scene)

	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
