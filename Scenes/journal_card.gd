extends Control

signal view_pressed(journal_id)
signal delete_requested(journal_id)

var journal_id: String
var journal_data: Dictionary
var play_new_anim := false

@onready var title_label = $"journal-id/journal-title"
@onready var date_label = $"journal-id/journal-date"
@onready var text_label = $"journal-id/journal-text"
@onready var view_btn = $"journal-id/journal-settings/view_btn"
@onready var delete_btn = $"journal-id/journal-settings/delete-btn"
@onready var journal_number = $"journal-id"
@onready var animation = $AnimationPlayer

func set_journal_data(data: Dictionary, is_new: bool = false) -> void:
	await ready
	
	journal_data = data
	journal_id = str(journal_data.get("id", 0))
	
	print("📋 Journal ID:", journal_id)
	print("📦 Journal Data:", journal_data)

	title_label.text = str(journal_data.get("title", "Untitled"))
	date_label.text = str(journal_data.get("date", journal_data.get("date_created", "--/--/----")))
	text_label.text = str(journal_data.get("text", journal_data.get("content", "")))
	
	# 🎨 Apply saved color to button background
	var color_value = journal_data.get("color", "#FFFFFF")
	print("🎨 Color value from data:", color_value)
	print("🔘 Button exists:", journal_number != null)
	
	if color_value and color_value != "":
		print("✅ Applying color:", color_value)
		_set_button_color(journal_number, Color(color_value))
	else:
		print("⚠️ Using default white color")
		_set_button_color(journal_number, Color("#FFFFFF"))
	
	# 🎬 Play animation for new journals
	if is_new and animation and animation.has_animation("new_journal"):
		animation.play("new_journal")

func _ready():
	# Connect buttons
	journal_number.pressed.connect(_on_journal_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	
	if view_btn:
		view_btn.pressed.connect(func():
			emit_signal("view_pressed", journal_id)
		)

# Called when any animation finishes
func _on_animation_finished_once(anim_name: String) -> void:
	if anim_name == "new_journal":
		var callable = Callable(self, "_on_animation_finished_once")
		if animation.is_connected("animation_finished", callable):
			animation.disconnect("animation_finished", callable)

func _on_delete_canceled():
	print("Delete canceled")

func _on_journal_pressed():
	print("Pressed journal:", journal_id)
	# 🔍 Emit view signal when card is pressed
	emit_signal("view_pressed", journal_id)

func _on_delete_pressed():
	var confirmation = preload("res://Scenes/confirmation_btn.tscn").instantiate()
	get_tree().current_scene.add_child(confirmation)

	# Connect directly to your function
	confirmation.connect("confirmed", Callable(self, "_on_delete_confirmed"))
	confirmation.connect("canceled", func():
		print("Delete canceled")
	)

func _on_delete_confirmed():
	Global.play_sound(load("res://Audio/paper-ripping.mp3"))
	
	# Play the fade out animation first
	animation.play("fade_out")
	
	# Wait until the animation finishes
	await animation.animation_finished
	
	# Emit the signal to the main scene to delete the journal
	emit_signal("delete_requested", journal_id)

# 🎨 Helper function to set button background color
func _set_button_color(button: Button, color: Color) -> void:
	print("🖌️ _set_button_color called")
	print("   Button:", button)
	print("   Color:", color)
	
	if not button:
		print("❌ Button is null!")
		return
	
	# Make button non-flat so background shows
	button.flat = false
	
	# Remove any existing theme overrides first
	button.remove_theme_stylebox_override("normal")
	button.remove_theme_stylebox_override("hover")
	button.remove_theme_stylebox_override("pressed")
	button.remove_theme_stylebox_override("focus")
	
	# Create a new StyleBoxFlat with the desired color
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.set_corner_radius_all(8)
	stylebox.content_margin_left = 10
	stylebox.content_margin_right = 10
	stylebox.content_margin_top = 10
	stylebox.content_margin_bottom = 10
	
	print("✅ Created StyleBoxFlat with color:", stylebox.bg_color)
	
	# Apply to all button states
	button.add_theme_stylebox_override("normal", stylebox)
	
	# Create slightly darker version for hover
	var hover_box = stylebox.duplicate()
	hover_box.bg_color = color.darkened(0.1)
	button.add_theme_stylebox_override("hover", hover_box)
	
	# Create even darker for pressed
	var pressed_box = stylebox.duplicate()
	pressed_box.bg_color = color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_box)
	
	# Also set focus style
	var focus_box = stylebox.duplicate()
	button.add_theme_stylebox_override("focus", focus_box)
	
	print("✅ Applied styleboxes to button")
	
	# Force update
	button.queue_redraw()
