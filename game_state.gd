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
var fade_scene = preload("res://fade.tscn")
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

func _ready():
	print("🟢 GameState actif")
	player = player_scene.instantiate()
	set_player(player)

	fade = fade_scene.instantiate()
	add_child(fade)

	hud = hud_scene.instantiate()
	add_child(hud)

	# HealthBar séparée dans HUD
	health_bar = hud.get_node_or_null("HealthBar")

	await get_tree().process_frame
	await load_level("res://Menu/lancement_lvl1/menu_lvl1.tscn")

func set_player(p: Node) -> void:
	player = p
	print("✅ Joueur enregistré dans GameState :", player)
	emit_signal("player_updated", p)

func load_level(scene_path: String) -> void:
	print("🚪 Chargement du niveau :", scene_path)

	var is_menu := is_menu_scene(scene_path)

	# ✅ Mémorise uniquement les niveaux jouables
	if not is_menu:
		current_level_path = scene_path

	if hud:
		hud.visible = not is_menu
	if health_bar:
		health_bar.visible = not is_menu

	if fade:
		await fade.fade_out()

	# Nettoyage avant chargement
	if player and player.get_parent():
		player.get_parent().remove_child(player)

	for child in get_children():
		if child != fade and child != player and child != hud:
			remove_child(child)
			child.queue_free()

	await get_tree().process_frame

	# ✅ Chargement sécurisé
	var scene_res = load(scene_path)
	var level = scene_res.instantiate()
	add_child(level)
	await get_tree().process_frame

	if not is_menu:
		level.add_child(player)
		if "reset_state" in player:
			player.reset_state()

		var spawn = level.find_child("SpawnPoint", true, false)
		player.global_position = spawn.global_position if spawn else Vector2.ZERO

		if player.has_node("Camera2D"):
			player.get_node("Camera2D").make_current()

	if fade:
		await fade.fade_in()


func is_menu_scene(scene_path: String) -> bool:
	return scene_path.contains("menu") or scene_path.contains("Menu")

func reset_lives():
	lives = max_lives

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

	# ✅ Recharge le dernier niveau valide uniquement
	if current_level_path == "" or current_level_path.contains("game_over"):
		load_level("res://Levels/level_1.tscn")
	else:
		load_level(current_level_path)


func is_game_over() -> bool:
	return lives <= 0

func trigger_player_jump():
	if player and "jump_buffer_timer" in player:
		if player.jump_buffer_timer <= 0.0:
			player.jump_buffer_timer = player.JUMP_BUFFER_TIME

func reset_seed_tracking(seed_count: int) -> void:
	total_seeds_in_level = seed_count
	collected_seeds = 0

func add_seed_collected() -> void:
	collected_seeds += 1
	if collected_seeds >= total_seeds_in_level:
		emit_signal("all_seeds_collected")
