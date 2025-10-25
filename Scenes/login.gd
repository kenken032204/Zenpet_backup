extends Control

@onready var login_window = $"Login_window"
@onready var username_input = $"Login_window/register/username_input"
@onready var password_input = $"Login_window/register/password_input"
@onready var submit_btn = $"Login_window/register/HBoxContainer/submit_btn"
@onready var go_to_registration = $"Login_window/register/register_btn"
@onready var toast_notif = $"toast_notification"

@onready var http = HTTPRequest.new()

func show_message(text: String, duration: float = 2.0):
	toast_notif.text = text
	toast_notif.modulate.a = 0.0
	toast_notif.visible = true

	var tween = create_tween()
	tween.tween_property(toast_notif, "modulate:a", 1.0, 0.3) # fade in
	tween.tween_interval(duration)
	tween.tween_property(toast_notif, "modulate:a", 0.0, 0.3) # fade out
	tween.tween_callback(Callable(toast_notif, "hide"))

func _ready():
	add_child(http)
	
	Global.add_button_effects(submit_btn)
	Global.add_button_effects(go_to_registration)
	
	http.request_completed.connect(_on_HTTPRequest_request_completed)
	submit_btn.pressed.connect(_on_submit_pressed)
	go_to_registration.pressed.connect(_go_register)

	var auth_data = load_login_data()
	print("Loaded auth data: ", auth_data)
	
	if auth_data.has("username") and auth_data.has("id"):
		print("🔐 Auto-login as:", auth_data["username"])
		Global.User = auth_data
		await _sync_user_level_from_server(int(auth_data["id"]))
		save_login_data(Global.User)
		_go_to_dashboard()
		return


# =========================
# 🔁 SERVER COMMUNICATION
# =========================

func _on_submit_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username == "":
		show_message("Input Username, Please?")
		return
	elif password == "":
		show_message("Don't leave password alone :<")
		return

	check_user(username, password)

func check_user(username: String, password: String):
	var url = "http://192.168.254.111/zenpet/login.php"
	var form_data = "username=%s&password=%s" % [username, password]
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	http.request(url, headers, HTTPClient.METHOD_POST, form_data)


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("HTTP Response Code:", response_code)
	var response_text = body.get_string_from_utf8()

	if response_code == 200:
		var data = JSON.parse_string(response_text)
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			var user = data[0]
			show_message("Successful!")
			Global.User = user
			await _sync_user_level_from_server(int(user["id"]))
			save_login_data(Global.User)
			
			var loading_scene = load("res://Scenes/loading_screen.tscn").instantiate()
			loading_scene.next_scene_path = "res://Scenes/dashboard.tscn"
			loading_scene.wait_time = 1.0
			get_tree().root.add_child(loading_scene)
			get_tree().current_scene.queue_free()
		else:
			show_message("Invalid Credentials!")
	else:
		show_message("Server connection failed!")


# =========================
# 🧩 LEVEL / EXP SYNC
# =========================

func _sync_user_level_from_server(user_id: int) -> void:
	var url: String = "http://192.168.254.111/zenpet/get_user_level.php?user_id=%d" % user_id
	print("🔄 Syncing level and EXP from:", url)

	var req: HTTPRequest = HTTPRequest.new()
	add_child(req)

	# start the request
	var err: Error = req.request(url)
	if err != OK:
		print("❌ Request error:", err)
		req.queue_free()
		return

	# wait for the signal and receive the 4-tuple
	var result = await req.request_completed
	# result is an Array: [result_enum, response_code, headers, body]
	var response_code: int = int(result[1])
	var body: PackedByteArray = result[3]

	# Explicitly type the text so the compiler is happy
	var text: String = body.get_string_from_utf8()
	# parse and use
	if response_code == 200:
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			Global.User["level"] = int(parsed.get("level", 1))
			Global.User["exp"] = float(parsed.get("exp", 0))
			print("✅ Synced User Level:", Global.User["level"], "| EXP:", Global.User["exp"])
		else:
			print("⚠️ Invalid JSON response from level sync:", text)
	else:
		print("❌ Failed to sync user level | Code:", response_code, "Body:", text)

	req.queue_free()

# =========================
# 💾 LOCAL AUTH STORAGE
# =========================

func load_login_data() -> Dictionary:
	if not FileAccess.file_exists("user://auth.json"):
		return {}
	var file = FileAccess.open("user://auth.json", FileAccess.READ)
	if not file:
		return {}
	var content = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}

func save_login_data(user: Dictionary) -> void:
	var file = FileAccess.open("user://auth.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user))
		file.close()
		print("💾 Auth data saved locally.")

# =========================
# 🌐 NAVIGATION
# =========================

func _go_register():
	var loading_scene = load("res://Scenes/loading_screen.tscn").instantiate()
	loading_scene.next_scene_path = "res://Scenes/registration.tscn"
	loading_scene.wait_time = 1.0
	get_tree().root.add_child(loading_scene)
	get_tree().current_scene.queue_free()

func _go_to_dashboard():
	get_tree().change_scene_to_file("res://Scenes/dashboard.tscn")
