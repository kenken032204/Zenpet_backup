extends Node

# Preload your info card scene
const InfoCardScene = preload("res://Scenes/information_card.tscn")

# Call this function to show an info card anywhere
func show_info_card(title_text: String, content_text: String, parent_node: Node) -> void:
	var card_instance = InfoCardScene.instantiate() as Control
	parent_node.add_child(card_instance)

	# Set title and content
	card_instance.title.text = title_text
	card_instance.content.text = content_text

	# Play animation
	if card_instance.animation:
		card_instance.animation.play("pop")

	# Connect confirm button to auto-remove the card
	if card_instance.confirm_btn:
		card_instance.confirm_btn.pressed.connect(func():
			card_instance.queue_free()
		)
		
