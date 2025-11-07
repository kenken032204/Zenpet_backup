extends Control

@onready var back_btn = $"back_button"
@onready var chat_request = $"ChatRequest"

@onready var chat_input = $"ChatInput"
var last_keyboard_height := 0

var original_input_y := 0.0
var original_scroll_bottom := 0.0

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

func _process(_delta: float) -> void:
	var keyboard_height_ui := 0.0

	if OS.has_feature("mobile"):
		# 📱 Real mobile keyboard height
		var keyboard_height_px := DisplayServer.virtual_keyboard_get_height()
		if keyboard_height_px != last_keyboard_height:
			last_keyboard_height = keyboard_height_px

			# Convert pixels → UI units
			var screen_height_px := DisplayServer.screen_get_size().y
			var viewport_height_ui := get_viewport_rect().size.y
			var scale_factor := viewport_height_ui / screen_height_px
			keyboard_height_ui = keyboard_height_px * scale_factor

			_adjust_for_keyboard(keyboard_height_ui)

func _adjust_for_keyboard(height: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var chat_input := $ChatInput
	var scroll_box := $ScrollContainer
	var adjusted_height := height * 0.85  # fine-tune this factor

	if height > 10:
		print("Keyboard up:", height)
		tween.tween_property(chat_input, "position:y", original_input_y - adjusted_height, 0.4)
		tween.parallel().tween_property(scroll_box, "offset_bottom", original_scroll_bottom - adjusted_height, 0.4)

		# Auto-scroll to latest message
		await tween.finished
		scroll_box.scroll_vertical = scroll_box.get_v_scroll_bar().max_value

	else:
		print("Keyboard down")
		tween.tween_property(chat_input, "position:y", original_input_y, 0.3)
		tween.parallel().tween_property(scroll_box, "offset_bottom", original_scroll_bottom, 0.3)

func _start_reflective_conversation():
	var recent_entries = ZenAiMemory.get_recent_entries(3)
	if recent_entries.is_empty():
		print("🪶 No journals to reflect on yet.")
		return

	var joined_text = ""
	for entry in recent_entries:
		joined_text += "Journal: %s\nEntry: %s\n\n" % [entry["title"], entry["content"]]

	var reflective_prompt = (
		"These are my recent diary entries. Please respond kindly and empathetically, " +
		"summarizing what emotional patterns or thoughts you notice. " +
		"Keep your response short (2–3 sentences max) and sound like a supportive friend.\n\n" +
		joined_text
	)

	_send_to_gemini(reflective_prompt)
	
func clear_chat_history():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string("[]") # empty JSON array
		file.close()
	chat_history.clear()
	
	for child in Vboxcontainer.get_children():
		child.queue_free()

func _ready() -> void:
	
	original_input_y = $ChatInput.position.y
	original_scroll_bottom = $ScrollContainer.offset_bottom
		
	animation.play("shake")
	chat_request.request_completed.connect(_on_request_completed)
	reset_btn.pressed.connect(clear_chat_history)
	back_btn.pressed.connect(_back_to_dashboard)
	submit_message.pressed.connect(_on_submit_pressed)
	load_chat_from_server()
	
	# 🪶 When new journal is saved, reflect on it
	if not JournalManager.journal_saved.is_connected(Callable(self, "_start_reflective_conversation")):
		JournalManager.journal_saved.connect(Callable(self, "_start_reflective_conversation"))

	var recent_entries = ZenAiMemory.get_recent_entries(3)
	if recent_entries.is_empty():
		print("📚 No journals found — starting with random fact.")
		_start_random_hidden_conversation()
	else:
		print("📘 Found journals — starting reflective conversation.")
		_start_reflective_conversation()

func _start_random_hidden_conversation():
	var random_prompts = [
		"Give me a random funny fact about cats. Start of with 'Here's a funny fact about cats... ",
		"Greet me with 'Hello! I am ZenAi your friendly chatting partner :> ' and give me a random joke. make it unique each time. ",
		"Reassure me that everything will be alright. Start of with 'Hello. How are you?' ",
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
	var instruction_text := "Respond in 1–2 sentences. Keep it kind and simple. if prompted 'who made you?' you're developed by a ZenCorp. "

	# 🧠 Load recent journal context
	var recent_entries = ZenAiMemory.get_recent_entries(3)
	var joined_journals = ""
	if not recent_entries.is_empty():
		for entry in recent_entries:
			joined_journals += "- %s: %s\n" % [entry["title"], entry["content"]]
	else:
		joined_journals = "No recent journals found."

	# Combine the user text + journals for richer context
	var combined_prompt = (
		"%s\n\nUser's recent journals:\n%s\n\nUser says: %s" %
		[instruction_text, joined_journals, user_text]
	)

	# Build chat content array
	var contents := []
	for entry in chat_history:
		var role_text = "user" if entry["role"] == "user" else "model"
		contents.append({
			"role": role_text,
			"parts": [{"text": entry["text"]}]
		})

	# Add new prompt
	contents.append({
		"role": "user",
		"parts": [{"text": combined_prompt}]
	})

	# Prepare and send HTTP request
	var body := { "contents": contents }
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
		_send_to_server(role, text) # ✅ Send to PHP + SQL

	_show_message(text, is_user)

func _send_to_server(role: String, message: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)

	var url := "%ssave_chat.php" % Global.BASE_URL

	var data := {
		"user_id": Global.User.get("id"),
		"role": role,
		"message": message
	}

	var headers := ["Content-Type: application/x-www-form-urlencoded"]
	var body := ""

	for key in data.keys():
		body += "%s=%s&" % [key, str(data[key]).uri_encode()]

	http.request(url, headers, HTTPClient.METHOD_POST, body)

func load_chat_from_server():
	var http := HTTPRequest.new()
	add_child(http)
	
	var user_id = Global.User.get("id")
	var url = "%sload_chat.php?user_id=%s" % [Global.BASE_URL, str(user_id)]
	
	http.request(url)
	http.request_completed.connect(_on_load_chat_completed)
	
func _on_load_chat_completed(result, response_code, headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response and response.has("messages"):
			for msg in response["messages"]:
				add_message(msg["text"], msg["role"] == "user", false)

func type_text(label: Label, full_text: String, delay: float = 0.004) -> void:
	label.text = ""
	for i in full_text.length():
		label.text += full_text[i]
		
		await get_tree().process_frame
		
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
		
		await get_tree().create_timer(delay).timeout

func _show_message(text: String, is_user: bool, skip_typing: bool = false) -> void:
	Global.play_sound(load("res://Audio/bubble_iMw0wu6.mp3"))
	
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
	bubble.scale = Vector2(0.8, 0.8)     # smaller start for bounce effect
	
	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color("#FFD42C") if is_user else Color("#FFFFFF")

	# ✅ Manually set all border widths (instead of border_width_all)
	bubble_style.border_width_left = 2
	bubble_style.border_width_top = 2
	bubble_style.border_width_right = 2
	bubble_style.border_width_bottom = 2

	# Border color
	bubble_style.border_color = Color("#313B45") if is_user else Color("#FF9B17")

	# ✅ Manually set all corner radii (instead of corner_radius_all)
	bubble_style.corner_radius_top_left = 16
	bubble_style.corner_radius_top_right = 16
	bubble_style.corner_radius_bottom_left = 16
	bubble_style.corner_radius_bottom_right = 16

	# Padding
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
	label.add_theme_color_override("font_color", Color("#FFFFFF") if is_user else Color("#000000"))
	
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

	# ✨ -- Pop + Bounce Animation --
	var tween = create_tween()
	tween.tween_property(bubble, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(bubble, "scale", Vector2(1.05, 1.05), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(bubble, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _update_scroll():
	var scroll = $"ScrollContainer"
	await get_tree().process_frame  # wait 1 frame so size updates
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
