extends Control

var current_request = ""

@onready var animation = $AnimationPlayer
@onready var center_container = $CenterContainer
@onready var register_window = $"Register_Window"
@onready var fun_loading_info = $"fun_loading_info"
@onready var http = HTTPRequest.new()

@onready var submit_btn = $"Register_Window/register/HBoxContainer/submit_btn"
@onready var username_input = $"Register_Window/register/username_input"
@onready var password_input = $"Register_Window/register/password_input"
@onready var conf_pass_input = $"Register_Window/register/confirm_pass_input"

@onready var go_to_login = $"Register_Window/register/login_btn"

@onready var toast_notif = $"toast_notification"

var infos_array = ["Buying Frisbee for Pet", "Feeding your Pet", "Taking a Walk"]

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
	
	Global.add_button_effects(go_to_login)
	Global.add_button_effects(submit_btn)
	
	http.request_completed.connect(_on_HTTPRequest_request_completed)
	go_to_login.pressed.connect(_go_login)
	submit_btn.pressed.connect(_on_submit_pressed)
	
	# Show loading screen
	center_container.visible = true
	register_window.visible = false
	fun_loading_info.visible = true
	animation.play("loading")

	# Start cycling info messages while loading
	start_info_cycle()

	# Wait 1 second then switch to register form
	await get_tree().create_timer(1.0).timeout
	show_register_form()

func _go_login():
	
	# Switch to loading screen and tell it where to go
			var loading_scene = load("res://Scenes/loading_screen.tscn").instantiate()
			loading_scene.next_scene_path = "res://Scenes/login.tscn"
			loading_scene.wait_time = 1.0   # you can tweak per case
			
			get_tree().root.add_child(loading_scene)
			get_tree().current_scene.queue_free()  # remove old scene
			
func _on_submit_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var conf_pass = conf_pass_input.text.strip_edges()
	
	if username == "":
		show_message("Empty username")
		return
	if password == "" or password != conf_pass:
		show_message("Passwords must match and not be empty")
		return
	
	register_user(username, password)

func register_user(username: String, password: String):
	current_request = "add_user"
	
	var url = "http://192.168.254.111/zenpet/register.php"  # adjust path
	
	# URL-encoded POST data
	var form_data = "username=%s&password=%s" % [username, password]
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	
	http.request(url, headers, HTTPClient.METHOD_POST, form_data)

func show_register_form():
	# Stop showing loading
	center_container.visible = false
	fun_loading_info.visible = false

	# Show register form with pop-up animation
	register_window.visible = true
	animation.play("Pop_up")

func start_info_cycle():
	await get_tree().process_frame
	var index = 0
	while animation.current_animation == "loading":
		fun_loading_info.text = infos_array[index % infos_array.size()]
		index += 1
		await get_tree().create_timer(0.8).timeout

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("HTTP Response Code: ", response_code)
	var response_text = body.get_string_from_utf8()
	print("Response: ", response_text)

	if current_request == "check_user":
		var data = JSON.parse_string(response_text)
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			# User already exists
			show_message("User already exists!")
		else:
			# User doesn’t exist → try to register
			current_request = "add_user"
			add_user(username_input.text, password_input.text)

	elif current_request == "add_user":
		if response_code == 201:
			show_message("Registration Success!")
			get_tree().change_scene_to_file("res://Scenes/login.tscn")
		else:
			show_message("Failed to register user!")
			
func add_user(user_name: String, user_password: String):
	current_request = "add_user"
	
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/users"
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json"
	]
	var body = {
		"username": user_name,
		"password": user_password
	}
	
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


func check_user(user_name: String):
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/users"
	url += "?select=username&username=eq." + user_name  
	
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY"
	]
	http.request(url, headers, HTTPClient.METHOD_GET)
