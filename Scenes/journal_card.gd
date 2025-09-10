extends Control

signal view_pressed(journal_id)
signal delete_requested(journal_id)  # NEW

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
	await ready  # ✅ ensures @onready vars are initialized

	journal_data = data
	journal_id = journal_data.get("id", "")

	title_label.text = journal_data.get("title", "Untitled")
	date_label.text = journal_data.get("date", "--/--/----")
	text_label.text = journal_data.get("text", "")

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
