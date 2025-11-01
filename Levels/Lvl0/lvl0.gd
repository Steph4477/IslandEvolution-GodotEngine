extends Node2D

var gs

func _ready() -> void:
	$sound/dijee.play()
	gs = get_node("/root/GameState") 

func _on_options_pressed() -> void:
	gs.load_level("res://Interface/Configuration/configuration.tscn")

func _on_restart_pressed() -> void:
	gs.reset_lives()
	gs.restart_game()  

func _on_start_pressed() -> void:
	gs.reset_lives()
	gs.load_level("res://Levels/Lvl1/lvl_1.tscn")
