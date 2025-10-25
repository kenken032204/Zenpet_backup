# ========================================
# zenbody.gd - Level Selection Menu
# ========================================
extends Control

const LEVELS_API_URL := "http://192.168.254.111/zenpet/get_zenbody_levels.php"
const USER_LEVEL_API_URL := "http://192.168.254.111/zenpet/get_user_level.php"

@onready var http_request_levels: HTTPRequest = $HTTPRequestLevels
@onready var http_request_user: HTTPRequest = $HTTPRequestUser
@onready var level_list: GridContainer = $"ScrollContainer/Levellist"
@onready var level_label: Label = $"Control/level_label"
@onready var exp_bar: ProgressBar = $"Control/ProgressBar"
@onready var back_btn = $"back_button"

var user_level: int = 0
var user_id: int = 0

func _ready() -> void:
	#print("📡 Initializing ZenBody Levels...")
	
	http_request_user.request_completed.connect(_on_user_level_response)
	http_request_levels.request_completed.connect(_on_levels_response)
	
	if back_btn:
		back_btn.pressed.connect(_back_to_dashboard)
	
	user_id = int(Global.User.get("id", 0))
	if user_id <= 0:
		push_error("❌ Invalid user ID.")
		return
	
	var url = "%s?user_id=%d" % [USER_LEVEL_API_URL, user_id]
	#print("📤 Requesting user level from: ", url)
	http_request_user.request(url)

func _on_user_level_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_text = body.get_string_from_utf8()
	#print("📥 User level response [%d]: %s" % [response_code, response_text])
	
	if response_code != 200:
		push_error("❌ HTTP Error when getting user level: %d" % response_code)
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		push_error("❌ Failed to parse JSON")
		return
	
	if typeof(json) == TYPE_DICTIONARY:
		if json.has("status") and json["status"] == "success":
			user_level = int(json["data"].get("level", 0))
			level_label.text = "Level %d" % user_level
			exp_bar.value = float(json["data"].get("exp", 0))
		elif json.has("level"):
			user_level = int(json.get("level", 0))
			level_label.text = "Level %d" % user_level
			exp_bar.value = float(json.get("exp", 0))
	
	#print("✅ User level set to:", user_level)
	_fetch_levels()

func _fetch_levels() -> void:
	#print("📤 Requesting ZenBody levels from: ", LEVELS_API_URL)
	http_request_levels.request(LEVELS_API_URL)

func _on_levels_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var response_text = body.get_string_from_utf8()
	#print("📥 Levels response [%d]: %s" % [response_code, response_text])
	
	if response_code != 200:
		push_error("❌ HTTP Error when getting levels: %d" % response_code)
		return

	var json = JSON.parse_string(response_text)
	if json == null:
		push_error("❌ Failed to parse levels JSON")
		return
	
	var levels_array: Array = []
	
	if typeof(json) == TYPE_DICTIONARY:
		if json.has("status") and json["status"] == "success":
			levels_array = json.get("data", [])
		elif json.has("levels"):
			levels_array = json["levels"]
	elif typeof(json) == TYPE_ARRAY:
		levels_array = json
	
	if levels_array.size() == 0:
		push_warning("⚠️ No levels found")
		return
	
	#print("✅ Creating buttons for %d levels" % levels_array.size())
	_create_level_buttons(levels_array)

func _create_level_buttons(levels: Array) -> void:
	for child in level_list.get_children():
		child.queue_free()

	for level_data in levels:
		if typeof(level_data) != TYPE_DICTIONARY:
			continue
		
		var btn: Button = Button.new()
		var level_name = level_data.get("level_name", "Unknown Level")
		var description = level_data.get("description", "")
		var exp_gain = level_data.get("exp_gain", 0)
		var duration = level_data.get("duration_seconds", 0)
		
		btn.text = "%s\n%s" % [level_name, description]
		btn.tooltip_text = "EXP: %s | Duration: %ss" % [exp_gain, duration]
		btn.custom_minimum_size = Vector2(300, 80)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_stylebox_override("normal", _create_stylebox(Color("#2c3e50")))
		btn.add_theme_stylebox_override("hover", _create_stylebox(Color("#3498db")))
		btn.add_theme_stylebox_override("pressed", _create_stylebox(Color("#2980b9")))

		var level_num: int = int(level_data.get("level_number", 1))
		btn.set_meta("level_data", level_data)

		if level_num > user_level:
			btn.disabled = true
			btn.add_theme_stylebox_override("disabled", _create_stylebox(Color("#7f8c8d")))
			btn.text += "\n🔒 Locked"

		btn.pressed.connect(_on_level_selected.bind(btn))
		level_list.add_child(btn)

func _on_level_selected(btn: Button) -> void:
	var level_data: Dictionary = btn.get_meta("level_data")
	
	#print("🧘 Selected Level: ", level_data.get("level_name", "Unknown"))
	
	# ✅ Store level data globally
	Global.current_zenbody_level = level_data
	
	# Load the level template scene
	var scene = load("res://Scenes/zenbody_level_1.tscn") as PackedScene
	if scene:
		get_tree().change_scene_to_packed(scene)
	else:
		push_error("❌ Failed to load zenbody_level_1.tscn")

func _create_stylebox(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(3)
	sb.border_color = Color("#ecf0f1")
	return sb

func _back_to_dashboard() -> void:
	var scene = load("res://Scenes/dashboard.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
