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
	http.request_completed.connect(_on_HTTPRequest_request_completed)
	submit_btn.pressed.connect(_on_submit_pressed)
	go_to_registration.pressed.connect(_go_register)

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

# Query Supabase users table (only username)
func check_user(user_name: String, password: String):
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/users"
	url += "?select=id,username&username=eq." + user_name + "&password=eq." + password
	
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY"
	]
	http.request(url, headers, HTTPClient.METHOD_GET)

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
			
			# Switch to loading screen and tell it where to go
			var loading_scene = load("res://Scenes/loading_screen.tscn").instantiate()
			loading_scene.next_scene_path = "res://Scenes/dashboard.tscn"
			loading_scene.wait_time = 1.0   # you can tweak per case
			
			get_tree().root.add_child(loading_scene)
			get_tree().current_scene.queue_free()  # remove old scene
			
		else:
			show_message("Invalid Credentials!")
	else:
		print("⚠️ Error contacting server")
