extends Control

@onready var smiley = preload("res://Scenes/smiley.tscn")
@onready var level_complete = preload("res://Scenes/minigame_complete.tscn")
@onready var smiley_left = $Label4
var smileys_clicked = 0
var max_smileys := 10

func _ready():
	randomize()
	_spawn_clickable_smileys()

func _spawn_clickable_smileys():
	smiley_left.text = "Smileys Left: " + str(max_smileys - smileys_clicked)

	# 🎉 Show level complete when finished
	if smileys_clicked >= max_smileys:
		_show_level_complete()
		return

	var smiley_obj = smiley.instantiate()
	var viewport_size = get_viewport_rect().size
	var x = randi_range(64, int(viewport_size.x - 64))
	var y = randi_range(64, int(viewport_size.y - 64))
	smiley_obj.position = Vector2(x, y)
	Global.play_sound(load("res://Audio/woosh-mark_diangelo-4778593.mp3"))
	add_child(smiley_obj)

	# ✨ Spawn tween effect
	smiley_obj.scale = Vector2(0, 0)
	var spawn_tween = create_tween()
	spawn_tween.set_trans(Tween.TRANS_BACK)
	spawn_tween.set_ease(Tween.EASE_OUT)
	spawn_tween.tween_property(smiley_obj, "scale", Vector2(1, 1), 0.2)

	# 🖱️ Handle clicks
	smiley_obj.clicked.connect(func():
		
		Global.play_sound(load("res://Audio/apple-pay-sound.mp3"))
		smileys_clicked += 1
		smiley_left.text = "Smileys Left: " + str(max_smileys - smileys_clicked)
		print("Smiley clicked! Total:", smileys_clicked)

		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(smiley_obj, "scale", Vector2(0, 0), 0.3)
		tween.parallel().tween_property(smiley_obj, "rotation", deg_to_rad(360), 0.3)

		await tween.finished
		smiley_obj.queue_free()
		await get_tree().create_timer(0.1).timeout
		_spawn_clickable_smileys()
	)

func _show_level_complete():
	var complete_obj = level_complete.instantiate()
	add_child(complete_obj)

	# 🧭 Center the object in the screen
	var viewport_size = get_viewport_rect().size
	var obj_size = complete_obj.get_rect().size  # only works if it's a Control node
	complete_obj.position = (viewport_size - obj_size) / 2

	# ✨ Fade and scale in
	complete_obj.modulate.a = 0
	complete_obj.scale = Vector2(0.5, 0.5)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(complete_obj, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(complete_obj, "scale", Vector2(1, 1), 0.5)
