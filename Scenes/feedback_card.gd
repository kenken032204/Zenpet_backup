extends Control

@onready var cancel_btn = $"PanelContainer/HBoxContainer/cancel_btn"

func _ready() -> void:
	cancel_btn.pressed.connect(_on_cancel_pressed)
	
func _on_cancel_pressed():
	var scene = load("res://Scenes/settings.tscn")
	if scene:
		get_tree().change_scene_to_packed(scene)
	else:
		print("⚠️ Scene not found!")
