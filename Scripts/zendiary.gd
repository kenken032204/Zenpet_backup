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
@onready var journal_id_panel = $"Add_Journal_window/journal-id"  # The panel to color

@onready var no_notes_label = $"no_notes_indicator"
@onready var audio = $AudioStreamPlayer2D
@onready var journal_window = $"Journal_window"

@onready var toast_notif = $"toast_notification"

# Journal Colors 
@onready var red_button = $"Add_Journal_window/HBoxContainer/red_btn"
@onready var blue_button = $"Add_Journal_window/HBoxContainer/blue_btn"
@onready var green_button = $"Add_Journal_window/HBoxContainer/green_btn"
@onready var orange_button = $"Add_Journal_window/HBoxContainer/orange_btn"

var selected_color: String = "#F39C12" # default white

func get_journals(user_id: String) -> Array:
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals?user_id=eq.%s" % user_id
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY"
	]

	var http := HTTPRequest.new()
	add_child(http)

	var err := http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("Request failed: ", err)
		return []

	var result = await http.request_completed
	var response_code: int = result[1]
	var body_raw: PackedByteArray = result[3]
	var body_text: String = body_raw.get_string_from_utf8()

	if response_code == 200:
		var parsed = JSON.parse_string(body_text)
		if typeof(parsed) == TYPE_ARRAY:
			return parsed
	else:
		print("❌ Fetch failed:", response_code, body_text)

	return []

func add_journal(title: String, text: String, user_id: String) -> Dictionary:
	
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals" 
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json",
		"Prefer: return=representation",
	]
	
	# 📅 Format current date/time
	var now = Time.get_datetime_dict_from_system()
	var formatted_date = "%04d-%02d-%02d %02d:%02d:%02d" % [
		now.year, now.month, now.day,
		now.hour, now.minute, now.second
	]
	
	var payload = {
		"title": title,
		"content": text,
		"user_id": user_id,
		"color": selected_color,
		"date_created": formatted_date
	}

	var http := HTTPRequest.new()
	add_child(http)

	# Send POST
	var err = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		print("Insert request failed:", err)
		return {}

	# Wait for completion
	var result = await http.request_completed
	var response_code: int = result[1]
	var body_raw: PackedByteArray = result[3]
	var body_text: String = body_raw.get_string_from_utf8()

	if response_code == 201:
		var parsed = JSON.parse_string(body_text)
		if typeof(parsed) == TYPE_ARRAY and parsed.size() > 0:
			print("✅ Inserted journal:", parsed[0])
			return parsed[0]  # return the inserted row
	else:
		print("❌ Insert failed:", response_code, body_text)

	return {}

func _ready():
	print(Global.User)
	await load_journals_from_supabase()
	_refresh_journal_cards()
	audio.play()

	animation.play("intro_fade")
	back_button.pressed.connect(_on_back_pressed)
	back_to_journal.pressed.connect(_on_back_to_zendiary_pressed)
	cancel_btn.pressed.connect(_on_back_to_zendiary_pressed)
	add_new_journal.pressed.connect(_on_add_new_journal_pressed)
	save_btn.pressed.connect(_on_save_new_journal_pressed)
	
	# 🎨 Connect color buttons
	red_button.pressed.connect(func(): _select_color("#E74C3C"))
	blue_button.pressed.connect(func(): _select_color("#3498DB"))
	green_button.pressed.connect(func(): _select_color("#2ECC71"))
	orange_button.pressed.connect(func(): _select_color("#F39C12"))

func _select_color(color: String) -> void:
	selected_color = color
	
	print("🎨 Selected color:", color)
	
	# 🎨 Update the panel background immediately for preview
	_set_panel_color(journal_id_panel, Color(color))
	
	show_message("Selected color: " + color, 1.5)

func load_journals_from_supabase() -> void:
	var user_id = int(Global.User.get("id", 0))
	var journals = await get_journals(str(user_id))

	print("📥 Journals from Supabase:", journals)

	if typeof(journals) == TYPE_ARRAY:
		var valid_journals: Array = []
		for j in journals:
			if typeof(j) == TYPE_DICTIONARY and j.has("id"):
				# Force Supabase ID to string of int (avoid "1.0")
				var clean_id = str(int(j["id"]))  

				var new_j = {
					"id": clean_id,
					"title": j.get("title", "Untitled"),
					"text": j.get("content", ""),
					"date": j.get("date_created", "--/--/----"),
					"color": j.get("color", "#FFFFFF") # 🟦 Load color
				}
				valid_journals.append(new_j)

		JournalManager.journals = valid_journals

		if valid_journals.size() > 0:
			var new_id = str(valid_journals[0]["id"])
			_refresh_journal_cards(new_id)
		else:
			_refresh_journal_cards()
	else:
		JournalManager.journals = []
		_refresh_journal_cards()

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
	
	# 🎨 Reset to default color when opening
	selected_color = "#F39C12"
	_set_panel_color(journal_id_panel, Color("#F39C12"))

func _on_save_new_journal_pressed():
	if journal_title.text == "" or journal_title.text.length() <= 5:
		show_message("Title too short!", 2.0)
		return

	if journal_text.text.length() < 5:
		show_message("Content too short!", 2.0)
		return

	# 🔊 Play sound
	Global.play_sound(load("res://Audio/bmw-bong.mp3"))

	# 📝 Save to Supabase
	var new_journal = await add_journal(journal_title.text, journal_text.text, str(int(Global.User.get("id", 0))))

	if new_journal.size() > 0:
		var new_id = str(new_journal["id"])

		# ✅ Update local cache
		JournalManager.journals.append(new_journal)

		# Clear input fields
		journal_title.text = ""
		journal_text.text = ""

		# 🔄 Refresh UI
		show_message("Journal saved")
		_refresh_journal_cards(new_id)

		# 🔔 Emit signal for other nodes
		emit_signal("journal_saved", new_journal["content"], new_id)
	else:
		show_message("Failed to save journal")

func _refresh_journal_cards(is_new_id: String = ""):
	# Clear old cards
	for child in cards_container.get_children():
		child.queue_free()

	# Make a sorted copy (newest first)
	var sorted = JournalManager.journals.duplicate()
	sorted.sort_custom(func(a, b): return int(b["id"]) - int(a["id"]))

	# Rebuild from sorted journals
	for journal in sorted:
		var card = preload("res://Scenes/journal_card.tscn").instantiate()
		card.set_journal_data(journal, str(journal["id"]) == is_new_id)
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

func _on_delete_journal_requested(journal_id: String) -> void:

	var id_int = int(journal_id)  # safe now ("1" → 1)
	var success = await JournalManager.delete_journal(id_int)

	if success:
		show_message("Deleted journal Success", 2.0)
		_refresh_journal_cards()
	else:
		show_message("Deleted journal Failed", 2.0)

func _on_view_journal_pressed(journal_id: String):
	
	var journal = JournalManager.get_journal(journal_id)
	if journal:

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

# 🎨 Helper function to set panel background color
func _set_panel_color(panel: Panel, color: Color) -> void:
	if not panel:
		print("❌ Panel is null!")
		return
	
	print("🎨 Setting panel color:", color)
	
	# Get the current stylebox or create a new one
	var stylebox = panel.get_theme_stylebox("panel")
	
	if stylebox:
		# Duplicate it so we don't modify the shared resource
		stylebox = stylebox.duplicate()
		if stylebox is StyleBoxFlat:
			stylebox.bg_color = color
			panel.add_theme_stylebox_override("panel", stylebox)
			print("✅ Applied color to existing StyleBoxFlat")
		else:
			# If not StyleBoxFlat, create a new one
			var new_stylebox = StyleBoxFlat.new()
			new_stylebox.bg_color = color
			new_stylebox.set_corner_radius_all(8)
			panel.add_theme_stylebox_override("panel", new_stylebox)
			print("✅ Created new StyleBoxFlat")
	else:
		# Create a brand new StyleBoxFlat
		var new_stylebox = StyleBoxFlat.new()
		new_stylebox.bg_color = color
		new_stylebox.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", new_stylebox)
		print("✅ Created new StyleBoxFlat (no existing style)")
	
	# Force update
	panel.queue_redraw()
