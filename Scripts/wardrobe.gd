extends Control

var previously_equipped: Dictionary = {
	"Hat": null,
	"Dress": null,
	"Boots": null
}

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

var player_level: int = 0

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
		load_equipped_outfits()

func _on_accessory_toggled(button_pressed: bool, category: String):
	if button_pressed:
		# Save currently displayed outfit before switching category
		if current_items.size() > 0:
			var current_item = current_items[current_index]
			var current_category = current_item.get("category", "")
			if current_category != "":
				previously_equipped[current_category] = current_item
		
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
		_restore_all_equipped_outfits()
		open_panel.visible = false
		
func show_hat_items():
	open_panel.visible = true
	current_items = await load_wardrobe_items("Hat")
	current_index = 0
	_render_single_item()

func show_dress_items():
	open_panel.visible = true
	current_items = await load_wardrobe_items("Dress")
	current_index = 0
	_render_single_item()

func show_boot_items():
	open_panel.visible = true
	current_items = await load_wardrobe_items("Boots")
	current_index = 0
	_render_single_item()

func back_to_home():
	get_tree().change_scene_to_file("res://Scenes/petmain.tscn")

func load_wardrobe_items(category: String) -> Array:
	var filtered_items: Array = []

	var url = "http://192.168.254.111/zenpet/get_wardrobe_items.php?category=%s" % category
	
	var http := HTTPRequest.new()
	add_child(http)

	var err = http.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		print("Request failed to start.")
		return filtered_items

	# Wait for completion signal
	var result = await http.request_completed

	var response_code = result[1]
	var body = result[3]

	if response_code != 200:
		print("HTTP request failed with code:", response_code)
		return filtered_items

	var json_text = body.get_string_from_utf8()
	print("Raw response: ", json_text)  # Debug: see what we're getting
	
	var parsed = JSON.parse_string(json_text)

	if parsed == null:
		print("Failed to parse JSON")
		return filtered_items

	# Check if the response has the nested structure
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("items"):
		# New format with debug info
		var items_array = parsed.get("items", [])
		if typeof(items_array) == TYPE_ARRAY:
			for outfit in items_array:
				filtered_items.append({
					"id": outfit.get("id", 0),
					"name": outfit.get("outfit_name", "Unnamed"),
					"sprite": outfit.get("sprite_url", ""),
					"category": outfit.get("outfit_type", ""),
					"equipped": outfit.get("is_equipped", false),
					"lvl_required": outfit.get("lvl_required", 0)
				})
	elif typeof(parsed) == TYPE_ARRAY:
		# Old format (simple array)
		for outfit in parsed:
			filtered_items.append({
				"id": outfit.get("id", 0),
				"name": outfit.get("outfit_name", "Unnamed"),
				"sprite": outfit.get("sprite_url", ""),
				"category": outfit.get("outfit_type", ""),
				"equipped": outfit.get("is_equipped", false),
				"lvl_required": outfit.get("lvl_required", 0)
			})
	else:
		print("Invalid data format from server. Got type: ", typeof(parsed))
		if typeof(parsed) == TYPE_DICTIONARY:
			print("Debug info from server: ", parsed.get("debug", {}))

	return filtered_items
	
func _render_single_item():
	if current_items.is_empty():
		item.text = "No items found."
		apply_outfit.text = "Apply Outfit"
		return

	var current_item = current_items[current_index]
	var sprite_path = current_item.get("sprite", "")
	var category = current_item.get("category", "")
	var required_level = current_item.get("lvl_required", 1)

	item.text = "%s" % [current_item.get("name", "Unnamed")]

	# Show name + locked info
	if player_level < required_level:
		item.text = "Locked"
		apply_outfit.disabled = true
	else:
		item.text = "%s" % [current_item.get("name", "Unnamed")]
		apply_outfit.disabled = false
	
	# Check if this outfit is the one currently equipped in PetStore
	var equipped_outfit = PetStore.equipped_outfits.get(category, {})
	var is_this_equipped = (equipped_outfit and equipped_outfit.get("id") == current_item.get("id"))
	if is_this_equipped:
		apply_outfit.text = "Equipped"
	else:
		apply_outfit.text = "Apply Outfit"
		
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
			var boots_sprite = PetStore.pet_node.get_node_or_null("PetArea/ArmSprite")
			if boots_sprite:
				boots_sprite.texture = texture
				boots_sprite.visible = texture != null
				boots_sprite.modulate = Color(1,1,1, 1 if player_level >= required_level else 0.3)

	prev_btn.disabled = current_index == 0
	next_btn.disabled = current_index >= current_items.size() - 1
	
func _restore_all_equipped_outfits():
	for category in PetStore.equipped_outfits.keys():
		var equipped_outfit = PetStore.equipped_outfits[category]
		if equipped_outfit and typeof(equipped_outfit) == TYPE_DICTIONARY:
			var sprite_url = equipped_outfit.get("sprite_url", "")
			if sprite_url and sprite_url != "":
				var texture = load(sprite_url)
				if texture:
					_set_sprite_for_category(category, texture)
					
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
		print("No item to apply.")
		return

	var selected_item = current_items[current_index]
	var name = selected_item.get("name", "Unnamed")
	var sprite_path = selected_item.get("sprite", "")
	var category = selected_item.get("category", "")
	var outfit_id = selected_item.get("id", 0)
	var texture = load(sprite_path) if sprite_path != "" else null

	# Mark the selected one as equipped
	selected_item["equipped"] = true

	# Apply sprite
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
			var boots_sprite = PetStore.pet_node.get_node_or_null("PetArea/ArmSprite")
			if boots_sprite:
				boots_sprite.texture = texture
				boots_sprite.visible = texture != null

	PetStore.equipped_outfits[category] = selected_item
	apply_outfit.text = "Equipped"
	print("You're now wearing:", name)
	_render_single_item()
	save_equipped_outfits(outfit_id, category)

func load_equipped_outfits() -> void:
	if not Global.User.has("id"):
		print("Missing user_id — cannot load equipped outfits.")
		return

	var user_id = int(Global.User["id"])
	var url = "http://192.168.254.111/zenpet/get_equipped_outfits.php?user_id=%d" % user_id
	
	var http := HTTPRequest.new()
	add_child(http)

	var err = http.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		print("Failed to start HTTP request:", err)
		return

	var result = await http.request_completed

	var response_code = result[1]
	var body = result[3]

	if response_code != 200:
		print("Server request failed with code:", response_code)
		return

	var json_text = body.get_string_from_utf8()
	print("Equipped outfits response: ", json_text)  # Debug
	
	var parsed = JSON.parse_string(json_text)

	if parsed == null:
		print("Failed to parse equipped outfits JSON")
		return

	# Handle nested response format
	var outfits_array = parsed
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("items"):
		outfits_array = parsed.get("items", [])
	
	if typeof(outfits_array) != TYPE_ARRAY:
		print("Invalid server response format. Got type: ", typeof(outfits_array))
		if typeof(parsed) == TYPE_DICTIONARY:
			print("Debug info: ", parsed.get("debug", {}))
		return

	for outfit in outfits_array:
		var category = outfit.get("category", "")
		var sprite_url = outfit.get("sprite_url", "")
		
		if category == "" or not sprite_url or sprite_url == "":
			continue
			
		var texture = load(sprite_url) if (sprite_url and sprite_url != "") else null
		if texture:
			PetStore.equipped_outfits[category] = outfit
			_set_sprite_for_category(category, texture)
		else:
			print("Failed to load texture: ", sprite_url)
			
func save_equipped_outfits(outfit_id: int, category: String):
	if not Global.User.has("id"):
		print("Missing user_id — cannot save equipped outfits.")
		return

	var user_id = int(Global.User["id"])

	var url = "http://192.168.254.111/zenpet/save_equipped_outfit.php"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"user_id": user_id,
		"outfit_id": outfit_id,
		"category": category
	})

	var http := HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(_on_save_completed.bind(http))
	var err = http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("HTTP Request failed to start for category:", category, "Error:", err)

func _on_save_completed(result, code, headers, body_data, http):
	if code in [200, 201]:
		print("Equipped outfit saved successfully.")
	else:
		print("Failed to save equipped outfit:", code, body_data.get_string_from_utf8())
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
			var boots_sprite = PetStore.pet_node.get_node_or_null("PetArea/ArmSprite")
			if boots_sprite:
				boots_sprite.texture = texture
				boots_sprite.visible = texture != null
