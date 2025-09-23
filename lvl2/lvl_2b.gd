extends Node2D

@export var dialogue_scene = preload("res://Interface/dialogue_ui_pyg.tscn")

func _ready():
	# Musique de fond
	$Node2D/Sound/lvl2.play()
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
		moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)

		# 🔒 Bloque le mouvement de Moko pendant le dialogue
		moko.can_move = false
	
	# Insertion du dialogue du pygmée
	await get_tree().process_frame
	await get_tree().create_timer(3).timeout
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)
	await get_tree().process_frame
	dlg.start()
	await dlg.finished

	# 🔓 Réactive le mouvement de Moko après le dialogue
	if gs.player:
		gs.player.can_move = true
