extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")

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
	
	# Insertion du dialogue du toucan
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)

	# 💬 Ici tu définis directement le texte du dialogue
	dlg.start([
		"J'ai faim, Moko.",
		"Trouve-moi 5 graines avant de sortir.",
		"Et peut-être que je pourrai t'aider..."
	])

	await dlg.finished

	# focus sur le digicode
	await focus_camera_on_node("Node2D/Digicode")
	
	# pause d'une seconde sur le digicode
	await get_tree().create_timer(1).timeout
	
	# retour sur la camera du joueur
	await return_camera_to_player()
	
	# 🔓 Réactive le mouvement de Moko après le dialogue
	if gs.player:
		gs.player.can_move = true
	
	gs.correct_symbols = ["owl", "lion", "bowl"]  
	gs.selected_symbols.clear()

# === FOCUS CAMÉRA GÉNÉRIQUE ===
func focus_camera_on_node(node_name: String) -> void:
	var gs = get_node("/root/GameState")
	var player = gs.player
	var cam = player.get_node("Camera2D")
	var target = get_node_or_null(node_name)
	if not target:
		return

	var tween = create_tween()
	tween.tween_property(cam, "global_position", target.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(0.6).timeout

# === RETOUR CAMÉRA VERS MOKO ===
func return_camera_to_player() -> void:
	var gs = get_node("/root/GameState")
	var player = gs.player
	var cam = player.get_node("Camera2D")

	var tween = create_tween()
	tween.tween_property(cam, "global_position", player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
