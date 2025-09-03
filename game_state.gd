extends Node

# --- Données globales ---
var banane_count = 0
var coco_count = 0
var seed_count = 0
var heal_amount = 0
var can_fire_coco = false
var has_key = false
var has_lance =false
# --- Joueur, HUD & Scènes ---
var player_scene = preload("res://Player/evo1.tscn")
var player: Node = null

var hud_scene = preload("res://Interface/Hud.tscn")
var hud: Node = null
var health_bar: Node = null

var fade_scene = preload("res://Effects/fade.tscn")
var fade: Node = null

# --- Vies & niveaux ---
var max_lives = 3
var lives = max_lives
var current_level_path: String = ""
var current_level: Node = null

# --- Graines ---
var total_seeds_in_level := 0
var collected_seeds := 0

# --- Signaux ---
signal all_seeds_collected
signal key_collected
signal lance_collected
signal player_updated(new_player)

# --- Initialisation ---
func _ready():
	print("📦 [GameState] Initialisé")

	player = player_scene.instantiate()
	set_player(player)

	fade = fade_scene.instantiate()
	add_child(fade)

	hud = hud_scene.instantiate()
	if not hud.has_method("update_seed_display"):
		hud.set_script(load("res://Interface/hud.gd"))
	add_child(hud)

	health_bar = hud.get_node_or_null("HealthBar")

	await get_tree().process_frame
	#await load_level("res://Menu/lancement_lvl1/menu_lvl1.tscn")
	await load_level("res://lvl2/lvl_2.tscn")

func set_player(p: Node) -> void:
	player = p
	emit_signal("player_updated", p)

# --- Chargement de niveau ---
func load_level(scene_path: String) -> void:
	print("🚪 Chargement du niveau :", scene_path)
	var is_menu := is_menu_scene(scene_path)

	if not is_menu:
		current_level_path = scene_path

	if hud:
		hud.visible = not is_menu
	if health_bar:
		health_bar.visible = not is_menu

	if fade:
		await fade.fade_out()

	if player and player.get_parent():
		player.get_parent().remove_child(player)
		player.queue_free()
		player = null

	for child in get_children():
		if child != fade and child != hud:
			child.queue_free()

	await get_tree().process_frame

	var scene_res = load(scene_path)
	if not scene_res:
		push_error("Erreur de chargement : %s" % scene_path)
		return

	var level = scene_res.instantiate()
	current_level = level
	add_child(level)

	# 🌱 Calcul automatique des graines dans la scène
	if not is_menu:
		reset_seed_tracking_from_scene()

		player = player_scene.instantiate()
		level.add_child(player)

		var spawn_point = level.get_node_or_null("SpawnPoint")
		player.global_position = spawn_point.global_position

		if player.has_method("reset_state"):
			player.reset_state()
		elif player.has_variable("pv") and player.has_variable("max_pv"):
			player.pv = player.max_pv

		if health_bar and health_bar.has_method("update_health_bar"):
			health_bar.update_health_bar(player.pv, player.max_pv)

		emit_signal("player_updated", player)

	if fade:
		await fade.fade_in()

# --- Scènes ---
func change_scene(scene_path: String) -> void:
	if scene_path == "":
		return
	await load_level(scene_path)

func is_menu_scene(scene_path: String) -> bool:
	return scene_path.contains("menu") or scene_path.contains("Menu")

# --- Vies ---
func reset_lives():
	lives = max_lives
	if hud and hud.has_method("update_lives_display"):
		hud.update_lives_display(lives)

func lose_life():
	if lives > 0:
		lives -= 1
		if hud.has_method("update_lives_display"):
			hud.update_lives_display(lives)

func is_game_over() -> bool:
	return lives <= 0

# --- Redémarrage ---
func restart_game():
	lives = max_lives
	banane_count = 0
	coco_count = 0
	seed_count = 0
	can_fire_coco = false
	has_key = false
	has_lance = false

	if hud and hud.has_method("update_lives_display"):
		hud.update_lives_display(lives)

	await get_tree().process_frame

	if current_level_path == "" or current_level_path.contains("game_over"):
		load_level("res://Levels/level_1.tscn")
	else:
		load_level(current_level_path)

func request_reload_after_delay(delay: float = 0.5) -> void:
	await get_tree().create_timer(delay).timeout
	if is_game_over():
		load_level("res://Menu/Game_over/game_over.tscn")
	else:
		load_level(current_level_path)

# --- GESTION DES GRAINES ---
func reset_seed_tracking_from_scene() -> void:
	if not current_level:
		return

	var seeds = current_level.get_tree().get_nodes_in_group("Seed")
	total_seeds_in_level = seeds.size()
	collected_seeds = 0

	print("🌱 Graines détectées :", total_seeds_in_level)

	if hud and hud.has_method("update_seed_display"):
		hud.update_seed_display(collected_seeds, total_seeds_in_level)

func add_seed_collected() -> void:
	collected_seeds += 1

	if hud and hud.has_method("update_seed_display"):
		hud.update_seed_display(collected_seeds, total_seeds_in_level)

	if collected_seeds >= total_seeds_in_level:
		emit_signal("all_seeds_collected")
