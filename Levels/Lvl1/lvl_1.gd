extends Node2D

#| Fonction                            | Description                                                                    |
#| ----------------------------------- | ------------------------------------------------------------------------------ |
#| `_ready()`                          | Lance l’intro dès le chargement                                                |
#| `start_intro_sequence()`            | Bloque Moko, fait les focus caméra, affiche la quête, puis redonne le contrôle |
#| `show_quest()`                      | Affiche le parchemin 5s                                                        |
#| `focus_camera_on_node()`            | Déplace la caméra en douceur vers un nœud                                      |
#| `return_camera_to_player()`         | Ramène la caméra sur Moko                                                      |
#| `focus_camera_on_totem_with_anim()` | Focus totem, met à jour le sprite, puis revient sur Moko                       |
#| `focus_camera_on_exit_and_fade()`   | Focus sortie, joue le fade, puis revient sur Moko                              |

func _ready():
	start_intro_sequence()
	await get_tree().process_frame
	$Sound/lvl1.play()

# === CINÉMATIQUE D’INTRO ===
func start_intro_sequence() -> void:
	await get_tree().process_frame

	var gs = get_node("/root/GameState")
	var player = gs.player
	player.can_move = false  # 🔒 Moko bloqué

	await focus_camera_on_node("Totem")
	await show_quest()
	await focus_camera_on_node("Exit")
	await return_camera_to_player()

	player.can_move = true  # 🔓 Moko débloqué

# === AFFICHAGE DE LA QUÊTE ===
func show_quest() -> void:
	var quest = get_node_or_null("QuestBox")
	if not quest:
		return

	quest.visible = true

	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	add_child(timer)
	timer.start()

	await timer.timeout
	quest.visible = false
	timer.queue_free()

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

# === FOCUS TOTEM + ANIMATION D'ÉTAPE ===
func focus_camera_on_totem_with_anim(seed_index: int) -> void:
	var gs = get_node("/root/GameState")
	var player = gs.player
	player.can_move = false

	var cam = player.get_node("Camera2D")
	var totem = get_node_or_null("Totem")
	if not totem:
		player.can_move = true
		return

	var original_position = cam.global_position

	var tween = create_tween()
	tween.tween_property(cam, "global_position", totem.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	await get_tree().create_timer(0.6).timeout

	if totem.has_method("update_sprite"):
		totem.update_sprite(seed_index)

	await get_tree().create_timer(0.6).timeout

	var back = create_tween()
	back.tween_property(cam, "global_position", original_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await back.finished

	player.can_move = true

# === FOCUS SORTIE + FADE + RETOUR MOKO ===
func focus_camera_on_exit_and_fade() -> void:
	var gs = get_node("/root/GameState")
	var player = gs.player
	player.can_move = false

	var cam = player.get_node("Camera2D")
	var exit = get_node_or_null("Exit")
	if not exit:
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

	player.can_move = true
