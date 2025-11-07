extends Control

var old_exp = Global.User.get("exp", 0)
var old_level = Global.User.get("level", 1)

@onready var back_btn: Button = $"back_button"
@onready var start_btn: Button = $"start_btn"
@onready var level_number: Label = $"Control/level_number"
@onready var level_title: Label = $"Control/level_title"
@onready var timer_label: Label = $"Control/TimerLabel"
@onready var yogadescription: Label = $"Control/YogaDescription"

@onready var progress_bar: ProgressBar = $"Control/ProgressBar"
@onready var animation: AnimationPlayer = $AnimationPlayer

@onready var pose_image: TextureRect = $"Control/Yoga_Sprite"

@onready var yoga_instruction: Label = $"Control/yoga_instruction"

var http_request: HTTPRequest
var exp_request_completed: bool = false

# Data loaded from database
var level_data: Dictionary = {}
var number: int = 1
var title: String = "Zen Session"
var next_scene_path: String = "res://Scenes/zenbody.tscn"
var exp_gain: int = 20
var total_duration: float = 60.0
var steps: int = 100

var messages: Array[String] = [
	"Ready...",
	"Set...",
	"Go!"
]

func _ready() -> void:
	print("🎮 ZenBody Level Starting...")

	if Global.current_zenbody_level.size() > 0:
		level_data = Global.current_zenbody_level
		_load_level_from_data()
	else:
		push_warning("⚠️ No level data found, using defaults")

	animation.play("fade_out")
	back_btn.pressed.connect(_back_to_zenbody)
	start_btn.pressed.connect(_start_level)
	level_number.text = "Level " + str(number)
	level_title.text = title
	timer_label.text = str(int(total_duration))

	# Create HTTPRequest
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_exp_response)
	print("✅ HTTPRequest node created and signal connected")

func _load_level_from_data() -> void:
	number = level_data.get("level_number", 1)
	title = level_data.get("level_name", "Zen Session")
	exp_gain = int(level_data.get("exp_gain", 20))
	total_duration = float(level_data.get("duration_seconds", 60))
	
	var description = level_data.get("session_intro", "")
	var sprite_url = level_data.get("sprite_url", "")
	var instructions = level_data.get("instructions", "")

	# 🧘 Load sprite if available
	if sprite_url != "":
		if sprite_url.begins_with("res://"):
			pose_image.texture = load(sprite_url)
	else:
		push_warning("⚠️ No sprite_url provided for this level")

	# 🩵 Set text content - show the session intro in yogadescription initially
	yogadescription.text = description
	yoga_instruction.text = ""  # Start empty, will be filled during progress

	print("📋 Loaded: %s | EXP: %d | Duration: %ds" % [title, exp_gain, int(total_duration)])

func _back_to_zenbody() -> void:
	_load_next_scene(next_scene_path)

func _start_level() -> void:
	print("🚀 Level started!")
	start_btn.disabled = true
	progress_bar.value = 0

	# 🩵 Show session intro before countdown (if not empty)
	var session_intro = level_data.get("session_intro", "")
	if session_intro != "":
		await _show_messages([session_intro])

	# Countdown after intro
	await _show_messages(messages)
	
	# Hide yogadescription after countdown, keep yoga_instruction visible
	yogadescription.visible = false

	await _increase_progress()

	var user_id: int = Global.User.get("id", 0)
	if user_id != 0:
		print("💫 Starting EXP gain process...")
		await _add_exp_to_user(exp_gain, user_id)
		print("✅ EXP gain process completed")

	_show_level_complete()

func _increase_progress() -> void:
	var step_time: float = total_duration / float(steps)
	var increment: float = (progress_bar.max_value - progress_bar.min_value) / float(steps)

	# Split yoga instructions into parts
	var all_instructions = level_data.get("instructions", "")
	print("🔹 Raw instructions:", all_instructions)
	
	var instruction_parts_raw = all_instructions.split("|")
	
	# Remove empty or whitespace-only strings
	var instruction_parts: Array = []
	for part in instruction_parts_raw:
		var p = part.strip_edges()
		if p != "":
			instruction_parts.append(p)
	print("🔹 Parsed instruction parts:", instruction_parts)
			
	var part_count = instruction_parts.size()
	print("🔹 Total instruction parts:", part_count)
	
	if part_count == 0:
		push_warning("⚠️ No instructions found!")
		# Continue with timer anyway
		for i in range(steps):
			progress_bar.value += increment
			var time_left: float = max(0.0, total_duration - (i * step_time))
			timer_label.text = str(int(time_left))
			print("⏱ Step", i, "Time left:", time_left, "Progress:", progress_bar.value)
			await get_tree().create_timer(step_time).timeout
	else:
		var steps_per_part = steps / float(part_count)
		var part_index = 0

		# Set first instruction immediately
		_show_instruction_with_bounce(instruction_parts[0])
		part_index = 1
			
		for i in range(steps):
			progress_bar.value += increment
			var time_left: float = max(0.0, total_duration - (i * step_time))
			timer_label.text = str(int(time_left))

			# Update instruction based on step count
			if part_index < part_count and i >= int(steps_per_part * part_index):
				# Wait a short pause before showing next instruction
				await get_tree().create_timer(2.0).timeout
				_show_instruction_with_bounce(instruction_parts[part_index])
				part_index += 1


			await get_tree().create_timer(step_time).timeout

	progress_bar.value = progress_bar.max_value
	timer_label.text = "0"
	print("✅ Progress complete, timer done")

# --- Helper function to show instruction with centered bounce + sound ---
func _show_instruction_with_bounce(text: String) -> void:
	print("▶ _show_instruction_with_bounce called with:", text)

	# set text & ensure visible / opaque
	yoga_instruction.text = text
	yoga_instruction.visible = true
	yoga_instruction.modulate.a = 1.0

	# wait one frame so Control layout updates (safe & reliable)
	await get_tree().process_frame

	# center pivot for a true center-scale bounce (use size in Godot 4)
	var size_vec = yoga_instruction.size
	yoga_instruction.pivot_offset = size_vec * 0.5

	# Start smaller and slightly transparent for a combined pop+fade (optional)
	yoga_instruction.scale = Vector2(0.8, 0.8)
	yoga_instruction.modulate.a = 0.0

	# create tween: fade in + bounce in parallel
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(yoga_instruction, "scale", Vector2(1, 1), 0.38)
	tween.parallel().tween_property(yoga_instruction, "modulate:a", 1.0, 0.28)

	# play click sound (debug print to confirm)
	print("▶ Requesting sound play")
	Global.play_sound(load("res://Audio/dog-clicker_IygBqAk.mp3"), -6.0)

	# optionally wait until tween finishes before returning (prevents overlaps)
	await tween.finished
	print("◀ instruction shown (tween finished)")

func _show_messages(msgs: Array[String]) -> void:
	for text in msgs:
		yogadescription.visible = true
		yogadescription.text = text
		yogadescription.modulate.a = 0.0
		yogadescription.scale = Vector2(0.8, 0.8)
		yogadescription.pivot_offset = yogadescription.size / 2

		# ✨ Tween for pop + fade-in
		var pop_in = create_tween()
		pop_in.set_trans(Tween.TRANS_BACK)
		pop_in.set_ease(Tween.EASE_OUT)
		pop_in.tween_property(yogadescription, "scale", Vector2(1, 1), 0.4)
		pop_in.parallel().tween_property(yogadescription, "modulate:a", 1.0, 0.4)
		await pop_in.finished

		await get_tree().create_timer(1.0).timeout

		# 🌙 Tween for fade-out + shrink
		var fade_out = create_tween()
		fade_out.set_trans(Tween.TRANS_SINE)
		fade_out.set_ease(Tween.EASE_IN)
		fade_out.tween_property(yogadescription, "modulate:a", 0.0, 0.3)
		fade_out.parallel().tween_property(yogadescription, "scale", Vector2(0.9, 0.9), 0.3)
		await fade_out.finished


func _add_exp_to_user(amount: int, user_id: int) -> void:
	print("\n🧘‍♀️ [ZenBody] --- EXP ADD START ---")
	print("🧩 Request EXP Gain:", amount)
	print("🧍 User ID:", user_id)

	var url = "%supdate_exp.php" % [Global.BASE_URL]

	var current_exp = float(Global.User.get("exp", 0))
	var current_level = int(Global.User.get("level", 1))
	print("📊 Current EXP:", current_exp, "| Level:", current_level)

	var new_exp = current_exp + amount
	var new_level = current_level

	if new_exp >= 100:
		new_exp -= 100
		new_level += 1
		print("🎉 Level Up! New Level:", new_level, "| Remaining EXP:", new_exp)
	else:
		print("🔸 No Level Up. New EXP:", new_exp)

	var body = {
		"user_id": user_id,
		"level": new_level,
		"exp": new_exp
	}
	var headers = ["Content-Type: application/json"]
	var payload = JSON.stringify(body)
	print("📦 JSON Payload:", payload)

	exp_request_completed = false

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, payload)
	if error != OK:
		print("❌ HTTP Request Error:", error)
		return
	
	print("📡 Request sent to:", url)
	
	while not exp_request_completed:
		await get_tree().process_frame
	
	print("✅ EXP update confirmed!")

func _on_exp_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("\n📥 [EXP RESPONSE] Signal Triggered!")
	print("🧩 Result:", result, "| Response Code:", response_code)

	var text := body.get_string_from_utf8()
	print("🧾 Raw Body:", text)

	if response_code == 200 or response_code == 201:
		var parsed = JSON.parse_string(text)
		if parsed and typeof(parsed) == TYPE_DICTIONARY:
			if parsed.get("success", false):
				print("✅ EXP Updated Successfully on Server!")
				Global.User["exp"] = float(parsed.get("exp", old_exp))
				Global.User["level"] = int(parsed.get("level", old_level))
				print("🎯 Updated Global - Level: %d, EXP: %.1f" % [Global.User["level"], Global.User["exp"]])
			else:
				print("❌ Server Error:", parsed.get("error", "Unknown error"))
		else:
			print("⚠️ Invalid JSON response")
	else:
		print("❌ HTTP Error Code:", response_code)
	
	exp_request_completed = true

func _show_level_complete() -> void:
	print("🎊 Showing level complete screen...")

	var level_complete_scene: PackedScene = load("res://Scenes/level_complete.tscn")
	if not level_complete_scene:
		push_warning("⚠️ level_complete.tscn not found!")
		_load_next_scene("res://Scenes/level_selection.tscn")
		return

	var level_complete: Node = level_complete_scene.instantiate()
	get_tree().root.add_child(level_complete)

	# Wait a bit for the level complete animation
	await get_tree().create_timer(1.0).timeout

	# 🧩 Summon mood assessment popup
	var mood_scene: PackedScene = load("res://Scenes/mood_assessment.tscn")
	if mood_scene:
		var mood_assessment = mood_scene.instantiate()
		get_tree().root.add_child(mood_assessment)
		mood_assessment.summon()

		mood_assessment.mood_submitted.connect(_on_mood_assessment_submitted)
		mood_assessment.mood_submit_cancel.connect(_on_mood_assessment_cancelled)
	else:
		push_warning("⚠️ Mood assessment scene not found!")
		_load_next_scene("res://Scenes/zenbody.tscn")

func _on_mood_assessment_submitted(mood_value: int) -> void:
	print("🧘 Mood submitted:", mood_value)
	_load_next_scene("res://Scenes/zenbody.tscn")

func _on_mood_assessment_cancelled(mood_cancelled: bool):
	print("🧘 Mood Cancelled")
	_load_next_scene("res://Scenes/zenbody.tscn")
	
func _load_next_scene(scene_path: String) -> void:
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("⚠️ Scene not found: " + scene_path)
