extends Node2D

func _ready() -> void:
	$sound/dijee.play()
	$"VBoxContainer/démarrer".grab_focus()

func _on_démarrer_pressed() -> void:
	var game_state = get_node("/root/GameState")  # ✅ correct
	if game_state:
		game_state.reset_lives()
		game_state.load_level("res://Levels/Lvl1/lvl_1.tscn")

func _on_Options_pressed():
	pass

func _on_Quitter_pressed():
	get_tree().quit()
