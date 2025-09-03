extends Control

@onready var hat = $"Area2D/HatSprite"

func apply_hat(sprite_path: String) -> void:
	if sprite_path == "":
		print("⚠️ No sprite path provided.")
		return

	if not hat:
		print("❌ 'HatSprite' node not found.")
		return

	var texture = load(sprite_path)
	if texture:
		hat.texture = texture
		print("✅ Hat applied!")
	else:
		print("❌ Failed to load texture at:", sprite_path)
