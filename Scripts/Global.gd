extends Node

var User = {}
	
# Pet Status
var energy: float = 100.0
var cleanliness: float = 100.0

var is_clean_done: bool = false
var is_sleep_done: bool = false

# Flags
var is_sleepy := false
var little_sleepy := false
var little_dirty := false
var is_dirty := false

# 🔹 Call this to update flags
func complete_clean():
	is_clean_done = true
	_check_status_bonus()

func complete_sleep():
	is_sleep_done = true
	_check_status_bonus()

# 🔹 Check if both conditions are met
func _check_status_bonus():
	if is_clean_done and is_sleep_done and energy >= 80 and cleanliness >= 80:
		print("✨ Pet feels amazing! Full energy & cleanliness.")
		# Reset flags if you only want this once per cycle:
		is_clean_done = false
		is_sleep_done = false

# Called every frame if you want
func decay_stats(delta):
	energy = clamp(energy - delta * 0.5, 0, 100)
	cleanliness = clamp(cleanliness - delta * 0.3, 0, 100)

	is_sleepy = energy <= 0
	is_dirty = cleanliness <= 0

	little_sleepy = energy < 50 and energy > 0
	little_dirty = cleanliness < 50 and cleanliness > 0

func play_sound(stream: AudioStream, volume_db := 0.0, is_2d := false, position := Vector2.ZERO):
	var player = AudioStreamPlayer2D.new() if is_2d else AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db

	if is_2d:
		player.position = position

	add_child(player)  # Add to current node tree
	player.play()
	
	# Clean up after playing
	player.finished.connect(player.queue_free)

func save_stats():
	var data = {
		"energy": energy,
		"cleanliness": cleanliness
	}
	var file = FileAccess.open("user://pet_stats.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	
func load_stats():
	var path = "user://pet_stats.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(data) == TYPE_DICTIONARY:
			energy = data.get("energy", 100)
			cleanliness = data.get("cleanliness", 100)
	else:
		energy = 100
		cleanliness = 100
