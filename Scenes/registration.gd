extends Control

@onready var animation = $AnimationPlayer
@onready var center_container = $CenterContainer
@onready var register_window = $"Register_Window"
@onready var fun_loading_info = $"fun_loading_info"
@onready var http = HTTPRequest.new()

var infos_array = ["Buying Frisbee for Pet", "Feeding your Pet", "Taking a Walk"]

func _ready():
	add_child(http)

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

func show_register_form():
	# Stop showing loading
	center_container.visible = false
	fun_loading_info.visible = false

	# Show register form with pop-up animation
	register_window.visible = true
	animation.play("Pop_up")

# Cycle loading info messages while 'loading' animation is active
func start_info_cycle():
	await get_tree().process_frame
	var index = 0
	while animation.current_animation == "loading":
		fun_loading_info.text = infos_array[index % infos_array.size()]
		index += 1
		await get_tree().create_timer(0.8).timeout

# Supabase fetch journals
func get_journals():
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals?select=*"
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY"
	]
	http.request(url, headers, HTTPClient.METHOD_GET)

# Supabase add journal entry
func add_journal(user_name: String, text: String):
	var url = "https://rekmhywernuqjshghyvu.supabase.co/rest/v1/journals"
	var headers = [
		"apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJla21oeXdlcm51cWpzaGdoeXZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg1MDEwNjEsImV4cCI6MjA3NDA3NzA2MX0.-ljSNpqHZ-Yzv_0eDlCGDSH7m3uM96c5oD2ejxPHhyY",
		"Content-Type: application/json"
	]
	var body = {
		"user_name": user_name,
		"entry": text
	}
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

# Handle HTTP responses
func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	print("HTTP Response Code: ", response_code)
	print("Response: ", body.get_string_from_utf8())
