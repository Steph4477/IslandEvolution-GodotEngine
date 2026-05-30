extends Node2D

#| Fonction                            | Description                                                                    |
#| ----------------------------------- | ------------------------------------------------------------------------------ |
#| `_ready()`                          | Lance l’intro dès le chargement                                                |
#| `start_intro_sequence()`            | Bloque Moko + ennemis, focus caméra, quête, puis redonne le contrôle           |
#| `set_enemies_blocked(blocked)`      | Active/Désactive tous les ennemis de Creatures                                 |
#| `show_quest()`                      | Affiche le parchemin 5s                                                        |
#| `focus_camera_on_node()`            | Déplace la caméra en douceur vers un nœud                                      |
#| `return_camera_to_player()`         | Ramène la caméra sur Moko                                                      |
#| `focus_camera_on_totem_with_anim()` | Focus totem, met à jour le sprite, puis revient sur Moko                       |
#| `focus_camera_on_exit_and_fade()`   | Focus sortie, joue le fade, puis revient sur Moko                              |

func _ready():
	var gs = get_node("/root/GameState")

	if gs.lvl1_intro_seen == false:
		gs.lvl1_intro_seen = true
		start_intro_sequence()

	await get_tree().process_frame
	$Sound/lvl1.play()

# === CINÉMATIQUE D’INTRO ===
func start_intro_sequence():
	await get_tree().process_frame

	var gs = get_node("/root/GameState")
	var player = gs.player

	player.can_move = false          # 🔒 Moko bloqué
	set_enemies_blocked(true)        # 🔒 Ennemis bloqués

	if gs.hud and gs.lvl1_quest_revealed == false:
		gs.lvl1_quest_revealed = true
		await gs.hud.appear_lvl1_quest()
	
	
	await focus_camera_on_node("Totem")


	await focus_camera_on_node("Exit")
	await return_camera_to_player()

	set_enemies_blocked(false)       # 🔓 Ennemis débloqués
	player.can_move = true           # 🔓 Moko débloqué

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
func return_camera_to_player():
	var gs = get_node("/root/GameState")
	var player = gs.player
	var cam = player.get_node("Camera2D")

	var tween = create_tween()
	tween.tween_property(cam, "global_position", player.global_position, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


# === FOCUS SORTIE + FADE + RETOUR MOKO ===
func focus_camera_on_exit_and_fade():
	var gs = get_node("/root/GameState")
	var player = gs.player

	player.can_move = false
	set_enemies_blocked(true)

	var cam = player.get_node("Camera2D")
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
