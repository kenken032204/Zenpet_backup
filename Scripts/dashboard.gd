extends Control

@onready var zenpet_btn = $Panel/VBoxContainer/Zenpet_btn
@onready var zenbody_btn = $Panel/VBoxContainer/Zenbody_btn
@onready var zendiary_btn = $Panel/VBoxContainer/Zendiary_btn
@onready var zenai_btn = $Panel/VBoxContainer/Zenai_btn
@onready var animation = $AnimationPlayer

func _ready():
	
	animation.play("fade_out")
	
	zenpet_btn.pressed.connect(_on_zenpet_pressed)
	zenbody_btn.pressed.connect(_on_zenbody_pressed)
	zendiary_btn.pressed.connect(_on_zendiary_pressed)
	zenai_btn.pressed.connect(_on_zenai_pressed)

func _on_zenpet_pressed():
	var scene = load("res://Scenes/petmain.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
	
func _on_zenbody_pressed():
	var scene = load("res://Scenes/zenbody.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
	
func _on_zendiary_pressed():
	var scene = load("res://Scenes/zendiary.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
	
func _on_zenai_pressed():
	var scene = load("res://Scenes/petmain.tscn") as PackedScene
	get_tree().change_scene_to_packed(scene)
