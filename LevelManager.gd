extends Node

# --- Player Data ---
var level: int = 1
var exp: float = 0.0
var exp_to_next_level: float = 100.0

# --- Optional UI elements (for automatic update) ---
var exp_bar: ProgressBar
var level_label: Label

# --- Backend URLs ---
const BASE_URL := "http://192.168.254.111/zenpet"
const GET_URL := BASE_URL + "/get_user_level.php"
const UPDATE_URL := BASE_URL + "/update_exp.php"

var http_request: HTTPRequest

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_response)
	print("✅ LevelManager loaded")

# --- Load user data ---
func get_user_level(user_id: int):
	if user_id <= 0:
		push_warning("Invalid user ID")
		return

	var url = "%s?user_id=%d" % [GET_URL, user_id]
	http_request.request(url, [], HTTPClient.METHOD_GET)

func _on_http_response(result, response_code, headers, body):
	if response_code != 200:
		print("❌ HTTP Error:", response_code)
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		print("⚠️ Invalid response format:", data)
		return

	level = int(data.get("level", 1))
	exp = float(data.get("exp", 0))
	_update_ui()
	print("✅ Synced LevelManager → Level: %d | Exp: %.2f" % [level, exp])

# --- Update exp and sync with backend ---
func add_exp(amount: float, user_id: int):
	exp += amount
	if exp >= exp_to_next_level:
		exp -= exp_to_next_level
		level += 1
		print("🎉 Level up! You are now Level %d" % level)

	_update_ui()
	_sync_exp_to_server(user_id)

# --- Sync changes back to server ---
func _sync_exp_to_server(user_id: int):
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"user_id": user_id,
		"level": level,
		"exp": exp
	})

	http_request.request(UPDATE_URL, headers, HTTPClient.METHOD_POST, body)

# --- Optional: Attach UI for auto-updates ---
func attach_ui(exp_bar_node: ProgressBar, level_label_node: Label = null):
	exp_bar = exp_bar_node
	level_label = level_label_node
	_update_ui()

func _update_ui():
	if exp_bar:
		exp_bar.max_value = exp_to_next_level
		var tween = create_tween()
		tween.tween_property(exp_bar, "value", exp, 0.4)
	if level_label:
		level_label.text = "Lv. %d" % level
