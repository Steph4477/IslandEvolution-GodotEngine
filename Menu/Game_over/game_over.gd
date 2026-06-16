extends Node2D

var gs

func _ready():
	$sound/GameOver.play()
	gs = get_node("/root/GameState")

func _on_menu_pressed():
	gs.load_level("res://Levels/Lvl0/lvl_0.tscn")

func _on_quitter_pressed():
	get_tree().quit()
