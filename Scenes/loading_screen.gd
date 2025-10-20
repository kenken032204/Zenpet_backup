extends Control

@onready var animation = $AnimationPlayer
@onready var info = $"fun_loading_info"

var next_scene_path: String = ""  # set by the caller
var wait_time: float = 2.0        # default delay
var sentences: Array = [
	"Loading magical pets...",
	"Fetching zen powers...",
	"Counting cat pixels...",
	"Polishing the virtual floor...",
	"Preparing your adventure...",
	"Charging happiness crystals...",
	"Calibrating rainbow lasers...",
	"Feeding the virtual unicorns...",
	"Syncing with the cloud of dreams...",
	"Untangling digital spaghetti...",
	"Adding sprinkles of joy...",
	"Sharpening pixel swords...",
	"Watering imaginary plants...",
	"Stirring the potion cauldron...",
	"Teaching robots to meditate...",
	"Aligning stars for perfect balance...",
	"Polishing user smiles...",
	"Painting invisible walls...",
	"Counting virtual sheep...",
	"Deploying ninja squirrels...",
	"Lighting up virtual lanterns...",
	"Adjusting gravity for fun...",
	"Training digital puppies...",
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
		get_tree().change_scene_to_file(next_scene_path)
