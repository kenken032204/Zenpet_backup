extends Control

@onready var back = $"back_button"
@onready var logout_btn = $"CanvasLayer/logout_btn" # 👈 make sure this matches your actual button node name
@onready var toast = $"toast_notification" # optional if you already have a toast system

func _ready():
	back.pressed.connect(back_to_home)
	logout_btn.pressed.connect(_on_logout_pressed)

func back_to_home():
	get_tree().change_scene_to_file("res://Scenes/dashboard.tscn")

func _on_logout_pressed():
	var path = "user://auth.json"
	if FileAccess.file_exists(path):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("auth.json") 

	get_tree().change_scene_to_file("res://Scenes/login.tscn")
