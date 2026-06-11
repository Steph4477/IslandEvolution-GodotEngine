extends Control

@export var next_scene = "res://Levels/IntroCinematic/intro_cinematic.tscn"
@export var splash_duration = 6.0

func _ready():
	await get_tree().create_timer(splash_duration).timeout
	go_to_intro()

func go_to_intro():
	var gs = get_node("/root/GameState")
	gs.load_level(next_scene)
