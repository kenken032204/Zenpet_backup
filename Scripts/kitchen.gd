extends Control

@onready var back = $back_button

func _ready():
	if PetStore.pet_node:
		add_child(PetStore.pet_node)
	
	back.pressed.connect(back_pressed)

func back_pressed():
	get_tree().change_scene_to_file("res://Scenes/petmain.tscn")
	
