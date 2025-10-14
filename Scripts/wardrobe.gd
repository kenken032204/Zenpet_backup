extends Control

#back 
@onready var back = $"UI/back_button"

#accessories buttons
@onready var hat = $"UI/hat_button"
@onready var dress = $"UI/dress_button"
@onready var boots = $"UI/boots_button"

#Next button and Prev button
@onready var prev_btn = $"UI/Panel/Menu/HBoxContainer/prev_button"
@onready var next_btn = $"UI/Panel/Menu/HBoxContainer/next_button"
@onready var apply_outfit = $"UI/Panel/Menu/HBoxContainer/apply_outfit"
@onready var outfit_label = $"UI/Panel/outfit_identification"
#Item
@onready var open_panel = $"UI/Panel"
@onready var item = $"UI/Panel/Menu/Label"

#Misc
@onready var Audio = $"AudioStreamPlayer2D"
var current_items: Array = []
var current_index: int = 0

var player_level: int = 0  # default if not loaded

func _ready():
	
	player_level = Global.User.get("level", 0)
	
	Audio.play()

	hat.toggle_mode = true
	dress.toggle_mode = true
	boots.toggle_mode = true

	open_panel.visible = false

	back.pressed.connect(back_to_home)
	hat.toggled.connect(_on_accessory_toggled.bind("Hat"))
	dress.toggled.connect(_on_accessory_toggled.bind("Dress"))
	boots.toggled.connect(_on_accessory_toggled.bind("Boots"))
	next_btn.pressed.connect(_on_next_pressed)
	prev_btn.pressed.connect(_on_prev_pressed)
	apply_outfit.pressed.connect(_apply_pressed)

	if PetStore.pet_node:
		add_child(PetStore.pet_node)
		load_equipped_outfits()  # ← Load saved outfit here!

func _on_accessory_toggled(button_pressed: bool, category: String):
	if button_pressed:
		# Untoggle the other buttons
		match category:
			"Hat":
				dress.button_pressed = false
				boots.button_pressed = false
				outfit_label.text = "Head"
				show_hat_items()
			"Dress":
				hat.button_pressed = false
				boots.button_pressed = false
				outfit_label.text = "Dress"
				show_dress_items()
			"Boots":
				hat.button_pressed = false
				dress.button_pressed = false
				outfit_label.text = "Shoes"
				show_boot_items()
	else:
		# If untoggled, just hide the panel
		open_panel.visible = false

func show_hat_items():
	open_panel.visible = true
	current_items = await load_wardrobe_items("Hat")  # ← Added await
	current_index = 0
	_render_single_item()

func show_dress_items():
	open_panel.visible = true
	current_items = await load_wardrobe_items("Dress")  # ← Added await
	current_index = 0
	_render_single_item()

func show_boot_items():
	open_panel.visible = true
	current_items = await load_wardrobe_items("Boots")  # ← Added await
	current_index = 0
	_render_single_item()


func back_to_home():
	get_tree().change_scene_to_file("res://Scenes/petmain.tscn")

func load_wardrobe_items(category: String) -> Array:
	var filtered_items: Array = []

	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/pet_outfits?outfit_type=eq." + category
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json",
		"Prefer: return=representation"

	]

	var http := HTTPRequest.new()
	add_child(http)

	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("❌ Supabase request failed to start.")
		return filtered_items

	# Wait for completion signal
	var result = await http.request_completed

	# Result format: [result_enum, response_code, headers, body]
	var response_code = result[1]
	var body = result[3]

	if response_code != 200:
		print("⚠️ Supabase responded with:", response_code)
		return filtered_items

	var json_text = body.get_string_from_utf8()
	var parsed = JSON.parse_string(json_text)

	if typeof(parsed) == TYPE_ARRAY:
		for outfit in parsed:
			filtered_items.append({
				"id": outfit.get("id", 0),
				"name": outfit.get("outfit_name", "Unnamed"),
				"sprite": outfit.get("sprite_url", ""),
				"category": outfit.get("outfit_type", ""),
				"equipped": outfit.get("is_equipped", false),
				"lvl_required": outfit.get("lvl_required", 0)  # <-- default 1 if missing
			})
	else:
		print("❌ Invalid data format from Supabase.")

	return filtered_items

#func load_wardrobe_items(category: String) -> Array:
	#var filtered_items := []
	#var file_path = "res://Assets/wardrobe_items.json"
#
	#if FileAccess.file_exists(file_path):
		#var file = FileAccess.open(file_path, FileAccess.READ)
		#var json_text = file.get_as_text()
		#file.close()
#
		#var result = JSON.parse_string(json_text)
		#if typeof(result) == TYPE_ARRAY:
			#for item in result:
				#if item.has("category") and item["category"] == category:
					#filtered_items.append(item)
#
			## Sort by "id"
			#filtered_items.sort_custom(func(a, b): return a["id"] < b["id"])
		#else:
			#print("❌ Invalid JSON format.")
	#else:
		#print("❌ JSON file not found.")
#
	#return filtered_items

#func _render_single_item():
	#if current_items.is_empty():
		#item.text = "No items found."
		#apply_outfit.text = "Apply Outfit"
		#return
#
	#var current_item = current_items[current_index]
	#item.text = "%s" % [current_item.get("name", "Unnamed")]
	#
	#var category = current_item.get("category", "")
	#var sprite_path = current_item.get("sprite", "")
#
	## Change apply button text based on PetStore
	#var equipped_item = PetStore.equipped_outfits.get(category, null)
	#if equipped_item and equipped_item.get("sprite", "") == sprite_path:
		#apply_outfit.text = "Equipped"
	#else:
		#apply_outfit.text = "Apply Outfit"
#
	#var texture = load(sprite_path) if sprite_path != "" else null  # ✅
	#match category:
		#"Hat":
			#var hat_sprite = PetStore.pet_node.get_node_or_null("PetArea/HatSprite")
			#if hat_sprite:
				#hat_sprite.texture = texture
				#hat_sprite.visible = texture != null
		#"Dress":
			#var dress_sprite = PetStore.pet_node.get_node_or_null("PetArea/ChestSprite")
			#if dress_sprite:
				#dress_sprite.texture = texture
				#dress_sprite.visible = texture != null
		#"Boots":
			#var boots_sprite = PetStore.pet_node.get_node_or_null("PetArea/ArmSprite")
			#if boots_sprite:
				#boots_sprite.texture = texture
				#boots_sprite.visible = texture != null
#
	## Disable buttons at ends
	#prev_btn.disabled = current_index == 0
	#next_btn.disabled = current_index >= current_items.size() - 1

func _render_single_item():
	if current_items.is_empty():
		item.text = "No items found."
		apply_outfit.text = "Apply Outfit"
		return

	var current_item = current_items[current_index]
	var sprite_path = current_item.get("sprite", "")
	var category = current_item.get("category", "")
	var required_level = current_item.get("lvl_required", 1)

	# Update the label
	item.text = "%s" % [current_item.get("name", "Unnamed")]

	# Change apply button text based on whether this item is already equipped
	#var equipped_item = PetStore.equipped_outfits.get(category, null)
	#if equipped_item and equipped_item.get("sprite", "") == sprite_path:
		#apply_outfit.text = "Equipped"
	#else:
		#apply_outfit.text = "Apply Outfit"

	# Preview the selected item on the pet (try-on)
	
	# Show name + locked info
	if player_level < required_level:
		item.text = "Locked"
		apply_outfit.disabled = true
	else:
		item.text = "%s" % [current_item.get("name", "Unnamed")]
		apply_outfit.disabled = false
		
	var texture = load(sprite_path) if sprite_path != "" else null
	match category:
		"Hat":
			var hat_sprite = PetStore.pet_node.get_node_or_null("PetArea/HatSprite")
			if hat_sprite:
				hat_sprite.texture = texture
				hat_sprite.visible = texture != null
				hat_sprite.modulate = Color(1,1,1, 1 if player_level >= required_level else 0.3)
		"Dress":
			var dress_sprite = PetStore.pet_node.get_node_or_null("PetArea/ChestSprite")
			if dress_sprite:
				dress_sprite.texture = texture
				dress_sprite.visible = texture != null
				dress_sprite.modulate = Color(1,1,1, 1 if player_level >= required_level else 0.3)
		"Boots":
			var boots_sprite = PetStore.pet_node.get_node_or_null("PetArea/BootsSprite")
			if boots_sprite:
				boots_sprite.texture = texture
				boots_sprite.visible = texture != null
				boots_sprite.modulate = Color(1,1,1, 1 if player_level >= required_level else 0.3)

	# Disable buttons at ends
	prev_btn.disabled = current_index == 0
	next_btn.disabled = current_index >= current_items.size() - 1

func _on_next_pressed():
	if current_index < current_items.size() - 1:
		current_index += 1
		_render_single_item()

func _on_prev_pressed():
	if current_index > 0:
		current_index -= 1
		_render_single_item()

func _apply_pressed():
	if current_items.is_empty():
		print("⚠️ No item to apply.")
		return

	var selected_item = current_items[current_index]
	var name = selected_item.get("name", "Unnamed")
	var sprite_path = selected_item.get("sprite", "")
	var category = selected_item.get("category", "")
	var texture = load(sprite_path) if sprite_path != "" else null

	# 🔁 Unmark all items in this category first
	for i in range(current_items.size()):
		var item_data = current_items[i]
		if item_data.has("equipped") and item_data["category"] == category:
			item_data["equipped"] = false

		if item_data == selected_item:
			item_data["equipped"] = true

	# ✅ Mark the selected one
	selected_item["equipped"] = true

	# Apply sprite or clear if default
	match category:
		"Hat":
			var hat_sprite = PetStore.pet_node.get_node_or_null("Area2D/HatSprite")
			if hat_sprite:
				hat_sprite.texture = texture
				hat_sprite.visible = texture != null
		"Dress":
			var dress_sprite = PetStore.pet_node.get_node_or_null("Area2D/ChestSprite")
			if dress_sprite:
				dress_sprite.texture = texture
				dress_sprite.visible = texture != null
		"Boots":
			var boots_sprite = PetStore.pet_node.get_node_or_null("Area2D/BootsSprite")
			if boots_sprite:
				boots_sprite.texture = texture
				boots_sprite.visible = texture != null

	# Save to PetStore
	PetStore.equipped_outfits[category] = selected_item
	apply_outfit.text = "Equipped"
	print("You're now wearing:", name)
	_render_single_item()
	save_equipped_outfits()

func load_equipped_outfits() -> void:
	if not Global.User.has("id"):
		print("⚠️ Missing user_id — cannot load equipped outfits.")
		return

	var user_id = str(Global.User["id"])
	var url = "https://rekmhywernuqjshghyvu/rest/v1/user_pet_outfit?user_id=eq." + str(user_id) + "&equipped=eq.true&select=*,pet_outfits(*)"
	
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json",
		"Prefer: return=representation"

	]

	var http := HTTPRequest.new()
	add_child(http)

	var err = http.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		print("❌ Failed to start HTTP request:", err)
		return

	var result = await http.request_completed

	var response_code = result[1]
	var body = result[3]

	if response_code != 200:
		print("⚠️ Supabase request failed with code:", response_code)
		return

	var json_text = body.get_string_from_utf8()
	var parsed = JSON.parse_string(json_text)

	if typeof(parsed) == TYPE_ARRAY:
		for outfit in parsed:
			var category = outfit.get("outfit_type", "")
			PetStore.equipped_outfits[category] = outfit
			var texture = load(outfit.get("sprite_url", ""))
			_set_sprite_for_category(category, texture)
	else:
		print("❌ Invalid Supabase response format")

func save_equipped_outfits():
	
	if not Global.User.has("id"):
		print("⚠️ Missing user_id — cannot save equipped outfits.")
		return

	var user_id = int(Global.User["id"])

	for category in PetStore.equipped_outfits.keys():
		var item = PetStore.equipped_outfits[category]
		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue

		var outfit_id = item.get("id", null)
		if outfit_id == null:
			continue

		var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/user_pet_outfit?on_conflict=user_id,category"
		var headers = [
			"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
			"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
			"Content-Type: application/json",
			"Prefer: resolution=merge-duplicates",
			"Prefer: return=representation"
		]

		var body = JSON.stringify({
			"user_id": user_id,
			"outfit_id": int(outfit_id),
			"category": category,
			"equipped_at": Time.get_datetime_string_from_system()
		})

		var http := HTTPRequest.new()
		add_child(http)

		http.request_completed.connect(_on_request_completed.bind(category, http))
		var err = http.request(url, headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			print("⚠️ HTTP Request failed to start for category:", category, "Error:", err)

# 🔹 This function handles the response from Supabase
func _on_request_completed(result, code, headers, body_data, category, http):
	if code in [200, 201, 204]:
		print("✅ Saved equipped", category, "outfit to Supabase.")
	else:
		print("⚠️ Supabase failed to save", category, ":", code, body_data.get_string_from_utf8())
	http.queue_free()
	
func _set_sprite_for_category(category: String, texture: Texture2D):
	match category:
		"Hat":
			var hat_sprite = PetStore.pet_node.get_node_or_null("PetArea/HatSprite")
			if hat_sprite:
				hat_sprite.texture = texture
				hat_sprite.visible = texture != null
		"Dress":
			var dress_sprite = PetStore.pet_node.get_node_or_null("PetArea/ChestSprite")
			if dress_sprite:
				dress_sprite.texture = texture
				dress_sprite.visible = texture != null
		"Boots":
			var boots_sprite = PetStore.pet_node.get_node_or_null("PetArea/BootsSprite")
			if boots_sprite:
				boots_sprite.texture = texture
				boots_sprite.visible = texture != null
