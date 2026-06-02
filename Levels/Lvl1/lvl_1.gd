extends Node2D                          

var cam
var player
var gs

func _ready():
	gs = get_node("/root/GameState")

	await get_tree().process_frame

	player = gs.player
	cam = player.get_node("Camera2D")
	cam.limit_right = 9500
	cam.limit_top = -300
	cam.limit_bottom = 1400
	

	if gs.lvl1_intro_seen == false:
		gs.lvl1_intro_seen = true
		#await start_intro_sequence()

	#$Sound.play()


# === CINÉMATIQUE D’INTRO ===
func start_intro_sequence():
	player.can_move = false
	set_enemies_blocked(true)

	if gs.hud and gs.lvl1_quest_revealed == false:
		gs.lvl1_quest_revealed = true
		await gs.hud.appear_lvl1_quest()
	
	await focus_camera_on_node("Totem")
	await focus_camera_on_node("Exit")
	await return_camera_to_player()

	set_enemies_blocked(false)
	player.can_move = true

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

		# stop net si CharacterBody2D (évite inertie)
		if blocked and e is CharacterBody2D:
			e.velocity = Vector2.ZERO


# === FOCUS CAMÉRA GÉNÉRIQUE ===
func focus_camera_on_node(node_name):
	var target = get_node_or_null(node_name)
	if not target:
		return

	var tween = create_tween()
	tween.tween_property(cam, "global_position", target.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(0.6).timeout

# === RETOUR CAMÉRA VERS MOKO ===
func return_camera_to_player():
	var tween = create_tween()
	tween.tween_property(cam, "global_position", player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


# === FOCUS SORTIE + FADE + RETOUR MOKO ===
func focus_camera_on_exit_and_fade():
	player.can_move = false
	set_enemies_blocked(true)

	var exit = get_node_or_null("Exit")
	if not exit:
		set_enemies_blocked(false)
		player.can_move = true
		return

	var original_position = cam.global_position

	var tween = create_tween()
	tween.tween_property(cam, "global_position", exit.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(1.0).timeout

	if exit.has_method("play_fade"):
		exit.play_fade()

	await get_tree().create_timer(1.5).timeout

	var back = create_tween()
	back.tween_property(cam, "global_position", original_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back.finished

	set_enemies_blocked(false)
	player.can_move = true
