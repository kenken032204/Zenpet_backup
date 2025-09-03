extends Control

@onready var title_label = $"journal-id/journal-title"
@onready var text_label = $"journal-id/ScrollContainer/journal-text"
@onready var close_btn = $"journal-settings/cancel-btn"
@onready var animation = $AnimationPlayer

var journal_data: Dictionary

func set_journal_data(data: Dictionary) -> void:
	await ready  # Wait until all @onready vars are valid
	journal_data = data

	if journal_data:
		title_label.text = journal_data["title"]
		text_label.text = journal_data["text"]

func _ready():
	animation.play("fade-in")
	close_btn.pressed.connect(func():
		queue_free()  # Close the panel
	)
