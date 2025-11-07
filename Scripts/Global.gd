extends Node

const SERVER_IP = "192.168.254.119"
const BASE_URL = "http://%s/zenpet/" % SERVER_IP

const SERVER_DOWN_SCENE = "res://Scenes/server_down.tscn"
const LOGIN_SCENE = "res://Scenes/login.tscn"

var User = {}
var current_zenbody_level: Dictionary = {}

var total_exp: int = 0

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

# Connection settings
var _is_checking_connection: bool = false
var _check_interval: float = 5.0 # seconds between checks
var _connection_fast_mode: bool = true

# ============================
# 🔹 SERVER CONNECTION CHECK
# ============================
func _ready():
	print("🌐 Checking server connectivity...")
	check_server_connection()
	# Start background monitoring
	_start_connection_monitoring()


func check_server_connection() -> void:
	if _is_checking_connection:
		return
	_is_checking_connection = true

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_server_check_completed.bind(http_request))

	# Shorter timeout if fast mode is enabled
	http_request.timeout = 2.0 if _connection_fast_mode else 5.0

	var err = http_request.request(BASE_URL)
	if err != OK:
		print("❌ HTTPRequest start failed with error:", err)
		_goto_server_down()
	_is_checking_connection = false

func _on_server_check_completed(result, response_code, headers, body, http_request):
	http_request.queue_free()
	_is_checking_connection = false

	if result == OK and response_code in [200, 201]:
		print("✅ Server is online!")
		_connection_fast_mode = true

		var root = get_tree().current_scene
		if root:
			var down_node = root.get_node_or_null("ServerDown")
			if down_node:
				print("🧹 Removing server_down overlay (server restored).")
				down_node.queue_free()


	else:
		print("⚠️ Server not reachable (response: %s)" % response_code)
		_connection_fast_mode = false
		_goto_server_down()
		
func _goto_server_down() -> void:
	await get_tree().process_frame  # ✅ wait 1 frame so current_scene is available
	var root = get_tree().current_scene
	if not root:
		print("⚠️ No current scene to attach server_down overlay, retrying...")
		await get_tree().create_timer(0.5).timeout
		root = get_tree().current_scene
		if not root:
			print("❌ Still no scene, giving up.")
			return

	if not root.get_node_or_null("ServerDown"):
		var down_scene = load(SERVER_DOWN_SCENE).instantiate()
		down_scene.name = "ServerDown"
		root.add_child(down_scene)
		print("🚨 Server down overlay added to current scene.")


# 🔄 Background monitor to keep checking server every few seconds
func _start_connection_monitoring() -> void:
	# Create a timer that periodically checks the server
	var timer := Timer.new()
	timer.wait_time = _check_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(func():
		print("🔍 Periodic server check...")
		check_server_connection()
	)
	add_child(timer)


# ============================
# 🔹 PET STATS + FUNCTIONS
# ============================
func complete_clean():
	is_clean_done = true
	_check_status_bonus()

func complete_sleep():
	is_sleep_done = true
	_check_status_bonus()

func _check_status_bonus():
	if is_clean_done and is_sleep_done and energy >= 80 and cleanliness >= 80:
		print("✨ Pet feels amazing! Full energy & cleanliness.")
		is_clean_done = false
		is_sleep_done = false

func decay_stats(delta):
	energy = clamp(energy - delta * 0.5, 0, 100)
	cleanliness = clamp(cleanliness - delta * 0.3, 0, 100)

	is_sleepy = energy <= 0
	is_dirty = cleanliness <= 0
	little_sleepy = energy < 50 and energy > 0
	little_dirty = cleanliness < 50 and cleanliness > 0


# ============================
# 🔹 SOUND FUNCTION
# ============================
func play_sound(stream: AudioStream, volume_db := 0.0, is_2d := false, position := Vector2.ZERO):
	var player = AudioStreamPlayer2D.new() if is_2d else AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	if is_2d:
		player.position = position
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


# ============================
# 🔹 SAVE / LOAD STATS
# ============================
func save_stats():
	var data = {"energy": energy, "cleanliness": cleanliness}
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


# ============================
# 🔹 UI BUTTON EFFECTS
# ============================
func add_button_effects(button: Button) -> void:
	if not button:
		return
	
	button.pivot_offset = button.size / 2
	button.resized.connect(func(): button.pivot_offset = button.size / 2)

	if not button.is_connected("mouse_entered", Callable(self, "_on_button_hover")):
		button.mouse_entered.connect(_on_button_hover.bind(button))
	if not button.is_connected("mouse_exited", Callable(self, "_on_button_exit")):
		button.mouse_exited.connect(_on_button_exit.bind(button))
	if not button.is_connected("pressed", Callable(self, "_on_button_pressed")):
		button.pressed.connect(_on_button_pressed.bind(button))
	if not button.is_connected("button_up", Callable(self, "_on_button_released")):
		button.button_up.connect(_on_button_released.bind(button))

func _on_button_hover(button: Button) -> void:
	var tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_button_exit(button: Button) -> void:
	var tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func _on_button_pressed(button: Button) -> void:
	var tween = button.create_tween()
	tween.tween_property(button, "modulate", Color(0.85, 0.85, 0.85, 0.5), 0.05)
	var click_sound: AudioStream = preload("res://Audio/bubble_iMw0wu6.mp3")
	play_sound(click_sound, -5) 

func _on_button_released(button: Button) -> void:
	var tween = button.create_tween()
	tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.05)
