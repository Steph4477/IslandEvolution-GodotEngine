extends Node2D

@onready var toucan_dialogue = $ToucanDialogue

var gs
var player = null

func _ready():
	$sound/dijee.play()
	gs = get_node("/root/GameState")

func _on_options_pressed():
	gs.load_level("res://Interface/Configuration/configuration.tscn")

func _on_restart_pressed():
	gs.reset_lives()
	gs.reinitialise()
	gs.reset_session_dialogues()
	gs.load_level("res://Levels/Lvl1/lvl_1.tscn")
	

func _on_load_pressed():
	await gs.load_game()

func _on_save_pressed():
	gs.save_game()


func _on_continue_pressed():
	await gs.continue_game()
