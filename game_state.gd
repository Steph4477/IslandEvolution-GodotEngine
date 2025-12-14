extends Node

# --- Données globales ---
var banane_count = 0
var honey_count = 0
var coco_count = 0
var seed_count = 0
var bone_count = 0
var heal_amount = 0
var lance_count = 0
var can_fire_coco = false
var can_fire_lance = false
var can_fire_bone = false
var has_key = false
var has_lance = false
var has_flower = false
var toucan_challenge_retry = false
var focus_cam_frog = false

# --- Compétences débloquées ---
var sprint_unlocked = false
var sprint_stamina_max = 100
var sprint_stamina = 100
var sprint_stamina_cost = 40
var sprint_stamina_regen = 25
var double_jump_unlocked = false
var ramp_unlocked = false

# --- Dialogues uniques ---
var toucan_dialogue_seen = false
var pygmy_dialogue_seen = false

# --- Joueur, HUD & Scènes ---
var player_scene = preload("res://Player/player.tscn")
var player = null

var hud_scene = preload("res://Interface/Hud/hud.tscn")
var hud = null
var health_bar = null
var speed_bar = null

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
	process_mode = Node.PROCESS_MODE_ALWAYS

	fade = fade_scene.instantiate()
	add_child(fade)
	fade.process_mode = Node.PROCESS_MODE_ALWAYS

	_create_world()

	reset_session_dialogues()

	await get_tree().process_frame
	await load_level("res://Levels/Lvl3/lvl_3.tscn")


func _process(_delta):
	if Input.is_action_just_pressed("break"):
		toggle_pause()

	if Input.is_action_just_pressed("gc_menu") or Input.is_action_just_pressed("menu"):
		if not is_menu_scene(current_level_path):
			load_level("res://Levels/Lvl0/lvl_0.tscn")


func _create_world():
	if world and is_instance_valid(world):
		world.queue_free()
	world = Node.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)


func set_player(p):
	player = p
	emit_signal("player_updated", p)


func restart_game():
	reinitialise()
	reset_session_dialogues()

	await get_tree().process_frame

	if current_level_path == "":
		await load_level("res://Levels/Lvl1/lvl_1.tscn")
	else:
		await load_level(current_level_path)


func reset_session_dialogues():
	toucan_dialogue_seen = false
	pygmy_dialogue_seen = false


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


func load_level(scene_path):
	resume_game()
	await fade.fade_out()

	emit_signal("player_updated", null)
	player = null

	for child in world.get_children():
		child.queue_free()

	await get_tree().process_frame

	var level = load(scene_path).instantiate()
	current_level = level
	world.add_child(level)

	var spawn_point = _find_spawn(level)
	var is_menu = spawn_point == null

	# HUD (toujours actif)
	if is_menu:
		if hud:
			hud.visible = false
		if health_bar:
			health_bar.visible = false
		if speed_bar:
			speed_bar.visible = false
	else:
		if hud == null:
			hud = hud_scene.instantiate()
			add_child(hud)
			hud.process_mode = Node.PROCESS_MODE_ALWAYS
			health_bar = hud.get_node("HealthBar")
			speed_bar = hud.get_node("SpeedBar")

		hud.visible = true

		if health_bar:
			health_bar.visible = true

		if speed_bar:
			speed_bar.visible = sprint_unlocked

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

		if health_bar:
			health_bar.update_health_bar(p.pv, p.max_pv)

		set_player(p)

		if hud:
			hud.update_lives_display(lives)
			hud.update_seed_display(collected_seeds, total_seeds_in_level)
			hud.update_lance_display()
			hud.update_banane_display()
			hud.update_honey_display()

		# Sprint
		if sprint_unlocked and speed_bar:
			sprint_stamina = sprint_stamina_max
			speed_bar.visible = true
			speed_bar.update_speed_bar_current(sprint_stamina)

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

		sprint_stamina = sprint_stamina_max
		if speed_bar:
			speed_bar.update_speed_bar_current(sprint_stamina)

		request_reload_after_delay(0.5)


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


# --- Signaux ---
func signal_key_collected():
	emit_signal("key_collected")

func signal_digicode_ok():
	emit_signal("digicode_ok")

func signal_flower_collected():
	emit_signal("flower_collected")


func _input(_event):
	if Input.is_action_just_pressed("gc_menu") or Input.is_action_just_pressed("menu"):
		if not is_menu_scene(current_level_path):
			load_level("res://Levels/Lvl0/lvl_0.tscn")


# --- Reset inventaire ---
func reinitialise():
	banane_count = 0
	honey_count = 0
	coco_count = 0
	bone_count = 0
	seed_count = 0
	lance_count = 0

	can_fire_coco = false
	can_fire_lance = false
	can_fire_bone = false

	if hud:
		var gamepad = hud.get_node("Gamepad")
		hud.set_button_enabled(gamepad.get_node("Coco"), false)
		hud.set_button_enabled(gamepad.get_node("Bone"), false)
		hud.set_button_enabled(gamepad.get_node("Spear"), false)
		hud.set_button_enabled(gamepad.get_node("Health"), false)

		# Honey existe maintenant
		if gamepad.has_node("Honey"):
			hud.set_button_enabled(gamepad.get_node("Honey"), false)

		hud.update_seed_display(0, total_seeds_in_level)
		hud.update_lance_display()
		hud.update_banane_display()
		hud.update_honey_display()


# --- Pause ---
func toggle_pause():
	if is_menu_scene(current_level_path):
		return
	is_paused = not is_paused
	get_tree().paused = is_paused

	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(is_paused)


func resume_game():
	is_paused = false
	get_tree().paused = false
	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(false)
