extends Control


# =======================
# 🖐️ ScrollContainer drag-to-scroll
# =======================
var scroll_dragging := false
var last_mouse_pos := Vector2.ZERO

signal journal_saved(journal_text: String, journal_id: String)

@onready var back_button = $back_button
@onready var cards_container = $"Journal_window/GridContainer"
@onready var animation = $AnimationPlayer
@onready var diary_animation = $PanelContainer/AnimationPlayer
@onready var back_to_journal = $"Add_Journal_window/back_zendiary"
@onready var add_new_journal = $"add_new_journal_btn"
@onready var save_btn = $"Add_Journal_window/journal-settings/save-btn"
@onready var cancel_btn = $"Add_Journal_window/journal-settings/cancel-btn"
@onready var add_journal_window = $"Add_Journal_window"
@onready var journal_title = $"Add_Journal_window/journal-id/journal-title"
@onready var journal_text = $"Add_Journal_window/journal-id/ScrollContainer/TextEdit"
@onready var journal_id_panel = $"Add_Journal_window/journal-id"
@onready var no_notes_label = $"no_notes_indicator"
@onready var audio = $AudioStreamPlayer2D
@onready var journal_window = $"Journal_window"
@onready var toast_notif = $"toast_notification"

@onready var go_zenai = $"go_to_zenai"


@onready var red_button = $"Add_Journal_window/HBoxContainer/red_btn"
@onready var blue_button = $"Add_Journal_window/HBoxContainer/blue_btn"
@onready var green_button = $"Add_Journal_window/HBoxContainer/green_btn"
@onready var orange_button = $"Add_Journal_window/HBoxContainer/orange_btn"

var API_URL = Global.BASE_URL
const MIN_TITLE_LENGTH = 5
const MIN_CONTENT_LENGTH = 5

var selected_color: String = "#F39C12"
var save_in_progress: bool = false

func _ready():
	print("📱 Initializing Journal Manager")
	_connect_signals()
	await load_journals_from_php()
	_refresh_journal_cards()
	audio.play()
	animation.play("intro_fade")
	
func _connect_signals() -> void:
	go_zenai.pressed.connect(_go_zenai_pressed)
	back_button.pressed.connect(_on_back_pressed)
	back_to_journal.pressed.connect(_on_back_to_journal_pressed)
	cancel_btn.pressed.connect(_on_back_to_journal_pressed)
	add_new_journal.pressed.connect(_on_add_new_journal_pressed)
	save_btn.pressed.connect(_on_save_journal_pressed)
	
	red_button.pressed.connect(func(): _select_color("#E74C3C"))
	blue_button.pressed.connect(func(): _select_color("#3498DB"))
	green_button.pressed.connect(func(): _select_color("#2ECC71"))
	orange_button.pressed.connect(func(): _select_color("#F39C12"))

func _go_zenai_pressed() -> void:
	# Optional: Play a button click sound
	var click_sound: AudioStream = preload("res://Audio/rne Perc.wav")
	Global.play_sound(click_sound, -15)

	var tween = create_tween()
	tween.tween_property($"zenai_btn", "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property($"zenai_btn", "scale", Vector2(1.0, 1.0), 0.1)
	
	var zenai_scene = preload("res://Scenes/zenai.tscn").instantiate()
	get_tree().root.add_child(zenai_scene)
	
	# Optionally free current scene if needed
	get_tree().current_scene.queue_free()

	# Set the new scene as current
	get_tree().current_scene = zenai_scene

# 📥 Fetch journals from PHP backend
func load_journals_from_php() -> void:
	var user_id = int(Global.User.get("id", 0))
	if user_id <= 0:
		print("⚠️ Invalid user ID")
		return
	
	var journals = await _make_request(
		"%s/get_journals.php?user_id=%d" % [API_URL, user_id],
		HTTPClient.METHOD_GET
	)
	
	if journals is Array:
		var valid_journals: Array = []
		for journal in journals:
			if typeof(journal) == TYPE_DICTIONARY and journal.has("id"):
				valid_journals.append({
					"id": str(journal["id"]),
					"title": journal.get("title", "Untitled"),
					"text": journal.get("content", ""),
					"date": journal.get("date_created", ""),
					"color": journal.get("color", "#FFFFFF")
				})
		
		JournalManager.journals = valid_journals
		print("✅ Loaded %d journals" % valid_journals.size())
	else:
		print("⚠️ Failed to load journals")
		JournalManager.journals = []
	
	_refresh_journal_cards()

# ➕ Add new journal to PHP backend
func add_journal_to_php(title: String, text: String) -> bool:
	if not _validate_input(title, text):
		return false
	
	var payload = {
		"user_id": int(Global.User.get("id", 0)),
		"title": title,
		"content": text,
		"color": selected_color
	}
	
	var response = await _make_request(
		"%s/add_journal.php" % API_URL,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	
	if response is Dictionary and response.get("success", false):
		var new_journal = {
			"id": str(response["id"]),
			"title": response["title"],
			"text": response["content"],
			"date": response["date_created"],
			"color": response["color"]
		}
		JournalManager.journals.append(new_journal)
		return true
	else:
		print("❌ Failed to save journal")
		return false

# 🔧 Generic HTTP request handler for Godot 4.4
func _make_request(url: String, method: int = HTTPClient.METHOD_GET, body: String = "") -> Variant:
	var http = HTTPRequest.new()
	add_child(http)
	
	var headers = ["Content-Type: application/json"]
	var err = http.request(url, headers, method, body if body != "" else "")

	if err != OK:
		print("❌ HTTP Request failed: ", err)
		http.queue_free()
		return null
	
	var result = await http.request_completed
	http.queue_free()
	
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]
	var response_text: String = response_body.get_string_from_utf8()
	
	print("📊 HTTP %d: %s" % [response_code, response_text])
	
	# Accept 200, 201, 204 as success
	if response_code not in [200, 201, 204]:
		print("❌ HTTP Error %d" % response_code)
		return null
	
	# Handle empty responses (204 No Content)
	if response_text.is_empty():
		return {"success": true}
	
	# Parse JSON
	var json = JSON.new()
	var parse_error = json.parse(response_text)
	if parse_error != OK:
		print("⚠️ JSON parse error: ", json.get_error_message())
		return null
	
	return json.get_data()

# ✅ Input validation
func _validate_input(title: String, text: String) -> bool:
	if title.length() < MIN_TITLE_LENGTH:
		show_message("Title too short!")
		return false
	if text.length() < MIN_CONTENT_LENGTH:
		show_message("Content too short!")
		return false
	return true

# 🎨 Select color
func _select_color(color: String) -> void:
	selected_color = color
	_set_panel_color(journal_id_panel, Color(color))
	show_message("Color selected", 1.0)

# 🎨 Set panel background color
func _set_panel_color(panel: Panel, color: Color) -> void:
	if not panel:
		return
	
	var stylebox = panel.get_theme_stylebox("panel")
	if stylebox and stylebox is StyleBoxFlat:
		stylebox = stylebox.duplicate()
		stylebox.bg_color = color
	else:
		stylebox = StyleBoxFlat.new()
		stylebox.bg_color = color
		stylebox.set_corner_radius_all(8)
	
	panel.add_theme_stylebox_override("panel", stylebox)
	panel.queue_redraw()

# 📢 Show toast notification
func show_message(text: String, duration: float = 2.0) -> void:
	toast_notif.text = text
	toast_notif.modulate.a = 0.0
	toast_notif.visible = true
	
	var tween = create_tween()
	tween.tween_property(toast_notif, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(toast_notif, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): toast_notif.hide())

# 🔄 Refresh journal cards UI
func _refresh_journal_cards(new_id: String = "") -> void:
	for child in cards_container.get_children():
		child.queue_free()
	
	var sorted = JournalManager.journals.duplicate()
	sorted.sort_custom(func(a, b): return int(b["id"]) - int(a["id"]))
	
	for journal in sorted:
		var card = preload("res://Scenes/journal_card.tscn").instantiate()
		card.set_journal_data(journal, str(journal["id"]) == new_id)
		cards_container.add_child(card)
		card.view_pressed.connect(_on_view_journal_pressed)
		card.delete_requested.connect(_on_delete_journal_requested)
	
	no_notes_label.visible = JournalManager.journals.is_empty()
	animation.play("fade-in")
	add_journal_window.visible = false
	journal_window.visible = true
	add_new_journal.visible = true

# 📖 View/Edit journal
func _on_view_journal_pressed(journal_id: String) -> void:
	var journal = JournalManager.get_journal(journal_id)
	if not journal or journal.is_empty():
		show_message("Journal not found")
		return
	
	var scene = load("res://Scenes/view_journal_window.tscn") as PackedScene
	if not scene:
		show_message("View scene missing")
		return
	
	var journal_view = scene.instantiate()
	journal_view.set_journal_data(journal, false)
	journal_view.journal_saved.connect(func(_id: String):
		_refresh_journal_cards(_id)
		show_message("Journal updated")
	)
	add_child(journal_view)

# 🗑️ Delete journal
func _on_delete_journal_requested(journal_id: String) -> void:
	var user_id = int(Global.User.get("id", 0))
	var journal_id_int = int(journal_id)
	
	var payload = {
		"id": journal_id_int,
		"user_id": user_id
	}
	
	var response = await _make_request(
		"%s/delete_journal.php" % API_URL,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)
	
	if response is Dictionary and response.get("success", false):
		for i in range(JournalManager.journals.size()):
			if int(JournalManager.journals[i]["id"]) == journal_id_int:
				JournalManager.journals.remove_at(i)
				break
		show_message("Journal deleted")
		_refresh_journal_cards()
	else:
		show_message("Failed to delete")

# ➕ Open add journal window
func _on_add_new_journal_pressed() -> void:
	Global.play_sound(load("res://Audio/button-press-382713.mp3"))
	animation.play("fade-in")
	add_journal_window.visible = true
	journal_window.visible = false
	add_new_journal.visible = false
	selected_color = "#F39C12"
	_set_panel_color(journal_id_panel, Color("#F39C12"))

# 💾 Save new journal
func _on_save_journal_pressed() -> void:
	if save_in_progress:
		return
	
	Global.play_sound(load("res://Audio/bmw-bong.mp3"))
	save_in_progress = true
	save_btn.disabled = true
	
	var title: String = journal_title.text.strip_edges()
	var content: String = journal_text.text.strip_edges()

	var success = await add_journal_to_php(title, content)
	
	if success:
		show_message("Journal saved!")
		
		# store in ZenAi memory
		var new_entry = {
			"title": title,
			"text": content,
			"date": Time.get_datetime_string_from_system()
		}
		ZenAiMemory.add_entry(new_entry)
	
		# 🧠 Play ZenAi reading effect
		await _zenai_read_journal(content)
		
		# 💬 Then trigger emotional reflection
		# _trigger_zenai_reflection(content)

		journal_title.text = ""
		journal_text.text = ""
		_refresh_journal_cards()
	else:
		show_message("Failed to save")
	
	save_btn.disabled = false
	save_in_progress = false

func _zenai_read_journal(entry_text: String) -> void:
	show_message("ZenAi is reading your diary entry...")
	
	diary_animation.play("diary_reading")
	await get_tree().create_timer(3.0).timeout  # simulate “reading time”
	diary_animation.play("diary_closed")
	
# 🔙 Navigation
func _on_back_to_journal_pressed() -> void:
	add_journal_window.visible = false
	journal_window.visible = true
	add_new_journal.visible = true

func _on_back_pressed() -> void:
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
