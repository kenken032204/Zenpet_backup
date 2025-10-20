extends Control

var current_request = ""
var user_id = Global.User.get("id", null)
var has_pet: bool = false

# Main Interactions
@onready var sleep_button = $"UI/HBoxContainer/Sleep_btn"
@onready var chat_button = $"UI/HBoxContainer/Chat_btn"
@onready var bath_button = $"UI/HBoxContainer/Bath_btn"

# Sleep Details
@onready var lamp_button = $"UI/Lamp_btn"
@onready var background = $TextureRect
@onready var tint_overlay = $ColorRect
@onready var zzz_particles = $CPUParticles2D
@onready var love_particles = $Love_particles

# Bath Details
@onready var bath_scene = $Bath
@onready var head_sprite = $"Pet/PetArea/HeadSprite"

# Logout and Settings
@onready var logout_btn = $"UI/VBoxContainer/Logout_btn"
@onready var settings_btn = $"UI/VBoxContainer/Settings_btn"

# Wardrobe and Furnitures
@onready var open_wardrobe = $"UI/VBoxContainer2/Wardrobe_btn"
@onready var open_furniture = $"UI/VBoxContainer2/Furnitures_btn"
@onready var open_kitchen = $"UI/VBoxContainer2/Kitchen_btn"

# Chat Details
@onready var back_button = $"UI/ChatSystem/ChatInput/back_to_main"
@onready var submit_message_button = $"UI/ChatSystem/ChatInput/submit_message"
@onready var reset_message_button = $"UI/ChatSystem/ChatInput/reset_messages"
@onready var message_box = $"UI/ChatSystem/ChatInput/message_box"
@onready var chat_request = $ChatRequest

var chat_history: Array = []
var GEMINI_API_KEY = "AIzaSyCo8wY7NHUtP2XvoNgDmpaXjhWXcW5ewFU"
var GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

# Level System
@onready var level_bar = $"UI/EXP_level"
@onready var level = $"UI/level"

# Misc
@onready var animation = $"Pet/AnimationPlayer"
@onready var GUIanimation = $"Pet/GUIAnimation"
@onready var room_name = $"room_name"
@onready var pet_name = $"pet_name"
@onready var pet_area = $Pet/PetArea
@onready var Audio = $"AudioStreamPlayer2D"

@onready var ExpPopup = preload("res://Scenes/pop_up.tscn")

var lamp_toggle = true
var is_hovering := false
var is_holding := false
var is_sleeping = false
var is_tweening_sleep := false
var is_tweening_little_sleep := false
var is_tweening_little_bath := false
var is_tweening_bath := false
var exp_given_after_sleep := false

var red_style := preload("res://Styles/button_buttom_pressed_texture.tres").duplicate() as StyleBoxFlat
var original_style := preload("res://Styles/button_button_original.tres").duplicate() as StyleBoxFlat
var yellow_style := preload("res://Styles/button_button_yellow.tres").duplicate() as StyleBoxFlat

@onready var http_pet = HTTPRequest.new()
@onready var http_outfit = HTTPRequest.new()

func _ready():
	
	if user_id == null:
		get_tree().change_scene_to_file("res://Scenes/login.tscn")
		return
	
	add_child(http_pet)
	add_child(http_outfit)
	
	http_pet.request_completed.connect(_on_http_pet_completed)
	http_outfit.request_completed.connect(_on_http_outfit_completed)

	check_user_pet()
	
	lamp_button.visible = false
	animation.play("idle")
	
	# Connect all signals
	pet_area.mouse_entered.connect(_on_mouse_entered)
	pet_area.mouse_exited.connect(_on_mouse_exited)
	pet_area.input_event.connect(_on_area_input_event)
	
	sleep_button.pressed.connect(_on_sleep_pressed)
	chat_button.pressed.connect(_on_chat_pressed)
	bath_button.pressed.connect(_on_bath_pressed)
	lamp_button.pressed.connect(_on_lamp_pressed)
	open_wardrobe.pressed.connect(_open_wardrobe)
	open_kitchen.pressed.connect(_open_kitchen)
	submit_message_button.pressed.connect(submit_message)
	reset_message_button.pressed.connect(reset_message)
	chat_request.request_completed.connect(_on_request_completed)
	back_button.pressed.connect(back_to_main)
	logout_btn.pressed.connect(back_to_dashboard)
	
	sleep_button.add_theme_stylebox_override("normal", sleep_button.get_theme_stylebox("normal").duplicate())
	lamp_button.add_theme_stylebox_override("normal", lamp_button.get_theme_stylebox("normal").duplicate())
	bath_button.add_theme_stylebox_override("normal", bath_button.get_theme_stylebox("normal").duplicate())

	Audio.play()
	
func check_user_pet():
	if user_id == null:
		return
	
	current_request = "get_pet"
	var url = "http://192.168.254.111/zenpet/check_user_pet.php?user_id=%d" % user_id
	http_pet.request(url, [], HTTPClient.METHOD_GET)

# ========== UNIFIED HTTP HANDLERS ==========

func _on_http_pet_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()

	if response_code != 200:
		push_error("HTTP request failed: %d" % response_code)
		return

	var parse_result = JSON.parse_string(response_text)
	if parse_result == null:
		push_error("Failed to parse JSON: %s" % response_text)
		return

	match current_request:
		"get_pet":
			_handle_get_pet(parse_result)
		"load_level":
			_handle_load_level(parse_result)
		"save_pet":
			_handle_save_pet(parse_result)

func _handle_get_pet(parse_result):
	if typeof(parse_result) == TYPE_ARRAY and parse_result.size() > 0:
		has_pet = true
		var pet_data = parse_result[0]
		print("User already has a pet:", parse_result[0])
		
		if pet_data.has("pet_name"):
			pet_name.text = str(pet_data["pet_name"])

		load_pet_data_from_server()
		load_equipped_outfits(user_id)
		load_chat_history()
		PetStore.pet_node = $Pet
		animation.play("idle")
	else:
		has_pet = false
		print("No pet found, redirecting to pet creation")
		get_tree().change_scene_to_file("res://Scenes/new_pet.tscn")

func _handle_load_level(parse_result):
	if typeof(parse_result) != TYPE_DICTIONARY:
		push_error("Expected a dictionary for load_level, got %s" % typeof(parse_result))
		return

	var loaded_level = int(parse_result.get("level", 1))
	var loaded_exp = float(parse_result.get("exp", 0.0))

	Global.User["level"] = loaded_level
	Global.User["exp"] = loaded_exp
	level.text = str(loaded_level)
	level_bar.value = loaded_exp

func _handle_save_pet(parse_result):
	if typeof(parse_result) == TYPE_ARRAY and parse_result.size() > 0:
		var updated_pet = parse_result[0]
		Global.User["level"] = int(updated_pet.get("level", 1))
		Global.User["exp"] = float(updated_pet.get("exp", 0))
		print("Pet data saved successfully")
	else:
		push_error("Failed to save pet data")

func _on_http_outfit_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	
	if response_code != 200:
		print("Failed to load outfits: " + response_text)
		return
	
	var parse_result = JSON.parse_string(response_text)
	if parse_result == null:
		print("Failed to parse outfits JSON")
		return

	var outfits_array = parse_result
	if typeof(parse_result) == TYPE_DICTIONARY and parse_result.has("items"):
		outfits_array = parse_result.get("items", [])
	
	if typeof(outfits_array) != TYPE_ARRAY or outfits_array.size() == 0:
		print("No outfits found for user.")
		return

	var category_mapping = {
		"Hat": "PetArea/HatSprite",
		"Dress": "PetArea/ChestSprite",
		"Boots": "PetArea/ArmSprite"
	}

	for outfit_row in outfits_array:
		var category = outfit_row.get("category", "")
		var sprite_url = outfit_row.get("sprite_url", "")

		if category == "" or not sprite_url or sprite_url == "":
			continue

		var sprite_path = category_mapping.get(category, "")
		if sprite_path == "":
			continue

		if sprite_url and sprite_url != "":
			var tex = load(sprite_url)
			if tex:
				var sprite_node = PetStore.pet_node.get_node_or_null(sprite_path)
				if sprite_node:
					sprite_node.texture = tex
					PetStore.equipped_outfits[category] = outfit_row
					print("Loaded equipped outfit: ", category)
			else:
				print("Failed to load sprite at path: " + sprite_url)

# ========== PET DATA LOADING ==========

func load_pet_data_from_server():
	current_request = "load_level"
	var url = "http://192.168.254.111/zenpet/get_user_level.php?user_id=" + str(Global.User["id"])
	http_pet.request(url, [], HTTPClient.METHOD_GET)

func load_equipped_outfits(user_id: int):
	var url = "http://192.168.254.111/zenpet/get_equipped_outfits.php?user_id=%d" % user_id
	http_outfit.request(url, [], HTTPClient.METHOD_GET)

func save_pet_data_to_server():
	current_request = "save_pet"
	var url = "http://192.168.254.111/zenpet/update_exp.php"
	var body = {
		"user_id": Global.User["id"],
		"level": Global.User["level"],
		"exp": Global.User["exp"]
	}
	var headers = ["Content-Type: application/json"]
	http_pet.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# ========== EXPERIENCE AND LEVELING ==========

func increase_exp(amount: float):
	var current_level = int(Global.User.get("level", 1))
	var current_exp = float(Global.User.get("exp", 0))

	var scaled_amount = amount / max(current_level, 1)
	current_exp += scaled_amount
	
	var did_level_up = current_exp >= 100
	
	if did_level_up:
		current_exp -= 100
		current_level += 1
	
	var tween = get_tree().create_tween()
	tween.tween_property(level_bar, "value", current_exp, 1.0)
	
	await tween.finished
	
	Global.User["level"] = current_level
	Global.User["exp"] = current_exp

	level.text = str(current_level)
	level_bar.value = current_exp
	level_bar.max_value = 100
	
	if did_level_up:
		var popup = preload("res://Scenes/leveled_up.tscn").instantiate()
		add_child(popup)
		popup.show_level_up(current_level)
	
	show_exp_gain(amount, global_position + Vector2(50, -50))
	save_pet_data_to_server()

func show_exp_gain(amount: float, position: Vector2):
	var popup = ExpPopup.instantiate()
	popup.text = "+%d EXP" % int(amount)
	popup.position = position
	add_child(popup)

	var tween = create_tween()
	tween.tween_property(popup, "position", position + Vector2(0, -40), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(popup.queue_free)

# ========== CHAT SYSTEM ==========

func submit_message():
	if message_box.text.strip_edges() != "":
		var user_input = message_box.text
		add_message(user_input, true)
		message_box.text = ""

		var parts = []
		parts.append({ "text": "You are a friendly cat companion. Respond briefly and cheerfully." })

		for entry in chat_history:
			parts.append({ "text": entry["text"] })

		var body = {
			"contents": [
				{
					"parts": parts
				}
			]
		}

		var headers = [ "Content-Type: application/json" ]
		var full_url = "%s?key=%s" % [GEMINI_ENDPOINT, GEMINI_API_KEY]
		var json_body = JSON.stringify(body)
		chat_request.request(full_url, headers, HTTPClient.METHOD_POST, json_body)

func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response and response.has("candidates"):
			var reply = response["candidates"][0]["content"]["parts"][0]["text"]
			add_message(reply.strip_edges(), false)

func reset_message():
	clear_chat_history()
	chat_history.clear()

	var chat_box = $UI/ChatSystem/ChatMessages/ChatBox
	for child in chat_box.get_children():
		chat_box.remove_child(child)
		child.queue_free()

func save_chat_history():
	var file = FileAccess.open("user://chat_history.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(chat_history))
	file.close()

func load_chat_history():
	if FileAccess.file_exists("user://chat_history.json"):
		var file = FileAccess.open("user://chat_history.json", FileAccess.READ)
		var loaded_data = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(loaded_data) == TYPE_ARRAY:
			chat_history = loaded_data
			for entry in chat_history:
				if entry.has("text") and entry.has("role"):
					var is_user = entry["role"] == "user"
					display_message(entry["text"], is_user)

func clear_chat_history():
	var file = FileAccess.open("user://chat_history.json", FileAccess.WRITE)
	file.store_string("[]")
	file.close()

func display_message(text: String, is_user: bool):
	var msg_label = Label.new()
	msg_label.text = ("You: " if is_user else "Pet: ") + text
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.add_theme_color_override("font_color", Color.html("#2c3e50") if is_user else Color.html("#8e44ad"))

	$UI/ChatSystem/ChatMessages/ChatBox.add_child(msg_label)

	await get_tree().process_frame
	var scroll = $UI/ChatSystem/ChatMessages
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func add_message(text: String, is_user: bool = false, save: bool = true):
	if save:
		var entry = {
			"text": text,
			"role": "user" if is_user else "pet"
		}
		chat_history.append(entry)
		save_chat_history()

	var msg_label = Label.new()
	msg_label.text = ("You: " if is_user else "Pet: ") + text
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.add_theme_color_override("font_color", Color.html("#34495e") if is_user else Color.html("#2c3e50"))

	$UI/ChatSystem/ChatMessages/ChatBox.add_child(msg_label)

	await get_tree().process_frame
	var scroll = $UI/ChatSystem/ChatMessages
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# ========== BUTTON STYLING ==========

func update_sleep_button_style():
	if Global.is_sleepy and !is_tweening_sleep:
		is_tweening_sleep = true
		is_tweening_little_sleep = false
		var red_style_copy = red_style.duplicate()
		var tween = create_tween()
		tween.tween_method(
			func(color):
				red_style_copy.bg_color = color
				sleep_button.add_theme_stylebox_override("normal", red_style_copy),
			sleep_button.get_theme_stylebox("normal").bg_color,
			Color.html("#9f1e33"),
			1.0
		)

	elif Global.little_sleepy and !Global.is_sleepy and !is_tweening_little_sleep:
		is_tweening_little_sleep = true
		is_tweening_sleep = false
		var yellow_style_copy = yellow_style.duplicate()
		var tween = create_tween()
		tween.tween_method(
			func(color):
				yellow_style_copy.bg_color = color
				sleep_button.add_theme_stylebox_override("normal", yellow_style_copy),
			sleep_button.get_theme_stylebox("normal").bg_color,
			Color.html("#f9ca24"),
			1.0
		)

	elif !Global.little_sleepy and !Global.is_sleepy:
		if is_tweening_sleep or is_tweening_little_sleep:
			is_tweening_sleep = false
			is_tweening_little_sleep = false
			var original_copy = original_style.duplicate()
			var tween = create_tween()
			tween.tween_method(
				func(color):
					original_copy.bg_color = color
					sleep_button.add_theme_stylebox_override("normal", original_copy),
				sleep_button.get_theme_stylebox("normal").bg_color,
				original_style.bg_color,
				1.0
			)

func update_bath_button_style(dirt: Sprite2D):
	if Global.is_dirty and !is_tweening_bath:
		head_sprite.texture = load("res://Sprite/Cat/Dirty_cat.png")
		is_tweening_bath = true
		is_tweening_little_bath = false
		var red_style_copy = red_style.duplicate()
		var tween = create_tween()
		tween.tween_method(
			func(color): 
				red_style_copy.bg_color = color
				bath_button.add_theme_stylebox_override("normal", red_style_copy),
			bath_button.get_theme_stylebox("normal").bg_color,
			Color.html("#9f1e33"),
			1.0
		)
		dirt.visible = true

	elif Global.little_dirty and !Global.is_dirty and !is_tweening_little_bath:
		is_tweening_little_bath = true
		is_tweening_bath = false
		head_sprite.texture = load("res://Sprite/Cat/Dirty_cat.png")
		var yellow_style_copy = yellow_style.duplicate()
		var tween = create_tween()
		tween.tween_method(
			func(color): 
				yellow_style_copy.bg_color = color
				bath_button.add_theme_stylebox_override("normal", yellow_style_copy),
			bath_button.get_theme_stylebox("normal").bg_color,
			Color.html("#f9ca24"),
			1.0
		)
		dirt.visible = false

	elif !Global.little_dirty and !Global.is_dirty:
		head_sprite.texture = load("res://Sprite/Cat/Asset 7.png")
		if is_tweening_bath or is_tweening_little_bath:
			is_tweening_bath = false
			is_tweening_little_bath = false
			var original_copy = original_style.duplicate()
			var tween = create_tween()
			tween.tween_method(
				func(color): 
					original_copy.bg_color = color
					bath_button.add_theme_stylebox_override("normal", original_copy),
				bath_button.get_theme_stylebox("normal").bg_color,
				original_style.bg_color,
				1.0
			)
			dirt.visible = false

func play_button_pop(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

# ========== MAIN LOOP ==========

func _process(delta):
	Global.decay_stats(delta)
	Global.save_stats()
	var dirt = $Pet/PetArea/DirtSprite

	if is_sleeping:
		Global.energy = clamp(Global.energy + delta * 2.0, 0, 100)
		Global.is_sleepy = Global.energy < 30

		if Global.energy >= 99.9 and !exp_given_after_sleep:
			increase_exp(20.0)
			play_button_pop(sleep_button)
			exp_given_after_sleep = true
			is_sleeping = false

	update_sleep_button_style()
	update_bath_button_style(dirt)

# ========== PET INTERACTIONS ==========

func _on_mouse_entered() -> void:
	is_hovering = true

func _on_mouse_exited() -> void:
	is_hovering = false
	if is_holding:
		is_holding = false
		animation.play("idle")
		love_particles.emitting = false

func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not is_hovering or is_sleeping:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_holding = true
			animation.play("pet")
			love_particles.emitting = true
			print("Pet being petted - animation started")
		else:
			is_holding = false
			animation.play("idle")
			love_particles.emitting = false
			print("Pet released - back to idle")

# ========== SCENE NAVIGATION ==========

func back_to_dashboard():
	save_chat_history()
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	animation.play("idle")
	get_tree().change_scene_to_packed(scene)
	
func _open_wardrobe():
	save_chat_history()
	var pet = $Pet
	PetStore.pet_node = pet
	pet.get_parent().remove_child(pet)
	var scene = load("res://Scenes/wardrobe.tscn") as PackedScene
	animation.play("idle")
	get_tree().change_scene_to_packed(scene)

func _open_kitchen():
	var pet = $Pet
	PetStore.pet_node = pet
	pet.get_parent().remove_child(pet)
	var scene = load("res://Scenes/kitchen.tscn") as PackedScene
	animation.play("idle")
	get_tree().change_scene_to_packed(scene)

# ========== ROOM INTERACTIONS ==========

func _on_sleep_pressed():
	save_chat_history()
	background.texture = preload("res://Sprite/empty-room-interior-design_1308-80588.png")
	lamp_button.visible = true
	bath_scene.visible = false
	room_name.text = "Bed Room"
	Global.play_sound(preload("res://Audio/comedy_pop_finger_in_mouth_001.mp3"))
	exp_given_after_sleep = false
	
func _on_lamp_pressed():
	is_sleeping = !is_sleeping
	
	if is_sleeping:
		lamp_button.text = "Turn On Lamp"
		tint_overlay.visible = true
		zzz_particles.emitting = true
		animation.play("sleep")  
		Global.play_sound(load("res://Audio/168860__orginaljun__light-switch-01.mp3"))
	else:
		lamp_button.text = "Turn Off Lamp"
		tint_overlay.visible = false
		zzz_particles.emitting = false
		animation.play("idle")
		Global.play_sound(load("res://Audio/168860__orginaljun__light-switch-01.mp3"))

func _on_chat_pressed():
	background.texture = load("res://Sprite/empty-room-with-black-floor-pink-walls_1308-65874.png")
	lamp_button.visible = false
	tint_overlay.visible = false
	zzz_particles.emitting = false
	is_sleeping = false
	lamp_toggle = true
	room_name.text = "Living Room"
	bath_scene.visible = false
	$UI/HBoxContainer.visible = false
	$UI/ChatSystem.visible = true
	GUIanimation.play("show_message")
	animation.play("idle")
	Global.play_sound(load("res://Audio/comedy_pop_finger_in_mouth_001.mp3"))

func back_to_main():
	$UI/HBoxContainer.visible = true
	$UI/ChatSystem.visible = false

func _on_bath_pressed():
	save_chat_history()
	background.texture = load("res://Sprite/empty-white-room-with-windows-white-tiles_1308-73482.png")
	lamp_button.visible = false
	tint_overlay.visible = false
	zzz_particles.emitting = false
	lamp_toggle = true
	is_sleeping = false
	room_name.text = "Bath Room"
	lamp_button.text = "Turn Off Lamp"
	bath_scene.visible = true
	animation.play("idle")
	Global.play_sound(load("res://Audio/comedy_pop_finger_in_mouth_001.mp3"))

func on_bath_completed():
	increase_exp(10.0)
	play_button_pop(bath_button)

func save_pet_data():
	var data = {
		"level": int(level.text),
		"exp": level_bar.value
	}
	var file = FileAccess.open("user://pet_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t")) 
	file.close()
