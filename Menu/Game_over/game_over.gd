extends Node2D

var gs

func _ready():
	$sound/GameOver.play()
	gs = get_node("/root/GameState")

func _on_restart_pressed():
	gs.reset_progression()
	gs.reset_lives()
	gs.reinitialise()
	gs.reset_session_dialogues()
	gs.load_level("res://Levels/Lvl1/lvl_1.tscn")

func _on_menu_pressed():
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")

func _on_options_pressed():
	gs.load_level("res://Interface/Configuration/configuration.tscn")


func _on_continue_pressed():
	gs.load_global_progress()
	await gs.continue_from_unlocked_level()
