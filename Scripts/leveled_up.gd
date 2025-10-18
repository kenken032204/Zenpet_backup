extends Control

@onready var label = $"Panel/level"
@onready var confirm = $"Panel/confirm_btn"
@onready var animation = $AnimationPlayer

var pet_data_path := "user://pet_data.json"

func _ready():
	animation.play("leveled_up")
	Global.play_sound(preload("res://Audio/999-level-up.mp3"))
	visible = true
	confirm.pressed.connect(hide_popup)
	load_pet_data()

func load_pet_data():
	if FileAccess.file_exists(pet_data_path):
		var file = FileAccess.open(pet_data_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(data) == TYPE_DICTIONARY:
			label.text = str(int(data.get("level", 1)))
	else:
		label.text = "1"

func show_level_up(new_level: int):
	label.text = str(new_level)
	save_level(new_level)
	visible = true


func save_level(level_val: int):
	var data = {
		"level": level_val,
		"exp": 0
	}
	var file = FileAccess.open(pet_data_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func hide_popup():
	visible = false
