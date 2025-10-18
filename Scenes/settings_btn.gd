extends Button

func _ready() -> void:
	self.pressed.connect(_open_settings)

func _open_settings() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")
