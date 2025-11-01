extends Control

@onready var animation = $AnimationPlayer

func _ready() -> void:
	animation.play("sunrays")
