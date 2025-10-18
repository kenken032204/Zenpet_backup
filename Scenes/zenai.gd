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
	#if JournalManager.last_journal.has("id"):
		#_start_conversation(JournalManager.last_journal["text"], JournalManager.last_journal["id"])
	
	# 🧠 Start a random hidden conversation on load (only AI reply shows)
	_start_random_hidden_conversation()

func _start_random_hidden_conversation():
	var random_prompts = [
		"Give me a random funny fact about cats.",
		"Greet me and give me a random joke.",
		"Hello.",
		"I just want some encouragement to keep going today.",
	]
	
	var random_index = randi() % random_prompts.size()
	var hidden_prompt = random_prompts[random_index]

	# Don't display the user message — only send it internally
	_send_to_gemini(hidden_prompt)

func _on_submit_pressed() -> void:
	var user_text = message_box.text.strip_edges()
	if user_text == "":
		return
	message_box.text = ""  # clear after sending

	add_message(user_text, true)
	_send_to_gemini(user_text)

func _send_to_gemini(user_text: String) -> void:
	# Instruction
	var instruction_text := "Respond in brief 1-2 short sentences. Stop after 2 sentences. Refrain from telling user to commit violence"

	# Build contents array from chat history
	var contents := []
	
	# Add all previous chat history
	for entry in chat_history:
		var role_text = "user" if entry["role"] == "user" else "model"
		contents.append({
			"role": role_text,
			"parts": [{"text": entry["text"]}]
		})
	
	# Add the current user message with instruction prepended
	var current_message = instruction_text + "\n\n" + user_text if contents.is_empty() else user_text
	contents.append({
		"role": "user",
		"parts": [{"text": current_message}]
	})

	# New Gemini v1beta request payload with full history
	var body := {
		"contents": contents
	}

	var headers = ["Content-Type: application/json"]
	var full_url = "%s?key=%s" % [GEMINI_ENDPOINT, GEMINI_API_KEY]
	var json_body = JSON.stringify(body)

	if chat_request:
		chat_request.request(full_url, headers, HTTPClient.METHOD_POST, json_body)
	else:
		push_error("chat_request node is missing")

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
							add_message(entry["text"], entry["role"] == "user", false)

# ==============================
# NAVIGATION
# ==============================
func _back_to_dashboard():
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)


# ==============================
# GEMINI REQUEST
# ==============================
func _start_conversation(journal_text: String, journal_id: String) -> void:
	var instruction_text := "Respond in exactly 1-2 short sentences with empathy. Use a gentle, supportive tone. Stop after 2 sentences."
	var full_prompt := "%s\n%s" % [instruction_text, journal_text]

	_send_to_gemini(full_prompt)

# ==============================
# GEMINI RESPONSE
# ==============================
func _on_request_completed(result, response_code, headers, body):
	
	print("Response code:", response_code)
	print("Body:", body.get_string_from_utf8())
	
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response and response.has("candidates") and response["candidates"].size() > 0:
			var parts = response["candidates"][0]["content"]["parts"]
			if parts.size() > 0 and parts[0].has("text"):
				var reply = parts[0]["text"]
				add_message(reply.strip_edges(), false)
	else:
		push_error("Gemini API request failed")

func add_message(text: String, is_user: bool, save: bool = true) -> void:
	var role = "user" if is_user else "model"
	var entry = { "role": role, "text": text }

	if save:
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
	# -- Row container --
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# -- Spacers --
	var left_spacer = Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right_spacer = Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# -- Bubble --
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.modulate = Color(1, 1, 1, 0)  # start invisible
	bubble.scale = Vector2(0.9, 0.9)     # slightly smaller initially
	
	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color("#FFD42C") if is_user else Color("#FFFFFF")
	bubble_style.border_width_left = 2
	bubble_style.border_width_top = 2
	bubble_style.border_width_right = 2
	bubble_style.border_width_bottom = 2
	bubble_style.border_color = Color("#313B45") if is_user else Color("#FF9B17")
	bubble_style.corner_radius_top_left = 16
	bubble_style.corner_radius_top_right = 16
	bubble_style.corner_radius_bottom_left = 16
	bubble_style.corner_radius_bottom_right = 16
	bubble_style.content_margin_left = 12
	bubble_style.content_margin_right = 12
	bubble_style.content_margin_top = 8
	bubble_style.content_margin_bottom = 8
	bubble.add_theme_stylebox_override("panel", bubble_style)
	
	# -- Label --
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if is_user:
		label.add_theme_color_override("font_color", Color("#FFFFFF"))
	else:
		label.add_theme_color_override("font_color", Color("#000000"))
	
	var vw = get_viewport_rect().size.x
	var max_bubble_width = vw * 0.7
	label.custom_minimum_size = Vector2(max_bubble_width - 24, 0)
	
	bubble.add_child(label)
	hbox.add_child(left_spacer)
	hbox.add_child(bubble)
	hbox.add_child(right_spacer)
	Vboxcontainer.add_child(hbox)
	
	# -- Alignment margins --
	var spacer_width = vw * 0.15
	if is_user:
		left_spacer.custom_minimum_size = Vector2(spacer_width, 0)
	else:
		right_spacer.custom_minimum_size = Vector2(spacer_width, 0)
	
	await get_tree().process_frame
	_update_scroll()

	# ✨ -- Animation with Tween --
	var tween = create_tween()
	tween.tween_property(bubble, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(bubble, "scale", Vector2(1, 1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _update_scroll():
	var scroll = $"ScrollContainer"
	await get_tree().process_frame  # wait 1 frame so size updates
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
