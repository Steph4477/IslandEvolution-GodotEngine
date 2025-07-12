extends Node2D

func _ready():
	#start_intro_sequence()
	await get_tree().process_frame
	$Sound/lvl1.play()

func start_intro_sequence() -> void:
	await focus_camera_on_totem()
	await show_quest()
	await focus_camera_on_temple()
	await return_camera_to_player()
	


func show_quest() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or not game_state.player:
		return

	game_state.player.disable_controls()

	var quest := get_node_or_null("QuestBox")
	if quest:
		quest.visible = true

		var timer := Timer.new()
		timer.wait_time = 5.0
		timer.one_shot = true
		add_child(timer)
		timer.start()

		await timer.timeout
		quest.visible = false
		timer.queue_free()

func focus_camera_on_temple() -> void:
	await focus_camera_on_node("Exit")

func focus_camera_on_totem(return_to_player := false) -> void:
	await focus_camera_on_node("Totem", return_to_player)

func return_camera_to_player() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or not game_state.player:
		return

	var player = game_state.player
	var cam = player.get_node_or_null("Camera2D")
	if cam == null:
		return

	var back_tween := create_tween()
	back_tween.tween_property(cam, "global_position", player.global_position, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back_tween.finished

	player.enable_controls()

func focus_camera_on_node(node_name: String, return_after := false) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or not game_state.player:
		return

	var player = game_state.player
	player.disable_controls()

	var cam = player.get_node_or_null("Camera2D")
	if cam == null:
		return

	var target = get_node_or_null(node_name)
	if target == null:
		return

	var original_position = cam.global_position

	var tween := create_tween()
	tween.tween_property(cam, "global_position", target.global_position, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(0.6).timeout  # Pause après focus

	if return_after:
		var back_tween = create_tween()
		back_tween.tween_property(cam, "global_position", original_position, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await back_tween.finished
		player.enable_controls()

func focus_camera_on_totem_with_anim(seed_index: int) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or not game_state.player:
		return
	
	var player = game_state.player
	var cam = player.get_node_or_null("Camera2D")
	var totem = get_node_or_null("Totem")

	if cam == null or totem == null:
		return

	player.disable_controls()
	var original_position = cam.global_position

	# 🎥 1. Focus caméra sur le totem
	var tween := create_tween()
	tween.tween_property(cam, "global_position", totem.global_position, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# ⏱️ 2. Pause avant changement visuel
	await get_tree().create_timer(0.6).timeout

	# 🧿 3. Changement de sprite visible pendant focus
	if totem.has_method("update_sprite"):
		totem.update_sprite(seed_index)

	# ⏸️ 4. Pause après pour bien voir le changement
	await get_tree().create_timer(0.6).timeout

	# 🔁 5. Retour caméra vers Moko
	var back_tween = create_tween()
	back_tween.tween_property(cam, "global_position", original_position, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back_tween.finished

	player.enable_controls()

func focus_camera_on_exit_and_fade() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if not game_state or not game_state.player:
		return

	var player = game_state.player
	player.disable_controls()

	var cam = player.get_node_or_null("Camera2D")
	var exit = get_node_or_null("Exit")

	if cam == null or exit == null:
		return

	var original_position = cam.global_position

	# 🎥 Focus caméra sur le temple
	var tween := create_tween()
	tween.tween_property(cam, "global_position", exit.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(1.0).timeout

	# 🎬 Lancement du fade
	if exit.has_method("play_fade"):
		print("🎬 [LVL1] Appel de play_fade()")
		exit.play_fade()
	else:
		print("❌ [LVL1] Exit n’a pas play_fade()")

	await get_tree().create_timer(1.5).timeout

	# 🔁 Retour vers Moko
	var back_tween = create_tween()
	back_tween.tween_property(cam, "global_position", original_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back_tween.finished

	player.enable_controls()
