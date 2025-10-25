extends Control

signal mood_submitted(mood_value: int)
signal mood_submit_cancel(mood_cancelled: bool)

@onready var mood_slider = $"PanelContainer/VBoxContainer/HSlider"
@onready var mood_value = $"PanelContainer/VBoxContainer/assessment_scale"
@onready var animation = $"AnimationPlayer"

@onready var close_btn = $"PanelContainer/VBoxContainer/HBoxContainer/cancel_btn"
@onready var submit_btn = $"PanelContainer/VBoxContainer/HBoxContainer/submit_btn"

# Define mood descriptions by value
var mood_labels = {
	0: "😞",
	1: "🙁",
	2: "😐",
	3: "🙂",
	4: "😄"
}

func _ready() -> void:
	animation.play("pop")

	mood_slider.min_value = 0
	mood_slider.max_value = 4
	mood_slider.step = 1

	mood_value.pivot_offset = mood_value.size / 2
	mood_value.resized.connect(func():
		mood_value.pivot_offset = mood_value.size / 2
	)

	mood_slider.value_changed.connect(_on_mood_slider_changed)
	submit_btn.pressed.connect(_on_submit_pressed)
	close_btn.pressed.connect(_close_pressed)

	_update_mood_label(int(mood_slider.value))


func _close_pressed() -> void:
	
	emit_signal("mood_submit_cancel", true)
	
	var tween = create_tween()
	tween.tween_property(close_btn, "scale", Vector2(0.8, 0.8), 0.08)
	tween.tween_property(close_btn, "scale", Vector2(1.0, 1.0), 0.1)
	tween.finished.connect(func(): queue_free()) # only closes via cancel


func _on_mood_slider_changed(value: float) -> void:
	var click_sound: AudioStream = preload("res://Audio/rne Perc.wav")
	Global.play_sound(click_sound, -20)
	_update_mood_label(int(value))
	_animate_label()


func _update_mood_label(value: int) -> void:
	if value in mood_labels:
		mood_value.text = mood_labels[value]
	else:
		mood_value.text = "Unknown 🤔"

func _animate_label() -> void:
	var tween = create_tween()
	tween.tween_property(mood_value, "scale", Vector2(1.2, 1.2), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mood_value, "scale", Vector2(1.0, 1.0), 0.12) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func _on_submit_pressed() -> void:
	var mood_value_int = int(mood_slider.value)
	emit_signal("mood_submitted", mood_value_int)

	queue_free()  # Now it closes only after submit
