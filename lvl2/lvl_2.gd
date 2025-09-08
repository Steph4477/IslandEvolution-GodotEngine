extends Node2D

@export var dialogue_scene = preload("res://Interface/dialogue_ui.tscn")

func _ready():
	$Sound/lvl2.play()
	
	# insertion du dialogue du toucan
	await get_tree().process_frame  
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)
	await get_tree().process_frame
	dlg.start()
	await dlg.finished
	
	# Assombrissement de Moko
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.player:
		var moko = gs.player
		moko.get_node("Sprite").modulate = Color(0.4, 0.4, 0.4)  
