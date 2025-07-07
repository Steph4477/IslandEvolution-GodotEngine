extends Node2D

func _ready ():	
	$sound/GameOver.play()
	$"VBoxContainer/démarrer".grab_focus()

func _on_démarrer_pressed() -> void:
	var game_state = get_node("/root/GameState")
	game_state.restart_game()  # 💡 recharge current_level_path et reset les vies

func _on_Options_pressed():
	pass

func _on_Quitter_pressed():
	get_tree().quit()
