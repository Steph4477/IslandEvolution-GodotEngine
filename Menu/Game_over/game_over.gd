extends Node2D

var gs

func _ready ():
	gs = get_node("/root/GameState")

func _on_restart_pressed() -> void:
	gs.reset_lives()
	gs.restart_game()  

func _on_menu_pressed() -> void:
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")
