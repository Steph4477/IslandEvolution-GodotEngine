extends Node

# Données
var banane_count = 0
var coco_count = 0
var seed_count = 0
var heal_amount = 0
var can_fire_coco = false

# Joueur & UI
var player_scene = preload("res://Player/evo1.tscn")
var player: Node = null
var hud_scene = preload("res://Interface/Hud.tscn")
var hud: Node = null
var health_bar: Node = null  # séparé !

# Transitions
var fade_scene = preload("res://Effects/fade.tscn")
var fade: Node = null

# Vies
var max_lives = 3
var lives = max_lives

# Mémorisation
var current_level_path: String = ""

# Collecte de graines
var total_seeds_in_level := 0
var collected_seeds := 0

signal all_seeds_collected
signal player_updated(new_player)

# collect de la clés! 
var has_key = false
var current_level: Node = null

signal key_collected

func _ready():
	print("📦 [GameState] Initialisé")
	player = player_scene.instantiate()
	set_player(player)

	fade = fade_scene.instantiate()
	add_child(fade)

	hud = hud_scene.instantiate()

	# ✅ Vérifie et force le bon script si besoin
	if not hud.has_method("update_seed_display"):
		hud.set_script(load("res://Interface/hud.gd"))
	add_child(hud)

	# HealthBar séparée dans HUD
	health_bar = hud.get_node_or_null("HealthBar")

	await get_tree().process_frame
	await load_level("res://Menu/lancement_lvl1/menu_lvl1.tscn")

func set_player(p: Node) -> void:
	player = p
	emit_signal("player_updated", p)

func load_level(scene_path: String) -> void:
	print("🚪 Chargement du niveau :", scene_path)
	var is_menu := is_menu_scene(scene_path)

	# ✅ Mémorise uniquement les niveaux jouables
	if not is_menu:
		current_level_path = scene_path

	# 🎛 Affiche ou cache le HUD et la barre de vie
	if hud:
		hud.visible = not is_menu
	if health_bar:
		health_bar.visible = not is_menu

	# ⬛ Fade out avant de nettoyer la scène
	if fade:
		await fade.fade_out()

	# 🔥 Supprime proprement l'ancien joueur
	if player:
		if player.get_parent():
			player.get_parent().remove_child(player)
		player.queue_free()
		player = null

	# 🧹 Nettoie tous les nodes sauf HUD et fade
	for child in get_children():
		if child != fade and child != hud:
			child.queue_free()

	# ⏳ Laisse le moteur souffler
	await get_tree().process_frame

	# 📦 Charge la nouvelle scène
	var scene_res = load(scene_path)
	if not scene_res:
		push_error("Erreur de chargement : %s" % scene_path)
		return

	var level = scene_res.instantiate()
	current_level = level
	add_child(level)

	# ✅ Ajoute un joueur neuf uniquement dans les niveaux jouables
	if not is_menu:
		player = player_scene.instantiate()
		level.add_child(player)

		# 🎯 Positionne le joueur sur le SpawnPoint 
		var spawn_point = level.get_node_or_null("SpawnPoint")
		player.global_position = spawn_point.global_position

		# 💉 Reset complet du joueur
		if player.has_method("reset_state"):
			player.reset_state()
		else:
			if player.has_variable("pv") and player.has_variable("max_pv"):
				player.pv = player.max_pv

		# ✅ Forcer la MAJ de la barre de vie à 100%
		if health_bar and health_bar.has_method("update_health_bar"):
			health_bar.update_health_bar(player.pv, player.max_pv)

		# 📢 Optionnel : notifier les autres systèmes
		emit_signal("player_updated", player)

	# ▶️ Lancer le fade in
	if fade:
		await fade.fade_in()

func change_scene(scene_path: String) -> void:
	if scene_path == "":
		return
	await load_level(scene_path)

func is_menu_scene(scene_path: String) -> bool:
	return scene_path.contains("menu") or scene_path.contains("Menu")

func reset_lives():
	lives = max_lives
	if hud and hud.has_method("update_lives_display"):
		hud.update_lives_display(lives)

func lose_life():
	if lives > 0:
		lives -= 1
		if hud.has_method("update_lives_display"):
			hud.update_lives_display(lives)

func request_reload_after_delay(delay: float = 0.5) -> void:
	await get_tree().create_timer(delay).timeout
	if is_game_over():
		load_level("res://Menu/Game_over/game_over.tscn")
	else:
		load_level(current_level_path)

func restart_game():
	lives = max_lives
	banane_count = 0
	coco_count = 0
	seed_count = 0
	can_fire_coco = false
	has_key = false
	
	# ✅ MAJ immédiate du HUD
	if hud and hud.has_method("update_lives_display"):
		hud.update_lives_display(lives)
	
	get_tree().process_frame # Attend une frame pour repartir propre

	# ✅ Recharge le dernier niveau valide uniquement
	if current_level_path == "" or current_level_path.contains("game_over"):
		load_level("res://Levels/level_1.tscn")
	else:
		load_level(current_level_path)

func is_game_over() -> bool:
	return lives <= 0

func reset_seed_tracking(seed_count: int) -> void:
	total_seeds_in_level = seed_count
	collected_seeds = 0

func add_seed_collected() -> void:
	collected_seeds += 1
	if collected_seeds >= total_seeds_in_level:
		emit_signal("all_seeds_collected")
