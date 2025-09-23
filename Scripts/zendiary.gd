extends Control

signal journal_saved(journal_text: String, journal_id: String)

@onready var back_button = $back_button
@onready var cards_container = $"Journal_window/GridContainer"
@onready var animation = $AnimationPlayer
@onready var back_to_journal = $"Add_Journal_window/back_zendiary"
@onready var add_new_journal = $"add_new_journal_btn"
@onready var save_btn = $"Add_Journal_window/journal-settings/save-btn"
@onready var cancel_btn = $"Add_Journal_window/journal-settings/cancel-btn"
@onready var Add_journal = $"Add_Journal_window"

@onready var journal_title = $"Add_Journal_window/journal-id/journal-title"
@onready var journal_text = $"Add_Journal_window/journal-id/ScrollContainer/journal-text"

@onready var no_notes_label = $"no_notes_indicator"
@onready var audio = $AudioStreamPlayer2D
@onready var journal_window = $"Journal_window"

@onready var toast_notif = $"toast_notification"

func _ready():
	
	JournalManager.load_journals()
	_refresh_journal_cards()
	audio.play()
	if JournalManager.journals.is_empty():
		no_notes_label.visible = true
	else:
		no_notes_label.visible = false
	
	animation.play("intro_fade")
	back_button.pressed.connect(_on_back_pressed)
	back_to_journal.pressed.connect(_on_back_to_zendiary_pressed)
	cancel_btn.pressed.connect(_on_back_to_zendiary_pressed)
	add_new_journal.pressed.connect(_on_add_new_journal_pressed)
	save_btn.pressed.connect(_on_save_new_journal_pressed)

func show_message(text: String, duration: float = 2.0):
	toast_notif.text = text
	toast_notif.modulate.a = 0.0
	toast_notif.visible = true

	var tween = create_tween()
	tween.tween_property(toast_notif, "modulate:a", 1.0, 0.3) # fade in
	tween.tween_interval(duration)
	tween.tween_property(toast_notif, "modulate:a", 0.0, 0.3) # fade out
	tween.tween_callback(Callable(toast_notif, "hide"))

func _on_back_pressed():
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)

func _on_add_new_journal_pressed():
	Global.play_sound(load("res://Audio/button-press-382713.mp3"))
	animation.play("fade-in")
	Add_journal.visible = true
	journal_window.visible = false
	add_new_journal.visible = false

func _on_save_new_journal_pressed():
	if journal_title.text == "" or journal_title.text.length() <= 5:
		print("title is too short!")
	else:
		if journal_text.text.length() >= 5:
			
			Global.play_sound(load("res://Audio/bmw-bong.mp3"))
			
			# 🔹 Save and capture the new journal
			var new_journal = JournalManager.add_journal(str(journal_title.text), str(journal_text.text))
			var new_id = new_journal["id"]
			
			# Clear input fields
			journal_title.text = ""
			journal_text.text = ""
			
			show_message("Added New Journal")
			_refresh_journal_cards()
			
			emit_signal("journal_saved", new_journal["text"], new_id)
			
		else:
			print("text too short!")


func _refresh_journal_cards(is_new_id: String = ""):
	# Clear old cards
	for child in cards_container.get_children():
		child.queue_free()

	# 🔹 Make a sorted copy (newest first)
	var sorted = JournalManager.journals.duplicate()
	sorted.sort_custom(func(a, b): return int(b["id"]) - int(a["id"]))

	# Rebuild from sorted journals
	for journal in sorted:
		var card = preload("res://Scenes/journal_card.tscn").instantiate()
		card.set_journal_data(journal, journal["id"] == is_new_id)
		cards_container.add_child(card)

		# Listen for the card's signals
		card.view_pressed.connect(_on_view_journal_pressed)
		card.delete_requested.connect(_on_delete_journal_requested)

	# Update "No Notes" label
	no_notes_label.visible = JournalManager.journals.is_empty()
	
	# Transition back
	animation.play("fade-in")
	Add_journal.visible = false
	journal_window.visible = true
	add_new_journal.visible = true



func _on_delete_journal_requested(journal_id: String):
	if JournalManager.delete_journal(journal_id):
		show_message("Deleted a journal")
		_refresh_journal_cards()

func _on_view_journal_pressed(journal_id: String):
	var journal = JournalManager.get_journal(journal_id)
	if journal:
		print("Opening journal:", journal["title"])

		# Load journal view/edit scene
		var scene = load("res://Scenes/view_journal_window.tscn") as PackedScene
		var journal_view = scene.instantiate()

		# Pass the journal data (existing entry → is_new = false)
		journal_view.set_journal_data(journal, false)

		# ✅ Connect the signal so journals refresh after editing
		journal_view.journal_saved.connect(func(new_id: String):
			_refresh_journal_cards(new_id)
			show_message("Successfully Edited Journal")
		)

		# Show on top of the current scene
		add_child(journal_view)

func _on_back_to_zendiary_pressed():
	Add_journal.visible = false
	journal_window.visible = true
	add_new_journal.visible = true
	
