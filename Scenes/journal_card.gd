extends Control

signal view_pressed(journal_id: String)
signal delete_requested(journal_id: String)

var journal_id: String
var journal_data: Dictionary

@onready var title_label = $"journal-id/journal-title"
@onready var date_label = $"journal-id/journal-date"
@onready var text_label = $"journal-id/journal-text"
@onready var view_btn = $"journal-id/journal-settings/view_btn"
@onready var delete_btn = $"journal-id/journal-settings/delete-btn"
@onready var card_button = $"journal-id"
@onready var animation = $AnimationPlayer

const API_URL = "http://localhost/your_api"

func _ready() -> void:
	
	card_button.disabled = true

	# Connect only the view and delete buttons
	if view_btn:
		view_btn.pressed.connect(func(): emit_signal("view_pressed", journal_id))
	
	if delete_btn:
		delete_btn.pressed.connect(_on_delete_pressed)

func set_journal_data(data: Dictionary, is_new: bool = false) -> void:
	await ready
	
	journal_data = data
	journal_id = str(journal_data.get("id", "0"))
	
	# Set text labels
	title_label.text = str(journal_data.get("title", "Untitled"))
	date_label.text = str(journal_data.get("date", journal_data.get("date_created", "")))
	text_label.text = str(journal_data.get("text", journal_data.get("content", "")))
	print("🧩 journal_data:", journal_data)

	# Apply color
	var color_hex = journal_data.get("color", "#FFFFFF")
	_set_card_color(Color(color_hex))
	
	# Play animation for new journals
	if is_new and animation and animation.has_animation("new_journal"):
		animation.play("new_journal")

func _on_card_pressed() -> void:
	emit_signal("view_pressed", journal_id)

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

func _set_card_color(color: Color) -> void:
	card_button.flat = false
	
	# Remove existing overrides
	card_button.remove_theme_stylebox_override("normal")
	card_button.remove_theme_stylebox_override("hover")
	card_button.remove_theme_stylebox_override("pressed")
	card_button.remove_theme_stylebox_override("focus")
	card_button.remove_theme_stylebox_override("disabled")  # added

	# Base style
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.set_corner_radius_all(8)
	stylebox.set_content_margin_all(10)
	
	# Hover and pressed states
	var hover_box = stylebox.duplicate()
	hover_box.bg_color = color.darkened(0.1)
	var pressed_box = stylebox.duplicate()
	pressed_box.bg_color = color.darkened(0.2)

	# Disabled state: keep same color but slightly desaturated
	var disabled_box = stylebox.duplicate()
	disabled_box.bg_color = color.lerp(Color(0.8, 0.8, 0.8, 1), 0)

	# Apply overrides
	card_button.add_theme_stylebox_override("normal", stylebox)
	card_button.add_theme_stylebox_override("hover", hover_box)
	card_button.add_theme_stylebox_override("pressed", pressed_box)
	card_button.add_theme_stylebox_override("focus", stylebox.duplicate())
	card_button.add_theme_stylebox_override("disabled", disabled_box)  # added

	card_button.queue_redraw()


func _create_hover_style(base: StyleBoxFlat, color: Color) -> StyleBoxFlat:
	var hover_box = base.duplicate()
	hover_box.bg_color = color.darkened(0.1)
	return hover_box

func _create_pressed_style(base: StyleBoxFlat, color: Color) -> StyleBoxFlat:
	var pressed_box = base.duplicate()
	pressed_box.bg_color = color.darkened(0.2)
	return pressed_box
