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
var has_flower = false
var toucan_challenge_retry = false
var focus_cam_frog = false

# --- Dialogues uniques ---
var toucan_dialogue_seen = false
var pygmy_dialogue_seen = false

# --- Joueur, HUD & Scènes ---
var player_scene = preload("res://Player/player.tscn")
var player = null

var hud_scene = preload("res://Interface/Hud/hud.tscn")
var hud = null
var health_bar = null

var fade_scene = preload("res://Effects/Fade/fade.tscn")
var fade = null

# --- Nœud gameplay (pausable) ---
var world = null  # contiendra level + player

# --- Vies & niveaux ---
var max_lives = 3
var lives = max_lives
var current_level_path = ""
var current_level = null

# --- Symboles lvl2 ----
var correct_symbols = []
var selected_symbols = []

# --- Graines ---
var total_seeds_in_level = 0
var collected_seeds = 0

# --- Pause ---
var is_paused = false

# --- Signaux ---
signal all_seeds_collected
signal key_collected
signal flower_collected
signal player_updated(new_player)
signal digicode_ok

func _ready():
	# GameState reste toujours actif pendant la pause
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Fade toujours actif
	fade = fade_scene.instantiate()
	add_child(fade)
	fade.process_mode = Node.PROCESS_MODE_ALWAYS

	# Crée le conteneur gameplay pausable
	_create_world()

	reset_session_dialogues()

	await get_tree().process_frame
	#await load_level("res://Levels/Lvl0/lvl_0.tscn")
	#await load_level("res://Levels/Lvl1/lvl_1.tscn")
	#await load_level("res:///Levels/Lvl2/lvl_2.tscn")
	#await load_level("res://Levels/lvl2/Lvl_2b/lvl_2b.tscn")
	await load_level("res://Levels/Lvl3/lvl_3.tscn")
	

func _process(_delta):
	# Pause via action "break"
	if Input.is_action_just_pressed("break"):
		toggle_pause()

	# Retour menu
	if Input.is_action_just_pressed("gc_menu") or Input.is_action_just_pressed("menu"):
		if not is_menu_scene(current_level_path):
			load_level("res://Levels/Lvl0/lvl_0.tscn")

func _create_world():
	if world and is_instance_valid(world):
		world.queue_free()
	world = Node.new()
	world.name = "World"
	# Tout ce qui est sous "World" s'arrêtera en pause
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

func set_player(p):
	player = p
	emit_signal("player_updated", p)

# --- Redemarre au dernier lvl ou au lvl1 si pas de niveau ---
func restart_game():
	# 🔄 Réinitialise les compteurs, dialogues, et inventaire
	reinitialise()
	reset_session_dialogues()

	# ⏳ Attend une frame pour éviter les conflits de chargement
	await get_tree().process_frame

	# 🗺️ Recharge le dernier niveau si défini, sinon démarre le niveau 1
	if current_level_path == "":
		await load_level("res://Levels/Lvl1/lvl_1.tscn")
	else:
		await load_level(current_level_path)

# --- Dialogues ---
func reset_session_dialogues():
	toucan_dialogue_seen = false
	pygmy_dialogue_seen = false

# --- Spawn ---
func _find_spawn(level):
	var direct = level.get_node_or_null("SpawnPoint")
	if direct:
		return direct
	for child in level.get_children():
		var found = _find_spawn(child)
		if found:
			return found
	return null

func is_menu_scene(scene_path):
	return scene_path.contains("menu") or scene_path.contains("Menu")

# --- Chargement de niveau ---
func load_level(scene_path):
	resume_game()
	await fade.fade_out()

	emit_signal("player_updated", null)
	player = null

	# On ne supprime pas hud ni fade, seulement le contenu gameplay
	for child in world.get_children():
		child.queue_free()

	await get_tree().process_frame

	var level = load(scene_path).instantiate()
	current_level = level
	world.add_child(level)  # ← dans World (pausable)

	var spawn_point = _find_spawn(level)
	var is_menu = spawn_point == null

	# HUD (toujours actif)
	if is_menu:
		if hud:
			hud.visible = false
		if health_bar:
			health_bar.visible = false
	else:
		if hud == null:
			hud = hud_scene.instantiate()
			add_child(hud)
			hud.process_mode = Node.PROCESS_MODE_ALWAYS
			health_bar = hud.get_node("HealthBar")
		hud.visible = true
		if health_bar:
			health_bar.visible = true

	if not is_menu:
		current_level_path = scene_path
		reset_seed_tracking_from_scene()
		
		var p = player_scene.instantiate()
		level.add_child(p)  # player sous le level (lui-même sous World)
		p.global_position = spawn_point.global_position
		# Le player hérite de level → donc PAUSABLE via World

		if p.has_method("reset_state"):
			p.reset_state()
		elif p.has_variable("pv") and p.has_variable("max_pv"):
			p.pv = p.max_pv

		if health_bar:
			health_bar.update_health_bar(p.pv, p.max_pv)

		set_player(p)

		if hud:
			hud.update_lives_display(lives)
			hud.update_seed_display(collected_seeds, total_seeds_in_level)

	await fade.fade_in()

# --- Vies ---
func reset_lives():
	lives = max_lives
	if hud:
		hud.update_lives_display(lives)

func gain_life():
	if lives < max_lives:
		lives += 1
		if hud:
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

func lose_life():
	if lives > 0:
		lives -= 1
		if hud:
			hud.update_lives_display(lives)
		reinitialise()
		request_reload_after_delay(0.5)

# --- Redémarrage ---
func request_reload_after_delay(delay = 0.5):
	await get_tree().create_timer(delay).timeout
	if lives <= 0:
		load_level("res://Menu/Game_over/game_over.tscn")
	else:
		load_level(current_level_path)

# --- Graines ---
func reset_seed_tracking_from_scene():
	var seeds = current_level.get_tree().get_nodes_in_group("Seed")
	total_seeds_in_level = seeds.size()
	collected_seeds = 0
	if hud:
		hud.update_seed_display(collected_seeds, total_seeds_in_level)

func add_seed_collected():
	collected_seeds += 1
	if hud:
		hud.update_seed_display(collected_seeds, total_seeds_in_level)
	if collected_seeds >= total_seeds_in_level:
		emit_signal("all_seeds_collected")

# --- Signaux "clé", "digicode", "flower" ---
func signal_key_collected():
	emit_signal("key_collected")

func signal_digicode_ok():
	emit_signal("digicode_ok")

func signal_flower_collected():
	emit_signal("flower_collected")

# --- Retour menu avec joystique et clavier ---
func _input(_event):
	if Input.is_action_just_pressed("gc_menu") or Input.is_action_just_pressed("menu"):
		if not is_menu_scene(current_level_path):
			load_level("res://Levels/Lvl0/lvl_0.tscn")

# --- Reset inventaire ---
func reinitialise():
	banane_count = 0
	coco_count = 0
	seed_count = 0
	can_fire_coco = false
	can_fire_lance = false
	if hud:
		var gamepad = hud.get_node("Gamepad")
		hud.set_button_enabled(gamepad.get_node("Ramp"), false)
		hud.set_button_enabled(gamepad.get_node("Coco"), false)
		hud.set_button_enabled(gamepad.get_node("Spear"), false)
		hud.set_button_enabled(gamepad.get_node("Health"), false)
		hud.update_seed_display(0, total_seeds_in_level)

# --- Pause ---
func toggle_pause():
	if is_menu_scene(current_level_path):
		return
	is_paused = not is_paused
	get_tree().paused = is_paused
	
	# Affichage de l'ecran de pause !
	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(is_paused)

func resume_game():
	is_paused = false
	get_tree().paused = false
	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(false)
