extends Node2D

var gs

func _ready() -> void:
	$sound/dijee.play()
	$"VBoxContainer/démarrer".grab_focus()
	gs = get_node("/root/GameState")  # ✅ correct

func _on_démarrer_pressed() -> void:
	gs.reset_lives()
	gs.load_level("res://Levels/Lvl1/lvl_1.tscn")

func _on_Options_pressed():
	pass

func _on_Quitter_pressed():
	get_tree().quit()
