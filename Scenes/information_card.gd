extends Control

@onready var animation = $AnimationPlayer
@onready var confirm_btn = $Panel/HBoxContainer/confirm_btn
@onready var title = $Panel/info_title
@onready var content = $Panel/info_contents

func _ready() -> void:
	animation.play("pop")
