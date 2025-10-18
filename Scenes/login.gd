extends Control

@onready var login_window = $"Login_window"
@onready var username_input = $"Login_window/register/username_input"
@onready var password_input = $"Login_window/register/password_input"
@onready var submit_btn = $"Login_window/register/HBoxContainer/submit_btn"

@onready var go_to_registration = $"Login_window/register/register_btn"

@onready var http = HTTPRequest.new()

@onready var toast_notif = $"toast_notification"

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
	add_child(http)  # make sure HTTPRequest is in the tree
	
	var auth_data = load_login_data()
	print("Loaded auth data: ", auth_data)
	if auth_data.has("username") and auth_data.has("id"):
		print("🔐 Auto-login as:", auth_data["username"])
		Global.User = auth_data
		_go_to_dashboard()
		return

	http.request_completed.connect(_on_HTTPRequest_request_completed)
	submit_btn.pressed.connect(_on_submit_pressed)
	go_to_registration.pressed.connect(_go_register)
	
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


func _go_register():
	
	# Switch to loading screen and tell it where to go
			var loading_scene = load("res://Scenes/loading_screen.tscn").instantiate()
			loading_scene.next_scene_path = "res://Scenes/registration.tscn"
			loading_scene.wait_time = 1.0   # you can tweak per case
			
			get_tree().root.add_child(loading_scene)
			get_tree().current_scene.queue_free()  # remove old scene

# When login is pressed
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
	var url = "http://192.168.254.111/zenpet/login.php"  # adjust path
	
	# Convert dictionary to URL-encoded string
	var form_data = "username=%s&password=%s" % [username, password]
	
	# Set proper headers
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	
	# Send POST request
	http.request(url, headers, HTTPClient.METHOD_POST, form_data)


# Handle HTTP responses
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("HTTP Response Code:", response_code)
	var response_text = body.get_string_from_utf8()
	if response_code == 200:
		var data = JSON.parse_string(response_text)
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			var user = data[0]
			show_message("Successful!")
			Global.User = user
			save_login_data(user)
			
			var loading_scene = load("res://Scenes/loading_screen.tscn").instantiate()
			loading_scene.next_scene_path = "res://Scenes/dashboard.tscn"
			loading_scene.wait_time = 1.0
			get_tree().root.add_child(loading_scene)
			get_tree().current_scene.queue_free()
		else:
			show_message("Invalid Credentials!")
	else:
		show_message("Server connection failed!")

func save_login_data(user: Dictionary) -> void:
	var file = FileAccess.open("user://auth.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user))
		file.close()

func _go_to_dashboard():
	get_tree().change_scene_to_file("res://Scenes/dashboard.tscn")
