extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")

func _ready():
	$Node2D/Sound/lvl2.play()
	await get_tree().process_frame

	var gs = get_node("/root/GameState")

	# --- Caméra & assombrissement (toujours faits) ---
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.limit_top = -250000
		cam.limit_right = 12000

		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)
		moko.can_move = false

	# --- Si déjà vu -> pas de dialogue ni de focus, mais on garde l'effet ---
	if gs.toucan_dialogue_seen:
		_set_digicode_symbols(gs)
		gs.player.can_move = true
		return

	# --- Dialogue Toucan ---
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	dlg.name = "DialogueUI"
	add_child(dlg)
	dlg.start([
		"J'ai faim, Moko.",
		"Trouve-moi 5 graines avant de sortir.",
		"Et peut-être que je pourrai t'aider..."
	])
	await dlg.finished

	# --- Marque comme vu ---
	gs.toucan_dialogue_seen = true

	# --- Focus sur le digicode ---
	await focus_camera_on_node("Node2D/Digicode")
	await get_tree().create_timer(1).timeout
	await return_camera_to_player()

	# --- Débloque Moko ---
	if gs.player:
		gs.player.can_move = true

	# --- Pose les symboles ---
	_set_digicode_symbols(gs)

# === Digicode ===
func _set_digicode_symbols(gs):
	gs.correct_symbols = ["owl", "lion", "bowl"]
	gs.selected_symbols.clear()

# === FOCUS CAMÉRA GÉNÉRIQUE ===
func focus_camera_on_node(node_name):
	var gs = get_node("/root/GameState")
	var player = gs.player
	if not player:
		return
	var cam = player.get_node("Camera2D")
	var target = get_node_or_null(node_name)
	if target:
		var tween = create_tween()
		tween.tween_property(cam, "global_position", target.global_position, 1.2)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		await get_tree().create_timer(0.6).timeout

# === RETOUR CAMÉRA VERS MOKO ===
func return_camera_to_player():
	var gs = get_node("/root/GameState")
	var player = gs.player
	if not player:
		return
	var cam = player.get_node("Camera2D")
	var tween = create_tween()
	tween.tween_property(cam, "global_position", player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
