extends Node

# --- Sauvegarde ---
const SAVE_PATH = "user://savegame.json"
var has_pending_load = false
var pending_player_pos = Vector2.ZERO
var pending_level_path = ""

# Permet de sauvegarder depuis le menu (lvl0) quand player = null
var last_player_pos = Vector2.ZERO
var has_last_player_pos = false

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
var can_camouflage = false
var has_key = false
var has_lance = false
var has_flower = false
var toucan_challenge_retry = false
var focus_cam_frog = false

# --- Camouflage ---
var camouflage_unlocked = false
var camouflage_count = 0
var is_camouflaged = false

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
var lvl1_intro_seen = false

# --- Joueur, HUD & Scènes ---
var player_scene = preload("res://Player/player.tscn")
var player = null

var hud_scene = preload("res://Hud/Hud.tscn")
var hud = null

var boss_fight_hud_scene = preload("res://Hud/BossHud/HudFightBoss/hud_fight_boss.tscn")
var boss_fight_hud = null

var health_bar = null
var speed_bar = null
var breath_bar = null
var fire_buff_bar = null
var fire_buff_unlocked = false
var air_buff_bar = null
var air_buff_unlocked = false

var fade_scene = preload("res://Effects/Fade/fade.tscn")
var fade = null

# --- Nœud gameplay (pausable) ---
var world = null  # contiendra level + player

# --- Vies & niveaux ---
var max_lives = 3
var lives = max_lives
var current_level_path = ""
var current_level = null

var skill_selected = "ramp"

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

##################################################################################
#                            QUETES                                              #
##################################################################################
# --- Craft skill_fire ---
var wood_collected = false
var stone_collected = false
var fire_recipe_unlocked = false
var fire_recipe_dialog_shown = false
var fire_craft_revealed = false
var fire_altar_found = false

# --- Craft skill_air ---
var leaf_collected = false
var idole_collected = false
var air_recipe_unlocked = false
var air_recipe_dialog_shown = false
var air_craft_revealed = false
var air_altar_found = false

# --- Lvl_1 Collecte de graines ---
var lvl1_quest_revealed = false
var lvl1_seeds_done = false
var lvl1_totem_done = false
var lvl1_key_done = false

##################################################################################
#                            SCORE                                               #
##################################################################################
var score_system: ScoreSystem
var score_screen_scene = preload("res://Hud/ScoreScreen/score_screen.tscn")
var score_screen = null
# --- Bonus ---
var moko_damage_bonus_percent = 0
var moko_hp_bonus_percent = 0
var enemy_evolution_percent = 0
var score_evolution_applied = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# --- score ---
	score_system = ScoreSystem.new()
	add_child(score_system)

	# --- score screen ---
	score_screen = score_screen_scene.instantiate()
	add_child(score_screen)

	print(score_screen)

	score_screen.visible = false

	# --- fondu au chargement ---
	fade = fade_scene.instantiate()
	add_child(fade)
	fade.process_mode = Node.PROCESS_MODE_ALWAYS

	# --- Création du monde qui contiendra les niveaux ---
	_create_world()
	
	# --- Réinitialise les dialogues de session pour éviter les répétitions ---
	reset_session_dialogues()

	await get_tree().process_frame
	#await load_level("res://Levels/IntroCinematic/intro_cinematic.tscn")
	#await load_level("res://Levels/Test/test_scene.tscn")
	#await load_level("res://Levels/Lvl0/lvl_0.tscn")
	await load_level("res://Levels/Lvl1/lvl_1.tscn")
	#await load_level("res://Levels/Lvl2/lvl_2.tscn")
	#await load_level("res://Levels/Lvl2/Lvl_2a/lvl_2a.tscn")
	#await load_level("res://Levels/Lvl2/Lvl_2b/lvl_2b.tscn")
	#await load_level("res://Levels/Lvl2/Lvl_2c/lvl_2c.tscn")
	#await load_level("res://Levels/Lvl3/lvl_3.tscn")
	#await load_level("res://Levels/Lvl3/Lvl_3b/lvl_3b.tscn")
	#await load_level("res://Levels/Lvl4/lvl_4.tscn")


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

	# Mémorise position pour pouvoir sauver depuis le menu
	if player:
		last_player_pos = player.global_position
		has_last_player_pos = true

	emit_signal("player_updated", p)

func restart_game():
	reinitialise()
	reset_session_dialogues()

	# Forces une nouvelle partie
	current_level_path = "res://Levels/Lvl1/lvl_1.tscn"

	# Oublies tout pending load
	has_pending_load = false
	pending_level_path = ""
	pending_player_pos = Vector2.ZERO

	await get_tree().process_frame
	await load_level(current_level_path)

func continue_game():
	# Si aucune partie n'a encore été lancée, revient lvl1
	if current_level_path == "":
		await load_level("res://Levels/Lvl1/lvl_1.tscn")
		return

	# On force un "pending load" sur la dernière position connue
	if has_last_player_pos:
		has_pending_load = true
		pending_player_pos = last_player_pos
		pending_level_path = current_level_path
	else:
		# Pas de position mémorisée -> Continue au SpawnPoint
		has_pending_load = false
		pending_player_pos = Vector2.ZERO
		pending_level_path = ""

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
	return scene_path.contains("menu") or scene_path.contains("Menu") or scene_path.contains("Lvl0") or scene_path.contains("lvl_0")


######################################################################################
#                                     SCORE                                          #
######################################################################################
func show_score_screen():
	score_system.calculate_stars()

	score_screen.show_score(
		get_current_level_title(),
		score_system.enemies_killed,
		score_system.enemies_total,
		score_system.stars,
		score_system.get_medal(),
		score_system.get_kill_percent(),
		score_system.get_moko_evolution_bonus(),
		score_system.get_enemy_evolution_bonus()
	)

func setup_level_score(level):
	score_system.reset_level_score()

	var creatures = level.find_child("Creatures", true, false)
	var total_enemies = 0

	if creatures:
		total_enemies = score_system.count_enemies_in_node(creatures)

	score_system.set_enemies_total(total_enemies)

	print("SCORE - Total ennemis :", total_enemies)

func get_current_level_title():
	if current_level_path == "res://Levels/Lvl1/lvl_1.tscn":
		return "Jungle Tropicale"

	if current_level_path == "res://Levels/Lvl2/lvl_2.tscn":
		return "Mangrove"

	if current_level_path == "res://Levels/Lvl3/lvl_3.tscn":
		return "Village Cannibale"

	return "Territoire Inconnu"

func load_level(scene_path):
	resume_game()
	await fade.fade_out()

	if boss_fight_hud != null:
		boss_fight_hud.queue_free()
		boss_fight_hud = null

	# Sauvegarde position du player 
	if player:
		last_player_pos = player.global_position
		has_last_player_pos = true

	emit_signal("player_updated", null)
	player = null

	for child in world.get_children():
		child.queue_free()

	await get_tree().process_frame

	var level = load(scene_path).instantiate()
	current_level = level
	world.add_child(level)

	# --- Cache l'écran de score ---
	if score_screen:
		score_screen.visible = false

	# --- Score ---
	setup_level_score(level)

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
			speed_bar = hud.get_node("BarSlot/SpeedBar")

		hud.visible = true

		if health_bar:
			health_bar.visible = true

		if speed_bar:
			speed_bar.visible = sprint_unlocked

	if not is_menu:
		current_level_path = scene_path
		reset_seed_tracking_from_scene()

		var is_loading_save = has_pending_load

		var p = player_scene.instantiate()
		level.add_child(p)

		if is_loading_save:
			p.global_position = pending_player_pos
		else:
			p.global_position = spawn_point.global_position

		if not is_loading_save:
			if p.has_method("reset_state"):
				p.reset_state()
			else:
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
			hud.update_coco_display()
			hud.update_bone_display()
			hud.update_camouflage_display()

		# Sprint
		if sprint_unlocked and speed_bar:
			sprint_stamina = sprint_stamina_max
			speed_bar.visible = true
			speed_bar.update_speed_bar_current(sprint_stamina)

	await fade.fade_in()

# ============================================================================
#                         BOSS FIGHT HUD
# ============================================================================
func show_boss_fight_hud(boss):
	if hud and hud.has_method("set_gameplay_hud_visible"):
		hud.set_gameplay_hud_visible(false)

	if boss_fight_hud != null:
		boss_fight_hud.queue_free()
		boss_fight_hud = null

	boss_fight_hud = boss_fight_hud_scene.instantiate()
	add_child(boss_fight_hud)
	boss_fight_hud.process_mode = Node.PROCESS_MODE_ALWAYS

	boss_fight_hud.setup(player, boss)


func hide_boss_fight_hud():
	if boss_fight_hud != null:
		boss_fight_hud.queue_free()
		boss_fight_hud = null

	if hud and hud.has_method("set_gameplay_hud_visible"):
		hud.set_gameplay_hud_visible(true)


func update_boss_fight_hud():
	if boss_fight_hud == null:
		return

	boss_fight_hud.update_hud()
# ===================================================================
#                          SAVE / LOAD
# ===================================================================

func save_game():
	# Il faut au minimum avoir déjà lancé une partie
	if current_level_path == "":
		return false

	# Position : player si dispo, sinon last_player_pos (quand on est au menu)
	var pos = null
	if player:
		pos = player.global_position
	elif has_last_player_pos:
		pos = last_player_pos
	else:
		return false

	var data = {}

	data["level_path"] = current_level_path
	data["player_pos"] = {"x": pos.x, "y": pos.y}

	data["banane_count"] = banane_count
	data["honey_count"] = honey_count
	data["coco_count"] = coco_count
	data["seed_count"] = seed_count
	data["bone_count"] = bone_count
	data["lance_count"] = lance_count
	data["lives"] = lives

	data["can_fire_coco"] = can_fire_coco
	data["can_fire_lance"] = can_fire_lance
	data["can_fire_bone"] = can_fire_bone

	data["camouflage_unlocked"] = camouflage_unlocked
	data["camouflage_count"] = camouflage_count
	data["can_camouflage"] = can_camouflage

	data["sprint_unlocked"] = sprint_unlocked
	data["double_jump_unlocked"] = double_jump_unlocked
	data["ramp_unlocked"] = ramp_unlocked
	data["fire_buff_unlocked"] = fire_buff_unlocked
	data["air_buff_unlocked"] = air_buff_unlocked
	
	data["has_key"] = has_key
	data["has_lance"] = has_lance
	data["has_flower"] = has_flower
	
	data["wood_collected"] = wood_collected
	data["stone_collected"] = stone_collected
	data["fire_recipe_unlocked"] = fire_recipe_unlocked
	data["fire_recipe_dialog_shown"] = fire_recipe_dialog_shown
	data["fire_craft_revealed"] = fire_craft_revealed
	data["fire_altar_found"] = fire_altar_found
	
	data["leaf_collected"] = leaf_collected
	data["idole_collected"] = idole_collected
	data["air_recipe_unlocked"] = air_recipe_unlocked
	data["air_recipe_dialog_shown"] = air_recipe_dialog_shown
	data["air_craft_revealed"] = air_craft_revealed
	data["air_altar_found"] = air_altar_found
	
	data["lvl1_intro_seen"] = lvl1_intro_seen

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

	return true


func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var result = json.parse(content)
	if result != OK:
		return false

	var data = json.data
	await apply_save_data(data)
	return true


func apply_save_data(data):
	pending_level_path = data.get("level_path", "")

	var pos_dict = data.get("player_pos", null)
	if pos_dict:
		pending_player_pos = Vector2(pos_dict["x"], pos_dict["y"])
		has_pending_load = true
	else:
		has_pending_load = false

	banane_count = int(data.get("banane_count", 0))
	honey_count = int(data.get("honey_count", 0))
	coco_count = int(data.get("coco_count", 0))
	seed_count = int(data.get("seed_count", 0))
	bone_count = int(data.get("bone_count", 0))
	lance_count = int(data.get("lance_count", 0))
	lives = int(data.get("lives", max_lives))

	can_fire_coco = data.get("can_fire_coco", false)
	can_fire_lance = data.get("can_fire_lance", false)
	can_fire_bone = data.get("can_fire_bone", false)

	camouflage_unlocked = data.get("camouflage_unlocked", false)
	camouflage_count = int(data.get("camouflage_count", 0))
	can_camouflage = data.get("can_camouflage", false)

	sprint_unlocked = data.get("sprint_unlocked", false)
	double_jump_unlocked = data.get("double_jump_unlocked", false)
	ramp_unlocked = data.get("ramp_unlocked", false)
	fire_buff_unlocked = data.get("fire_buff_unlocked", false)
	air_buff_unlocked = data.get("air_buff_unlocked", false)
	
	has_key = data.get("has_key", false)
	has_lance = data.get("has_lance", false)
	has_flower = data.get("has_flower", false)
	
	wood_collected = data.get("wood_collected", false)
	stone_collected = data.get("stone_collected", false)
	fire_recipe_unlocked = data.get("fire_recipe_unlocked", false)
	fire_recipe_dialog_shown = data.get("fire_recipe_dialog_shown", false)
	fire_craft_revealed = data.get("fire_craft_revealed", false)
	fire_altar_found = data.get("fire_altar_found", false)

	leaf_collected = data.get("leaf_collected", false)
	idole_collected = data.get("idole_collected", false)
	air_recipe_unlocked = data.get("air_recipe_unlocked", false)
	air_recipe_dialog_shown = data.get("air_recipe_dialog_shown", false)
	air_craft_revealed = data.get("air_craft_revealed", false)
	air_altar_found = data.get("air_altar_found", false)
	
	lvl1_intro_seen = data.get("lvl1_intro_seen", false)

	# Recharge du niveau sauvegardé
	await load_level(pending_level_path)


# ===================================================================

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
			player.popups_mod.show_info("❤️ +1 vie (" + str(lives) + "/" + str(max_lives) + ")")
		return true
	else:
		if player:
			player.popups_mod.show_info("❤️ Vies déjà au maximum (" + str(max_lives) + ")")
		return false


func is_game_over():
	return lives <= 0


func lose_life():
	if lives > 0:
		lives -= 1
		if hud:
			hud.update_lives_display(lives)

		reset_after_death()

		sprint_stamina = sprint_stamina_max
		if speed_bar:
			speed_bar.update_speed_bar_current(sprint_stamina)

		request_reload_after_delay(0.5)

func reset_after_death():
	banane_count = 0
	honey_count = 0
	coco_count = 0
	bone_count = 0
	seed_count = 0
	lance_count = 0
	camouflage_count = 0

	can_fire_coco = false
	can_fire_lance = false
	can_fire_bone = false
	can_camouflage = false

	get_tree().paused = false
	is_paused = false
	if hud and hud.has_method("set_pause_visual"):
		hud.set_pause_visual(false)

	if hud:
		var gamepad = hud.get_node("Gamepad")
		hud.set_button_enabled(gamepad.get_node("Coco"), false)
		hud.set_button_enabled(gamepad.get_node("Bone"), false)
		hud.set_button_enabled(gamepad.get_node("Spear"), false)
		hud.set_button_enabled(gamepad.get_node("Health"), false)
		hud.set_button_enabled(gamepad.get_node("Honey"), false)
		hud.set_button_enabled(gamepad.get_node("Camouflage"), false)

		hud.update_seed_display(0, total_seeds_in_level)
		hud.update_lance_display()
		hud.update_banane_display()
		hud.update_honey_display()
		hud.update_coco_display()
		hud.update_bone_display()
		hud.update_camouflage_display()

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
		lvl1_seeds_done = true

		if hud:
			hud.update_lvl1_checklist()

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
	camouflage_count = 0

	can_fire_coco = false
	can_fire_lance = false
	can_fire_bone = false
	can_camouflage = false
	fire_buff_unlocked = false
	air_buff_unlocked = false
	
	wood_collected = false
	stone_collected = false
	fire_recipe_unlocked = false
	fire_recipe_dialog_shown = false
	fire_craft_revealed = false
	fire_altar_found = false
	
	leaf_collected = false
	idole_collected = false
	air_recipe_dialog_shown = false
	air_recipe_unlocked = false
	air_craft_revealed = false
	air_altar_found = false
	
	lvl1_intro_seen = false

	lvl1_quest_revealed = false
	lvl1_seeds_done = false
	lvl1_totem_done = false
	lvl1_key_done = false

	if hud:
		var gamepad = hud.get_node("Gamepad")
		hud.set_button_enabled(gamepad.get_node("Coco"), false)
		hud.set_button_enabled(gamepad.get_node("Bone"), false)
		hud.set_button_enabled(gamepad.get_node("Spear"), false)
		hud.set_button_enabled(gamepad.get_node("Health"), false)
		hud.set_button_enabled(gamepad.get_node("Honey"), false)
		hud.set_button_enabled(gamepad.get_node("Camouflage"), false)

		hud.update_seed_display(0, total_seeds_in_level)
		hud.update_lance_display()
		hud.update_banane_display()
		hud.update_honey_display()
		hud.update_coco_display()
		hud.update_bone_display()
		hud.update_camouflage_display()


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
