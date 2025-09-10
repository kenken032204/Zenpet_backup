extends Control

signal journal_saved(journal_id: String)

@onready var title_label = $"journal-id/journal-title"
@onready var text_label = $"journal-id/ScrollContainer/journal-text"
@onready var save_btn = $"journal-settings/save-btn"
@onready var close_btn = $"journal-settings/cancel-btn"
@onready var back_to_main = $"back_zendiary"
@onready var share_diary = $"share_diary"
@onready var animation = $AnimationPlayer

var journal_data: Dictionary
var is_new: bool = true

func set_journal_data(data: Dictionary, new_entry: bool = false) -> void:
	await ready
	journal_data = data
	is_new = new_entry

	if not is_new and journal_data:
		title_label.text = journal_data["title"]
		text_label.text = journal_data["text"]
	else:
		title_label.text = ""
		text_label.text = ""

func _ready():
	animation.play("fade-in")
	back_to_main.pressed.connect(func(): queue_free())
	close_btn.pressed.connect(func(): queue_free())
	save_btn.pressed.connect(_on_save_pressed)

func _on_save_pressed():
	# ✅ Validation
	if title_label.text.strip_edges() == "" or title_label.text.length() < 5:
		print("Title is too short!")
		return
	if text_label.text.strip_edges() == "" or text_label.text.length() < 5:
		print("Text is too short!")
		return

	Global.play_sound(load("res://Audio/bmw-bong.mp3"))
	var new_id: String = ""

	if is_new:
		# ✅ Use add_journal to auto-generate id, title, text, date
		var new_journal: Dictionary = JournalManager.add_journal(title_label.text, text_label.text)
		new_id = new_journal["id"]

		# If you want to also hold the full data locally:
		journal_data = new_journal
	else:
		# ✅ Update journal (keep id & date from before)
		journal_data["title"] = title_label.text
		journal_data["text"] = text_label.text
		JournalManager.update_journal(journal_data)
		new_id = journal_data["id"]

	emit_signal("journal_saved", new_id)
	queue_free()
