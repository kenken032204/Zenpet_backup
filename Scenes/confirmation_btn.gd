extends Panel

signal confirmed
signal canceled

@onready var confirm_btn = $"journal-settings/confirm-btn"
@onready var cancel_btn = $"journal-settings/cancel-btn"
@onready var animation = $AnimationPlayer

func _ready() -> void:
	Global.play_sound(load("res://Audio/apple-pay-sound.mp3"))
	animation.play("shake")
	confirm_btn.pressed.connect(_on_confirm_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

func _on_confirm_pressed():
	emit_signal("confirmed")
	queue_free()

func _on_cancel_pressed():
	emit_signal("canceled")
	queue_free()
