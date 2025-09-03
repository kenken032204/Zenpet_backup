extends Control

#back 
@onready var back = $"back_button"

func _ready():
	back.pressed.connect(back_to_home)

func back_to_home():
	get_tree().change_scene_to_file("res://Scenes/petmain.tscn")
