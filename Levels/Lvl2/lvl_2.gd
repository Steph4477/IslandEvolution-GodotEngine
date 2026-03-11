extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")
@export var crank_path = NodePath("Node2D/Platforms/Bridge/Crank")  

var gs
var moko 
var cam

# === BLOQUAGE / DÉBLOQUAGE ENNEMIS ===
func set_enemies_blocked(blocked):
	var creatures = get_node_or_null("Creatures")
	if not creatures:
		return

	var mode
	if blocked:
		mode = Node.PROCESS_MODE_DISABLED
	else:
		mode = Node.PROCESS_MODE_INHERIT

	for e in creatures.get_children():
		e.process_mode = mode

		# stop net si CharacterBody2D 
		if blocked and e is CharacterBody2D:
			e.velocity = Vector2.ZERO

func _ready():
	$Node2D/Sound/lvl2.play()
	await get_tree().process_frame

	gs = get_node("/root/GameState")

	# --- Limite caméra & assombrissement ---
	cam = gs.player.get_node("Camera2D")
	cam.limit_top = -250000
	cam.limit_right = 12000
	
	# === BLOQUAGE / DÉBLOQUAGE ENNEMIS ===
	set_enemies_blocked(true)

	moko = gs.player
	moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)
	moko.can_move = false

	# --- Ecoute le signal quand toutes les graines sont collectées ---
	gs.connect("all_seeds_collected", Callable(self, "_on_all_seeds_collected"))

	## --- Si déjà vu -> pas de dialogue ni de focus, mais on garde l'effet ---
	#if gs.toucan_dialogue_seen:
		#_set_digicode_symbols(gs)
		#gs.player.can_move = true
		#return
#
	## --- Dialogue Toucan d’intro ---
	#await get_tree().process_frame
	#var dlg = dialogue_scene.instantiate()
	#dlg.name = "DialogueUI"
	#add_child(dlg)
	#dlg.start([
		#"J'ai faim, Moko.",
		#"Trouve-moi 5 graines...",
		#"Et peut-être que je pourrai t'aider..."
	#])
	#await dlg.finished
#
	## --- Marque comme vu ---
	#gs.toucan_dialogue_seen = true

	## --- Focus sur le digicode ---
	#await focus_camera_on_node("Node2D/Digicode")
	#await get_tree().create_timer(1).timeout
	#await return_camera_to_player()
#
	# --- Débloque Moko ---
	moko.can_move = true
#
	## --- Pose les symboles ---
	#_set_digicode_symbols(gs)

# ======================================================
#         Quand toutes les graines sont ramassées
# ======================================================
func _on_all_seeds_collected():
	# --- On bloque le mouvement de Moko
	moko.can_move = false

	# --- Dialogue Toucan manivelle ---
	await get_tree().process_frame
	var dlg = dialogue_scene.instantiate()
	add_child(dlg)
	dlg.start([
		"C'est bien Moko !",
		"Je vais pouvoir manger, tu as récupéré toutes mes graines !",
		"Regarde là-bas... une manivelle !"
	])
	await dlg.finished
	
	# --- Focus caméra sur la manivelle ---
	await focus_camera_on_node(crank_path)
	
	# --- Déverrouille et rend visible la manivelle ---
	var crank = get_node_or_null(crank_path)
	if crank:
		var area = crank.get_node_or_null("Crank")
		if area:
			area.visible = true
			area.set_deferred("monitoring", true)
			area.get_node("CollisionShape2D").disabled = false
			moko.show_info_popup("✅ La manivelle est apparue !")
	
	# --- Retour caméra sur le joueur ---
	await return_camera_to_player()
	moko.can_move = true

# ======================================================
#                    Digicode                        
# ======================================================
func _set_digicode_symbols(_gs):
	gs.correct_symbols = ["owl", "lion", "bowl"]
	gs.selected_symbols.clear()

# ======================================================
#             FOCUS CAMÉRA GÉNÉRIQUE                  
# ======================================================
func focus_camera_on_node(node_path):
	var target = get_node_or_null(node_path)
	var tween = create_tween()
	tween.tween_property(cam, "global_position", target.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	await get_tree().create_timer(0.6).timeout

# ======================================================
#                RETOUR CAMÉRA VERS MOKO              
# ======================================================
func return_camera_to_player():
	var tween = create_tween()
	tween.tween_property(cam, "global_position", gs.player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
