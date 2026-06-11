extends Node2D

var gs

func _ready():
	$sound/GameOver.play()
	gs = get_node("/root/GameState")

func _on_restart_pressed():
	gs.reset_lives()
	gs.load_level(gs.current_level_path)

func _on_menu_pressed():
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")

func _on_options_pressed():
	gs.load_level("res://Interface/Configuration/configuration.tscn")
