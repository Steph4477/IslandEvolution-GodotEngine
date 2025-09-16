extends Node2D

@export var dialogue_scene = preload("res://Interface/dialogue_ui.tscn")

func _ready():
	# Musique de fond
	$Sound/lvl2.play()
	# On attend pour tout charger
	await get_tree().process_frame

	# Récupérer la caméra du Player et augmenter sa limite top
	var gs = get_node("/root/GameState")
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.limit_top = -250000
		cam.limit_right = 12000   

	# Assombrissement de Moko
	if gs.player:
		var moko = gs.player
		moko.get_node("Sprite").modulate = Color(0.4, 0.4, 0.4)

		# 🔒 Bloque le mouvement de Moko pendant le dialogue
		moko.can_move = false
	
	# Insertion du dialogue du toucan
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)
	await get_tree().process_frame
	dlg.start()
	await dlg.finished

	# 🔓 Réactive le mouvement de Moko après le dialogue
	if gs.player:
		gs.player.can_move = true
