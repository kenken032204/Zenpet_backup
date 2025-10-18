extends Control
# ========== NODES ==========
@onready var animation = $AnimationPlayer
@onready var name_input = $"Panel/LineEdit"
@onready var button = $"Panel/Button"
@onready var http_request = HTTPRequest.new()
@onready var toast_notif = $"toast_notification"
# ========== USER ==========
var user_id = Global.User.get("id", null)
# ========== VALIDATION ==========
const MIN_NAME_LENGTH = 3
const MAX_NAME_LENGTH = 12
const NAME_PATTERN = r"^[a-zA-Z0-9]+$"  # Only letters and numbers
# ========== READY ==========
func _ready() -> void:
	add_child(http_request)
	animation.play("pop")
	button.pressed.connect(_on_create_pressed)
# ========== CREATE PET ==========
func _on_create_pressed():
	if user_id == null:
		print("No user ID found!")
		show_message("User not logged in!")
		return
	
	var pet_name = name_input.text.strip_edges()
	
	# EMPTY CHECK
	if pet_name == "":
		show_message("Please input a cute name!")
		return
	
	# LENGTH CHECK
	if pet_name.length() < MIN_NAME_LENGTH:
		show_message("Name too short! Min %d chars." % MIN_NAME_LENGTH)
		return
	elif pet_name.length() > MAX_NAME_LENGTH:
		show_message("Name too long! Max %d chars." % MAX_NAME_LENGTH)
		return
	
	# CHARACTER CHECK
	var regex = RegEx.new()
	if regex.compile(NAME_PATTERN) != OK:
		show_message("Internal error validating name!")
		return
	
	if regex.search(pet_name) == null:
		show_message("Name can only contain letters and numbers!")
		return
	
	# DISABLE BUTTON TO PREVENT MULTIPLE CLICKS
	button.disabled = true
	
	# PREPARE HTTP REQUEST
	var url = "http://192.168.254.111/zenpet/create_pet.php"
	var body = {
		"user_id": user_id,
		"pet_name": pet_name,
		"level": 1,
		"exp": 0
	}
	var headers = ["Content-Type: application/json"]
	
	# CONNECT SIGNAL ONLY ONCE (fixed)
	if not http_request.request_completed.is_connected(Callable(self, "_on_pet_created")):
		http_request.request_completed.connect(Callable(self, "_on_pet_created"))
	http_request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
# ========== HTTP CALLBACK ==========
func _on_pet_created(result, response_code, headers, body):
	button.disabled = false
	var response_text = body.get_string_from_utf8()
	
	if response_code in [200, 201]:
		print("Pet created successfully:", response_text)
		get_tree().change_scene_to_file("res://Scenes/petmain.tscn")
	else:
		print("Failed to create pet:", response_text)
		show_message("Failed to create pet. Try again!")
# ========== TOAST NOTIFICATION ==========
func show_message(text: String, duration: float = 2.0):
	toast_notif.text = text
	toast_notif.modulate.a = 0.0
	toast_notif.visible = true
	
	var tween = create_tween()
	tween.tween_property(toast_notif, "modulate:a", 1.0, 0.3) # fade in
	tween.tween_interval(duration)
	tween.tween_property(toast_notif, "modulate:a", 0.0, 0.3) # fade out
	tween.tween_callback(Callable(toast_notif, "hide"))
