extends Node2D

func _ready ():	
	$sound/dijee.play()
	$"VBoxContainer/démarrer".grab_focus()

func _on_démarrer_pressed() -> void:
	get_node("/root/GameManagement").load_game()

	
func _on_Options_pressed():
	pass
	
func _on_Quitter_pressed():
	pass
	
