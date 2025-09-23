extends Control

#Main Interactions
@onready var sleep_button = $"UI/HBoxContainer/Sleep_btn"
@onready var chat_button = $"UI/HBoxContainer/Chat_btn"
@onready var bath_button = $"UI/HBoxContainer/Bath_btn"

#Sleep Details
@onready var lamp_button = $"UI/Lamp_btn"
@onready var background = $TextureRect
@onready var tint_overlay = $ColorRect
@onready var zzz_particles = $CPUParticles2D  # Adjust path as needed
@onready var love_particles = $Love_particles  # Adjust path as needed

#Bath Details
@onready var bath_scene = $Bath
@onready var head_sprite = $"Pet/PetArea/HeadSprite"
# Logout and Settings
@onready var logout_btn = $"UI/VBoxContainer/Logout_btn"
@onready var settings_btn = $"UI/VBoxContainer/Settings_btn"

#Wardrobe and Furnitures
@onready var open_wardrobe = $"UI/VBoxContainer2/Wardrobe_btn"
@onready var open_furniture = $"UI/VBoxContainer2/Furnitures_btn"
@onready var open_kitchen = $"UI/VBoxContainer2/Kitchen_btn"

#Chat Details
@onready var back_button = $"UI/ChatSystem/ChatInput/back_to_main"
@onready var submit_message_button = $"UI/ChatSystem/ChatInput/submit_message"
@onready var reset_message_button = $"UI/ChatSystem/ChatInput/reset_messages"
@onready var message_box = $"UI/ChatSystem/ChatInput/message_box"
@onready var chat_request = $ChatRequest

var chat_history: Array = []
var GEMINI_API_KEY = "AIzaSyCo8wY7NHUtP2XvoNgDmpaXjhWXcW5ewFU"  # Replace with yours
var GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

#Level System
@onready var level_bar = $"UI/EXP_level"
@onready var level = $"UI/level"

#Misc
@onready var animation = $"Pet/AnimationPlayer"
var lamp_toggle = true

@onready var pet_area = $Pet/PetArea
var is_hovering := false
var is_holding := false

@onready var Audio = $"AudioStreamPlayer2D"
var is_sleeping = false
var is_tweening_sleep := false
var is_tweening_little_sleep := false
var is_tweening_little_bath := false
var is_tweening_bath := false
var red_style := preload("res://Styles/button_buttom_pressed_texture.tres").duplicate() as StyleBoxFlat
var original_style := preload("res://Styles/button_button_original.tres").duplicate() as StyleBoxFlat
var yellow_style := preload("res://Styles/button_button_yellow.tres").duplicate() as StyleBoxFlat

func _ready():
	
	Global.load_stats()
	
	PetStore.pet_node = $Pet
	load_equipped_outfits()
	load_chat_history()
	Global.play_sound(load("res://Audio/meow-1.mp3"), -30.0) 
	Audio.play()
	Audio.finished.connect(_on_audio_finished)
	animation.play("idle")
	var outfit = PetStore.equipped_outfits
	
	# Connect signal to trigger idle after intro
	animation.animation_finished.connect(_on_intro_finished)
	
	if outfit["Hat"] and outfit["Hat"].has("sprite"):
		var hat_sprite = $Pet/PetArea/HatSprite
		if hat_sprite:
			hat_sprite.texture = load(outfit["Hat"]["sprite"])
	
	if outfit["Dress"] and outfit["Dress"].has("sprite"):
		var dress_sprite = $Pet/PetArea/ChestSprite
		if dress_sprite:
			dress_sprite.texture = load(outfit["Dress"]["sprite"])
	
	if outfit["Boots"] and outfit["Boots"].has("sprite"):
		var boots_sprite = $Pet/PetArea/ArmSprite
		if boots_sprite:
			boots_sprite.texture = load(outfit["Boots"]["sprite"])
					
	#Load JSON Data
	load_pet_data()
	lamp_button.visible = false
	animation.play("idle")
	
	#Connect Buttons
	
	pet_area.connect("mouse_entered", _on_mouse_entered)
	pet_area.connect("mouse_exited", _on_mouse_exited)
	settings_btn.pressed.connect(_open_settings)
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

func _on_audio_finished():
	Audio.play()
	
func _on_intro_finished(name):
	if name == "pet_ready":
		animation.play("pet")
		love_particles.emitting = true
		
func load_equipped_outfits():
	var path = "user://equipped_outfits.json"
	if not FileAccess.file_exists(path):
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)
	print(result)

	# Loop through each category and apply the saved outfit
	for category in result.keys():
		var item = result[category]
		var sprite_path = item.get("sprite", "")

		if sprite_path != "":
			match category:
				"Hat":
					var hat_sprite = PetStore.pet_node.get_node("PetArea/HatSprite")
					if hat_sprite:
						hat_sprite.texture = load(sprite_path)
				"Dress":
					var dress_sprite = PetStore.pet_node.get_node("PetArea/ChestSprite")
					if dress_sprite:
						dress_sprite.texture = load(sprite_path)
				"Boots":
					var boots_sprite = PetStore.pet_node.get_node("PetArea/ChestSprite")
					if boots_sprite:
						boots_sprite.texture = load(sprite_path)

		# Also update PetStore memory for future reference
		PetStore.equipped_outfits[category] = item

func _process(delta):
	
	Global.decay_stats(delta)
	Global.save_stats()  
	var dirt = $Pet/PetArea/DirtSprite

	if is_sleeping:
		Global.energy = clamp(Global.energy + delta * 2.0, 0, 100)
		Global.is_sleepy = Global.energy < 30

	update_sleep_button_style()
	update_bath_button_style(dirt) 
	
func update_sleep_button_style():
	if Global.is_sleepy and !is_tweening_sleep:
		is_tweening_sleep = true
		is_tweening_little_sleep = false  # Cancel yellow
		var tween = create_tween()
		tween.tween_method(
			func(color): 
				red_style.bg_color = color
				sleep_button.add_theme_stylebox_override("normal", red_style),
			sleep_button.get_theme_stylebox("normal").bg_color,
			Color.html("#9f1e33"),
			1.0
		)

	elif Global.little_sleepy and !Global.is_sleepy and !is_tweening_little_sleep:
		is_tweening_little_sleep = true
		is_tweening_sleep = false  # Cancel red
		var tween = create_tween()
		tween.tween_method(
			func(color): 
				yellow_style.bg_color = color
				sleep_button.add_theme_stylebox_override("normal", yellow_style),
			sleep_button.get_theme_stylebox("normal").bg_color,
			Color.html("#f9ca24"),
			1.0
		)

	elif !Global.little_sleepy and !Global.is_sleepy:
		if is_tweening_sleep or is_tweening_little_sleep:
			is_tweening_sleep = false
			is_tweening_little_sleep = false
			var tween = create_tween()
			tween.tween_method(
				func(color): 
					original_style.bg_color = color
					sleep_button.add_theme_stylebox_override("normal", original_style),
				sleep_button.get_theme_stylebox("normal").bg_color,
				original_style.bg_color,
				1.0
			)

func update_bath_button_style(dirt: Sprite2D):
	if Global.is_dirty and !is_tweening_bath:
		# Red state
		head_sprite.texture = load("res://Sprite/Cat/Dirty_cat.png")
		is_tweening_bath = true
		is_tweening_little_bath = false
		var tween = create_tween()
		tween.tween_method(
			func(color): 
				red_style.bg_color = color
				bath_button.add_theme_stylebox_override("normal", red_style),
			bath_button.get_theme_stylebox("normal").bg_color,
			Color.html("#9f1e33"),
			1.0
		)
		dirt.visible = true

	elif Global.little_dirty and !Global.is_dirty and !is_tweening_little_bath:
		# Yellow state
		is_tweening_little_bath = true
		is_tweening_bath = false
		head_sprite.texture = load("res://Sprite/Cat/Dirty_cat.png")
		var tween = create_tween()
		tween.tween_method(
			func(color): 
				yellow_style.bg_color = color
				bath_button.add_theme_stylebox_override("normal", yellow_style),
			bath_button.get_theme_stylebox("normal").bg_color,
			Color.html("#f9ca24"),
			1.0
		)
		dirt.visible = false

	elif !Global.little_dirty and !Global.is_dirty:
		# Reset to original style
		head_sprite.texture = load("res://Sprite/Cat/Asset 7.png")
		if is_tweening_bath or is_tweening_little_bath:
			is_tweening_bath = false
			is_tweening_little_bath = false
			var tween = create_tween()
			tween.tween_method(
				func(color): 
					original_style.bg_color = color
					bath_button.add_theme_stylebox_override("normal", original_style),
				bath_button.get_theme_stylebox("normal").bg_color,
				original_style.bg_color,
				1.0
			)
			dirt.visible = false

func _on_mouse_entered():
	is_hovering = true

func _on_mouse_exited():
	is_hovering = false
	if is_holding:
		is_holding = false
		animation.play("idle")
				
func back_to_dashboard():
	save_chat_history()
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	animation.play("idle")
	get_tree().change_scene_to_packed(scene)
	
func _open_wardrobe():
	save_chat_history()
	var pet = $Pet
	PetStore.pet_node = pet
	
	# Detach the pet from the current scene
	pet.get_parent().remove_child(pet)

	# Load and switch scene (this will not delete pet_node now)
	var scene = load("res://Scenes/wardrobe.tscn") as PackedScene
	animation.play("idle")
	get_tree().change_scene_to_packed(scene)

func _open_settings():
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")

func _open_kitchen():
	var pet = $Pet
	PetStore.pet_node = pet
	
	# Detach the pet from the current scene
	pet.get_parent().remove_child(pet)

	# Load and switch scene (this will not delete pet_node now)
	var scene = load("res://Scenes/kitchen.tscn") as PackedScene
	animation.play("idle")
	get_tree().change_scene_to_packed(scene)


func submit_message():
	if message_box.text.strip_edges() != "":
		var user_input = message_box.text
		add_message(user_input, true)  # This saves and displays
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

func reset_message():
	clear_chat_history()
	chat_history.clear()

	# Remove all message labels from the chat box
	var chat_box = $UI/ChatSystem/ChatMessages/ChatBox
	for child in chat_box.get_children():
		chat_box.remove_child(child)
		child.queue_free()

	
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response and response.has("candidates"):
			var reply = response["candidates"][0]["content"]["parts"][0]["text"]
			add_message(reply.strip_edges(), false)
			
func clear_chat_history():
	var file = FileAccess.open("user://chat_history.json", FileAccess.WRITE)
	file.store_string("[]")
	file.close()

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
					display_message(entry["text"], is_user)  # <- Only display, no saving!


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

	# This part draws the message visually
	var msg_label = Label.new()
	msg_label.text = ("You: " if is_user else "Pet: ") + text
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.add_theme_color_override("font_color", Color.html("#34495e") if is_user else Color.html("#2c3e50"))

	$UI/ChatSystem/ChatMessages/ChatBox.add_child(msg_label)

	await get_tree().process_frame
	var scroll = $UI/ChatSystem/ChatMessages
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func load_pet_data():
	if FileAccess.file_exists("user://pet_data.json"):
		var file = FileAccess.open("user://pet_data.json", FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(data) == TYPE_DICTIONARY:
			level.text = str(int(data.get("level", 1)))
			level_bar.value = data.get("exp", 0)
	else:
		level.text = "1"
		level_bar.value = 0

func increase_exp(base_amount: float):
	var current_level = int(level.text)
	var scaled_amount = base_amount / current_level
	level_bar.value += scaled_amount
	
	if level_bar.value >= 100:
		level_bar.value = 0
		current_level += 1
		level.text = str(current_level)
		
		var popup = preload("res://Scenes/leveled_up.tscn").instantiate()
		add_child(popup)
		popup.show_level_up(current_level)

	save_pet_data()

func _on_sleep_pressed():
	save_chat_history()
	background.texture = load("res://Sprite/empty-room-interior-design_1308-80588.png")
	lamp_button.visible = true
	bath_scene.visible = false
	Global.play_sound(load("res://Audio/comedy_pop_finger_in_mouth_001.mp3"))
	increase_exp(10.0)
	
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
		animation.play("idle")  # Play here
		Global.play_sound(load("res://Audio/168860__orginaljun__light-switch-01.mp3"))

func _on_chat_pressed():
	background.texture = load("res://Sprite/empty-room-with-black-floor-pink-walls_1308-65874.png")
	lamp_button.visible = false
	tint_overlay.visible = false
	zzz_particles.emitting = false
	is_sleeping = false
	lamp_toggle = true
	bath_scene.visible = false
	$UI/HBoxContainer.visible = false
	$UI/ChatSystem.visible = true
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
	lamp_button.text = "Turn Off Lamp"
	bath_scene.visible = true
	increase_exp(10.0)
	animation.play("idle")
	Global.play_sound(load("res://Audio/comedy_pop_finger_in_mouth_001.mp3"))

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and !is_sleeping:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_hovering:
				is_holding = true
				animation.play("pet_ready")
			else:
				is_holding = false
				animation.play("idle")
				love_particles.emitting = false
			
# Saving data for JSON
func save_pet_data():
	var data = {
		"level": int(level.text),
		"exp": level_bar.value
	}
	var file = FileAccess.open("user://pet_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))  # Pretty print
	file.close()
