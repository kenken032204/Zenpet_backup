extends Control

signal view_pressed(journal_id: String)
signal delete_requested(journal_id: String)

var journal_id: String
var journal_data: Dictionary
var hover_tween: Tween

@onready var title_label = $"journal-id/journal-title"
@onready var date_label = $"journal-id/journal-date"
@onready var text_label = $"journal-id/journal-text"
@onready var view_btn = $"journal-id/journal-settings/view_btn"
@onready var delete_btn = $"journal-id/journal-settings/delete-btn"
@onready var card_button = $"journal-id"
@onready var animation = $AnimationPlayer

func _ready() -> void:
	card_button.mouse_filter = Control.MOUSE_FILTER_PASS

	# Connect hover signals (Godot 4+)
	card_button.mouse_entered.connect(_on_mouse_entered)
	card_button.mouse_exited.connect(_on_mouse_exited)

	if view_btn:
		view_btn.pressed.connect(func(): emit_signal("view_pressed", journal_id))
	if delete_btn:
		delete_btn.pressed.connect(_on_delete_pressed)

func set_journal_data(data: Dictionary, is_new: bool = false) -> void:
	await ready
	journal_data = data
	journal_id = str(journal_data.get("id", "0"))
	title_label.text = str(journal_data.get("title", "Untitled"))
	date_label.text = str(journal_data.get("date", journal_data.get("date_created", "")))
	text_label.text = str(journal_data.get("text", journal_data.get("content", "")))

	var color_hex = journal_data.get("color", "#FFFFFF")
	_set_card_color(Color(color_hex))

	if is_new and animation and animation.has_animation("new_journal"):
		animation.play("new_journal")

# 🌈 Add border & style
func _set_card_color(color: Color) -> void:
	card_button.flat = false
	card_button.remove_theme_stylebox_override("normal")
	card_button.remove_theme_stylebox_override("hover")
	card_button.remove_theme_stylebox_override("pressed")
	card_button.remove_theme_stylebox_override("focus")
	card_button.remove_theme_stylebox_override("disabled")

	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.set_corner_radius_all(8)
	stylebox.set_content_margin_all(10)
	stylebox.set_border_width_all(5)
	stylebox.border_color = Color("#573510")

	var hover_box = stylebox.duplicate()
	hover_box.bg_color = color.darkened(0.05)
	hover_box.border_color = Color("#573510")

	var pressed_box = stylebox.duplicate()
	pressed_box.bg_color = color.darkened(0.15)
	pressed_box.border_color = Color(0, 0.3, 0.8, 1)

	card_button.add_theme_stylebox_override("normal", stylebox)
	card_button.add_theme_stylebox_override("hover", hover_box)
	card_button.add_theme_stylebox_override("pressed", pressed_box)
	card_button.add_theme_stylebox_override("focus", hover_box.duplicate())

	card_button.queue_redraw()

# 🎬 Hover animation
func _on_mouse_entered() -> void:
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(card_button, "scale", Vector2(1.05, 1.05), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(card_button, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_delete_pressed() -> void:
	var confirmation = preload("res://Scenes/confirmation_btn.tscn").instantiate()
	get_tree().current_scene.add_child(confirmation)
	confirmation.confirmed.connect(_on_delete_confirmed)
	confirmation.canceled.connect(func(): print("Delete canceled"))

func _on_delete_confirmed() -> void:
	Global.play_sound(load("res://Audio/paper-ripping.mp3"))
	if animation and animation.has_animation("fade_out"):
		animation.play("fade_out")
		await animation.animation_finished
	emit_signal("delete_requested", journal_id)
