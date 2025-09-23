extends Control

@onready var back_btn = $"back_button"
@onready var chat_request = $"ChatRequest"

@onready var scroll = $ScrollContainer
@onready var Vboxcontainer = $"ScrollContainer/VBoxContainer"
@onready var message_box = $"ChatInput/message_box"
@onready var submit_message = $"ChatInput/submit_message"
@onready var animation = $AnimationPlayer
@onready var reset_btn = $"HBoxContainer/clear_prompt"

var SAVE_PATH = "user://zenAi_history.json"

var chat_history: Array = []
var GEMINI_API_KEY = "AIzaSyCo8wY7NHUtP2XvoNgDmpaXjhWXcW5ewFU" 
var GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

func clear_chat_history():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("[]") # empty JSON array
		file.close()
	chat_history.clear()
	
	for child in Vboxcontainer.get_children():
		child.queue_free()

func _ready() -> void:
	
	animation.play("shake")
	chat_request.request_completed.connect(_on_request_completed)
	reset_btn.pressed.connect(clear_chat_history)
	back_btn.pressed.connect(_back_to_dashboard)
	submit_message.pressed.connect(_on_submit_pressed)
	
	load_chat_history()

	# Connect to JournalManager
	var callable = Callable(self, "_start_conversation")
	if not JournalManager.journal_saved.is_connected(callable):
		JournalManager.journal_saved.connect(callable)

	# Start immediately if a last journal exists
	if JournalManager.last_journal.has("id"):
		_start_conversation(JournalManager.last_journal["text"], JournalManager.last_journal["id"])

# Called when user presses "send"
func _on_submit_pressed() -> void:
	var user_text = message_box.text.strip_edges()
	if user_text == "":
		return
	message_box.text = ""  # clear after sending

	add_message(user_text, true)
	chat_history.append({ "role": "user", "text": user_text })
	_send_to_gemini(user_text)

# Shared sending logic
func _send_to_gemini(user_text: String) -> void:
	var contents = []
	# Add history
	for entry in chat_history:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("role") and entry.has("text"):
			contents.append({
				"role": entry["role"],
				"parts": [{ "text": entry["text"] }]
			})

	var body = { "contents": contents }
	var headers = ["Content-Type: application/json"]
	var full_url = "%s?key=%s" % [GEMINI_ENDPOINT, GEMINI_API_KEY]
	var json_body = JSON.stringify(body)
	
	chat_request.request(full_url, headers, HTTPClient.METHOD_POST, json_body)

	
# ==============================
# SAVE / LOAD
# ==============================
func save_chat_history() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_data = JSON.stringify(chat_history)
		file.store_string(json_data)
		file.close()

func load_chat_history() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var parsed = JSON.parse_string(content)
			if typeof(parsed) == TYPE_ARRAY:
				chat_history = parsed

				for entry in chat_history:
					if typeof(entry) == TYPE_DICTIONARY:
						if entry.has("text") and entry.has("role"):
							_show_message(entry["text"], entry["role"] == "user", true)

# ==============================
# NAVIGATION
# ==============================
func _back_to_dashboard():
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)


# ==============================
# JOURNAL → GEMINI
# ==============================
func _start_conversation(journal_text: String, journal_id: String) -> void:
	# Build Gemini request contents
	var contents = [
		{
			"role": "user",
			"parts": [
			  {
				"text": "Respond in 1-2 sentences maximum with empathy and understanding. Use a gentle, supportive tone as if you're listening to a close friend share their thoughts. Avoid using bold, bulleted, numbered, long words. " 
			  },
			  {
				"text": journal_text
			  }
			]
		}
	]

	# Append chat history (excluding the just-added journal to avoid duplication)
	for entry in chat_history.slice(0, chat_history.size() - 1):
		contents.append({
			"role": entry["role"],
			"parts": [{ "text": entry["text"] }]
		})

	var body = { "contents": contents }
	var headers = ["Content-Type: application/json"]
	var full_url = "%s?key=%s" % [GEMINI_ENDPOINT, GEMINI_API_KEY]
	var json_body = JSON.stringify(body)

	chat_request.request(full_url, headers, HTTPClient.METHOD_POST, json_body)


# ==============================
# GEMINI RESPONSE
# ==============================
func _on_request_completed(result, response_code, headers, body):

	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response and response.has("candidates") and response["candidates"].size() > 0:
			var parts = response["candidates"][0]["content"]["parts"]
			if parts.size() > 0 and parts[0].has("text"):
				var reply = parts[0]["text"]
				add_message(reply.strip_edges(), false)
	else:
		push_error("Gemini API request failed")

func add_message(text: String, is_user: bool) -> void:
	var role = "user" if is_user else "model"
	var entry = { "role": role, "text": text }
	chat_history.append(entry)
	save_chat_history()
	_show_message(text, is_user)

func type_text(label: Label, full_text: String, delay: float = 0.004) -> void:
	label.text = ""
	for i in full_text.length():
		label.text += full_text[i]
		
		await get_tree().process_frame
		
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
		
		await get_tree().create_timer(delay).timeout


func _show_message(text: String, is_user: bool, skip_typing: bool = false) -> void:
	# Create label
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_user else HORIZONTAL_ALIGNMENT_LEFT

	# Color styling
	if is_user:
		label.add_theme_color_override("font_color", Color(0.2, 0.6, 1)) # blue
	else:
		label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.4)) # green

	Vboxcontainer.add_child(label)

	# Typing effect logic
	if is_user or skip_typing:
		# User messages and history show instantly
		label.text = text
		_update_scroll()
	else:
		# AI new responses "type out"
		await type_text(label, text)
		_update_scroll()

func _update_scroll():
	var scroll = $"ScrollContainer"
	await get_tree().process_frame  # wait 1 frame so size updates
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
