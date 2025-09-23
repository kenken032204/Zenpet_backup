extends Control

@onready var login_window = $"Login_window"
@onready var username_input = $"Login_window/username_input"
@onready var submit_btn = $"Login_window/submit_btn"
@onready var http = HTTPRequest.new()

func _ready():
	add_child(http)  # make sure HTTPRequest is in the tree
	http.request_completed.connect(_on_HTTPRequest_request_completed)
	submit_btn.pressed.connect(_on_submit_pressed)

# When login is pressed
func _on_submit_pressed():
	var username = username_input.text.strip_edges()
	if username == "":
		print("⚠️ Username required")
		return
	
	print("🔑 Trying to log in:", username)
	check_user(username)

# Query Supabase users table (only username)
func check_user(user_name: String):
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/users"
	url += "?select=username&username=eq." + user_name  # ✅ only return username
	
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY"
	]
	http.request(url, headers, HTTPClient.METHOD_GET)

# Handle HTTP responses
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("HTTP Response Code:", response_code)
	var response_text = body.get_string_from_utf8()
	print("Response:", response_text)

	if response_code == 200:
		var data = JSON.parse_string(response_text)
		if typeof(data) == TYPE_ARRAY and data.size() > 0:
			var user = data[0]
			print("📦 Raw user data:", user)
			print("✅ Login successful for user:", user["username"])
			Global.User = user
			get_tree().change_scene_to_file("res://Scenes/dashboard.tscn")
		else:
			print("❌ User not found")
	else:
		print("⚠️ Error contacting server")
