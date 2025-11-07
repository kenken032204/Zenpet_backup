extends Control

@onready var check_btn = $"PanelContainer/VBoxContainer/HBoxContainer/check_server_btn"
@onready var close_btn = $"PanelContainer/VBoxContainer/HBoxContainer/close_app_btn"
@onready var animation = $"AnimationPlayer"

func _ready():
	animation.play("pop")
	check_btn.pressed.connect(_on_check_pressed)
	close_btn.pressed.connect(_on_close_pressed)

func _on_check_pressed():
	print("🔄 Retrying server connection...")
	Global.check_server_connection()

func _on_close_pressed():
	print("👋 Closing application.")
	get_tree().quit()
