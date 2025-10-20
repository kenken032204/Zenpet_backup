extends Control

signal journal_saved(journal_id: String)

@onready var title_label = $"journal-id/journal-title"
@onready var text_label = $"journal-id/ScrollContainer/journal-text"
@onready var save_btn = $"journal-settings/save-btn"
@onready var close_btn = $"journal-settings/cancel-btn"
@onready var back_to_main = $"back_zendiary"
@onready var share_diary = $"share_diary"
@onready var animation = $AnimationPlayer
@onready var journal_id_panel = $"journal-id"  # The panel background
@onready var toast_notif = $"toast_notification" if has_node("toast_notification") else null

var journal_data: Dictionary
var is_new: bool = true
var save_in_progress: bool = false  # 🚫 Prevent double submission

# =======================
# 📄 Load Journal Data
# =======================
func set_journal_data(data: Dictionary, new_entry: bool = false) -> void:
	await ready
	print("📖 Attempting to load journal data...")
	
	journal_data = data
	is_new = new_entry

	if not is_new and journal_data:
		print("✅ Journal found:", JSON.stringify(journal_data))
		title_label.text = journal_data.get("title", "")
		text_label.text = journal_data.get("text", "")

		# 🎨 Apply the journal's color
		var color_value = journal_data.get("color", "#FFFFFF")
		print("📋 Loading journal with color:", color_value)
		_set_panel_color(journal_id_panel, Color(color_value))
	else:
		print("🆕 Creating new journal entry")
		title_label.text = ""
		text_label.text = ""

# =======================
# 🧠 Initialization
# =======================
func _ready():
	print("🪄 view_journal_window ready — fade-in starting...")
	animation.play("fade-in")
	
	back_to_main.pressed.connect(_on_close_pressed)
	close_btn.pressed.connect(_on_close_pressed)
	save_btn.pressed.connect(_on_save_pressed)

# =======================
# 💾 Save Logic
# =======================
func _on_save_pressed() -> void:
	if save_in_progress:
		print("⚠️ Save already in progress")
		return

	var title = title_label.text.strip_edges()
	var text = text_label.text.strip_edges()
	var user_id = int(Global.User.get("id", 0))

	print("💾 Attempting to save journal...")
	print("   📝 Title:", title)
	print("   🧠 Text length:", text.length())
	print("   👤 User ID:", user_id)

	if title == "" or title.length() < 5:
		print("❌ Title too short (min 5 chars required)")
		return
	if text == "" or text.length() < 5:
		print("❌ Text too short (min 5 chars required)")
		return
	if user_id == 0:
		print("❌ Invalid user_id — cannot save journal")
		return

	save_in_progress = true
	save_btn.disabled = true
	Global.play_sound(load("res://Audio/bmw-bong.mp3"))

	var new_id: String = ""

	if is_new:
		print("📦 Creating new journal entry in database...")
		var new_journal: Dictionary = await JournalManager.add_journal(title, text, user_id)

		if new_journal.is_empty():
			print("❌ Failed to add journal — JournalManager returned empty result")
			save_in_progress = false
			save_btn.disabled = false
			return

		new_id = new_journal["id"]
		journal_data = new_journal
		print("✅ New journal created with ID:", new_id)
	else:
		print("🧩 Updating existing journal with ID:", journal_data.get("id", "unknown"))
		journal_data["title"] = title
		journal_data["text"] = text

		var success = await JournalManager.update_journal(journal_data, user_id)
		if not success:
			print("❌ Failed to update journal")
			save_in_progress = false
			save_btn.disabled = false
			return

		# ✅ Refresh journals from PHP after update
		print("🔄 Refreshing journals after update...")
		var updated = await JournalManager.update_journal(journal_data, user_id)
		if updated:
			await JournalManager.load_journals_from_php(user_id)
			print("✅ Journals reloaded successfully")

		new_id = journal_data["id"]
		print("✅ Journal updated successfully")

	emit_signal("journal_saved", new_id)
	print("📨 Emitted journal_saved signal for ID:", new_id)

	await get_tree().create_timer(0.5).timeout
	print("🧹 Closing journal view after save...")
	queue_free()

	save_in_progress = false
	save_btn.disabled = false

# =======================
# 🎨 Color Helper
# =======================
func _set_panel_color(panel: Panel, color: Color) -> void:
	if not panel:
		print("❌ Panel is null!")
		return
	
	print("🎨 Setting panel color:", color)
	var stylebox = panel.get_theme_stylebox("panel")

	if stylebox:
		stylebox = stylebox.duplicate()
		if stylebox is StyleBoxFlat:
			stylebox.bg_color = color
			panel.add_theme_stylebox_override("panel", stylebox)
			print("✅ Applied color to existing StyleBoxFlat")
		else:
			var new_stylebox = StyleBoxFlat.new()
			new_stylebox.bg_color = color
			new_stylebox.set_corner_radius_all(8)
			panel.add_theme_stylebox_override("panel", new_stylebox)
			print("🎨 Created new StyleBoxFlat for panel")
	else:
		var new_stylebox = StyleBoxFlat.new()
		new_stylebox.bg_color = color
		new_stylebox.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", new_stylebox)
		print("🆕 Added new stylebox override for panel")

	panel.queue_redraw()

# =======================
# ❌ Close Window
# =======================
func _on_close_pressed():
	print("❌ Closing journal view window...")
	queue_free()
