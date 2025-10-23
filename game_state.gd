extends Node

# --- Données globales ---
var banane_count = 0
var coco_count = 0
var seed_count = 0
var heal_amount = 0
var can_fire_coco = false
var can_fire_lance = false
var has_key = false
var has_lance = false

# --- Joueur, HUD & Scènes ---
var player_scene = preload("res://Player/player.tscn")
var player = null

var hud_scene = preload("res://Interface/Hud/hud.tscn")
var hud = null
var health_bar = null

var fade_scene = preload("res://Effects/Fade/fade.tscn")
var fade = null

# --- Vies & niveaux ---
var max_lives = 3
var lives = max_lives
var current_level_path = ""
var current_level = null

# --- Graines ---
var total_seeds_in_level = 0
var collected_seeds = 0

# --- Signaux ---
signal all_seeds_collected
signal key_collected
signal flower_collected
signal player_updated(new_player)
signal digicode_ok  

# --- Digicode lvl2 ---
var correct_symbols = []   # les 3 bons rencontrés dans le niveau
var selected_symbols = []  # la sélection du joueur sur le digicode final

# --- Initialisation ---
func _ready():
	print("📦 [GameState] Initialisé")

	# HUD + Fade
	fade = fade_scene.instantiate()
	add_child(fade)

	hud = hud_scene.instantiate()
	add_child(hud)

	health_bar = hud.get_node("HealthBar")

	# Premier chargement
	await get_tree().process_frame
	#await load_level("res://Levels/Lvl0/lvl_0.tscn")
	#await load_level("res://Levels/Lvl1/lvl_1.tscn")
	#await load_level("res:///Levels/Lvl2/lvl_2.tscn")
	#await load_level("res://Levels/lvl2/Lvl_2b/lvl_2b.tscn")
	await load_level("res://Levels/Lvl3/lvl_3.tscn")

func set_player(p):
	player = p
	emit_signal("player_updated", p)

# --- Chargement de niveau ---
# --- Helper : cherche un node nommé "SpawnPoint" n'importe où dans la scène ---
func _find_spawn(level):
	var direct = level.get_node_or_null("SpawnPoint")
	if direct:
		return direct
	for child in level.get_children():
		var found = _find_spawn(child)
		if found:
			return found
	return null

# --- Chargement de niveau robuste menus/sans spawn ---
func load_level(scene_path):
	print("🚪 Chargement du niveau :", scene_path)

	await fade.fade_out()

	emit_signal("player_updated", null)
	player = null

	for child in get_children():
		if child != fade and child != hud:
			child.queue_free()

	await get_tree().process_frame

	var level = load(scene_path).instantiate()
	current_level = level
	add_child(level)

	var spawn_point = _find_spawn(level)
	var is_menu = spawn_point == null

	hud.visible = not is_menu
	health_bar.visible = not is_menu

	if not is_menu:
		current_level_path = scene_path
		reset_seed_tracking_from_scene()

		var p = player_scene.instantiate()
		level.add_child(p)
		p.global_position = spawn_point.global_position

		if p.has_method("reset_state"):
			p.reset_state()
		elif p.has_variable("pv") and p.has_variable("max_pv"):
			p.pv = p.max_pv
		
		health_bar.update_health_bar(p.pv, p.max_pv)
		set_player(p)

	await fade.fade_in()

# --- Scènes ---
func change_scene(scene_path):
	if scene_path == "":
		return
	await load_level(scene_path)

func is_menu_scene(scene_path):
	return scene_path.contains("menu") or scene_path.contains("Menu")

# --- Vies ---
func reset_lives():
	lives = max_lives
	hud.update_lives_display(lives)

func lose_life():
	if lives > 0:
		lives -= 1
		hud.update_lives_display(lives)
		reinitialise()
		request_reload_after_delay(0.5)

# --- Gain de vie ---
func gain_life():
	if lives < max_lives:
		lives += 1
		hud.update_lives_display(lives)
		if player:
			player.show_info_popup("❤️ +1 vie (" + str(lives) + "/" + str(max_lives) + ")")
		return true
	else:
		if player:
			player.show_info_popup("❤️ Vies déjà au maximum (" + str(max_lives) + ")")
		return false

func is_game_over():
	return lives <= 0

# --- Redémarrage ---
func restart_game():
	lives = max_lives
	hud.update_lives_display(lives)
	reinitialise()
	await get_tree().process_frame
	if current_level_path == "" or current_level_path.contains("game_over"):
		load_level("res://Levels/Lvl1/lvl_1.tscn")
	else:
		load_level(current_level_path)

func request_reload_after_delay(delay = 0.5):
	await get_tree().create_timer(delay).timeout
	if is_game_over():
		load_level("res://Menu/Game_over/game_over.tscn")
	else:
		load_level(current_level_path)

# --- GESTION DES GRAINES ---
func reset_seed_tracking_from_scene():
	var seeds = current_level.get_tree().get_nodes_in_group("Seed")
	total_seeds_in_level = seeds.size()
	collected_seeds = 0
	print("🌱 Graines détectées :", total_seeds_in_level)
	hud.update_seed_display(collected_seeds, total_seeds_in_level)

func add_seed_collected():
	collected_seeds += 1
	hud.update_seed_display(collected_seeds, total_seeds_in_level)
	if collected_seeds >= total_seeds_in_level:
		emit_signal("all_seeds_collected")

# --- Reset inventaire + HUD ---
func reinitialise():
	banane_count = 0
	coco_count = 0
	seed_count = 0
	can_fire_coco = false
	can_fire_lance = false

	var gamepad = hud.get_node("Gamepad")
	hud.set_button_enabled(gamepad.get_node("Ramp"), false)
	hud.set_button_enabled(gamepad.get_node("Coco"), false)
	hud.set_button_enabled(gamepad.get_node("Spear"), false)
	hud.set_button_enabled(gamepad.get_node("Health"), false)
	
	hud.update_seed_display(0, total_seeds_in_level)

# --- Signaux "clé", "digicode", "flower" ---
func signal_key_collected():
	emit_signal("key_collected")

func signal_digicode_ok():   
	emit_signal("digicode_ok")
	
func signal_flower_collected():
	emit_signal("flower_collected")
