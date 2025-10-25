extends Control

@onready var animation = $AnimationPlayer
@onready var info = $"fun_loading_info"

var next_scene_path: String = ""  # set by the caller
var wait_time: float = 2.0        # default delay
var sentences: Array = [
	"Loading magical outfits...",
	"Magklase pa ta ma'am?",
	"Counting cat pixels...",
	"Polishing the virtual floor...",
	"Preparing your diary...",
	"Charging happiness...",
	"Calibrating ZenAi...",
	"Asa ko nagkulang?",
	"Nagkuan pa si kuan...",
	"Charging your zen meter..."
]


func _ready() -> void:
	animation.play("loading")
	_start_random_info()
	_start_transition()

# 🔹 Randomly updates info every 0.5 seconds
func _start_random_info() -> void:
	while true:
		info.text = sentences[randi() % sentences.size()]
		await get_tree().create_timer(1).timeout

# 🔹 Switch scene after wait_time
func _start_transition() -> void:
	await get_tree().create_timer(wait_time).timeout
	if next_scene_path != "":
		await get_tree().change_scene_to_file(next_scene_path)
		queue_free()
