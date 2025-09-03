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

func _ready():
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
	current_items = load_wardrobe_items("Hat")
	current_index = 0
	_render_single_item()

func show_dress_items():
	open_panel.visible = true
	current_items = load_wardrobe_items("Dress")
	current_index = 0
	_render_single_item()

func show_boot_items():
	open_panel.visible = true
	current_items = load_wardrobe_items("Boots")
	current_index = 0
	_render_single_item()

func back_to_home():
	get_tree().change_scene_to_file("res://Scenes/petmain.tscn")

func load_wardrobe_items(category: String) -> Array:
	var filtered_items := []
	var file_path = "res://Assets/wardrobe_items.json"

	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()

		var result = JSON.parse_string(json_text)
		if typeof(result) == TYPE_ARRAY:
			for item in result:
				if item.has("category") and item["category"] == category:
					filtered_items.append(item)

			# Sort by "id"
			filtered_items.sort_custom(func(a, b): return a["id"] < b["id"])
		else:
			print("❌ Invalid JSON format.")
	else:
		print("❌ JSON file not found.")

	return filtered_items

func _render_single_item():
	if current_items.is_empty():
		item.text = "No items found."
		apply_outfit.text = "Apply Outfit"
		return

	var current_item = current_items[current_index]
	item.text = "%s" % [current_item.get("name", "Unnamed")]

	# Change apply button text based on PetStore
	var equipped_item = PetStore.equipped_outfits.get(current_item.get("category", ""), null)
	if equipped_item and equipped_item.get("name", "") == current_item.get("name", ""):
		apply_outfit.text = "Equipped"
	else:
		apply_outfit.text = "Apply Outfit"

	# Preview the selected item on the pet (try-on)
	var sprite_path = current_item.get("sprite", "")
	var texture = load(sprite_path) if sprite_path != "" else null  # ✅
	var category = current_item.get("category", "")

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

func load_equipped_outfits():
	var path = "user://equipped_outfits.json"
	if not FileAccess.file_exists(path):
		print("ℹ️ No equipped outfit data found yet.")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	file.close()

	var result = JSON.parse_string(text)

	# ✅ Validate the result is a dictionary
	if typeof(result) != TYPE_DICTIONARY:
		print("❌ equipped_outfits.json is not a valid dictionary.")
		return

	for category in result.keys():
		var item = result[category]

		# ✅ Safely check item is valid
		if typeof(item) != TYPE_DICTIONARY:
			print("⚠️ Skipping invalid item for", category, "→ value:", item)
			continue

		PetStore.equipped_outfits[category] = item

		var sprite_path = item["sprite"] if item.has("sprite") else ""
		if sprite_path != "":
			var texture = load(sprite_path)
			match category:
				"Hat":
					var hat_sprite = PetStore.pet_node.get_node_or_null("PetArea/HatSprite")
					if hat_sprite:
						hat_sprite.texture = texture
				"Dress":
					var dress_sprite = PetStore.pet_node.get_node_or_null("PetArea/ChestSprite")
					if dress_sprite:
						dress_sprite.texture = texture
				"Boots":
					var boots_sprite = PetStore.pet_node.get_node_or_null("PetArea/BootsSprite")
					if boots_sprite:
						boots_sprite.texture = texture

func save_equipped_outfits():
	var save_data = {}
	for key in PetStore.equipped_outfits.keys():
		var item = PetStore.equipped_outfits[key]

		if item == null or typeof(item) != TYPE_DICTIONARY:
			continue

		save_data[key] = {
			"name": item.get("name", ""),
			"sprite": item.get("sprite", ""),
			"category": key
		}

	var file = FileAccess.open("user://equipped_outfits.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
