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
	cam.limit_bottom = 1500
	
	if not gs.all_seeds_collected.is_connected(_on_all_seeds_collected):
		gs.all_seeds_collected.connect(_on_all_seeds_collected)

	if not gs.key_collected.is_connected(_on_key_collected):
		gs.key_collected.connect(_on_key_collected)


	if gs.lvl1_intro_seen == false:
		gs.lvl1_intro_seen = true
		await start_intro_sequence()

	$Sound/Lvl1.play()

func _on_all_seeds_collected():
	player.disable_controls()
	set_enemies_blocked(true)

	await focus_camera_on_node("Totem")
	await return_camera_to_player()

	await get_tree().create_timer(1.0).timeout

	player.enable_controls()
	set_enemies_blocked(false)
	


# === CINÉMATIQUE D’INTRO ===
func start_intro_sequence():
	player.disable_controls()

	set_enemies_blocked(true)

	cam.top_level = true
	cam.global_position = player.global_position

	if gs.hud and gs.lvl1_quest_revealed == false:
		gs.lvl1_quest_revealed = true
		await gs.hud.appear_lvl1_quest()
	
	await focus_camera_on_node("Totem")
	await focus_camera_on_node("Exit")
	await return_camera_to_player()

	player.enable_controls()
	set_enemies_blocked(false)


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

	cam.top_level = false
	cam.position = Vector2.ZERO


func _on_key_collected():
	await focus_camera_on_exit_and_fade()

	if gs.hud:
		await get_tree().create_timer(0.5).timeout
		await gs.hud.disappear_lvl1_quest()


# === FOCUS SORTIE + FADE + RETOUR MOKO ===
func focus_camera_on_exit_and_fade():
	player.disable_controls()
	set_enemies_blocked(true)

	cam.top_level = true
	cam.global_position = player.global_position

	var exit = get_node_or_null("Exit")
	if not exit:
		cam.top_level = false
		cam.position = Vector2.ZERO

		set_enemies_blocked(false)
		player.enable_controls()
		return

	var original_position = player.global_position

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

	cam.top_level = false
	cam.position = Vector2.ZERO

	player.enable_controls()
	set_enemies_blocked(false)
	
