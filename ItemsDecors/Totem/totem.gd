extends Node2D

@export var key_scene: PackedScene = null

var key_spawn
var stages = []

var game_state = null
var key_spawned = false

func _ready():
	key_spawn = $KeySpawn
	stages = [$Stage1, $Stage2, $Stage3, $Stage4]

	game_state = get_node_or_null("/root/GameState")

	if game_state:
		# 1) Affiche l'étape correspondant à l'état actuel
		update_totem_stage()

		# 2) Si déjà toutes les graines collectées → étape 4 + spawn clé immédiat
		if game_state.total_seeds_in_level > 0 and game_state.collected_seeds >= game_state.total_seeds_in_level:
			update_sprite(4)
			spawn_key()

		# 3) Branche le signal (sans doublon)
		var cb = Callable(self, "on_all_seeds_collected")
		if not game_state.is_connected("all_seeds_collected", cb):
			game_state.connect("all_seeds_collected", cb)

# Affiche 1 des 4 étapes en fonction du % de graines collectées
func update_totem_stage():
	if not game_state:
		return
	if game_state.total_seeds_in_level == 0:
		return

	var collected = game_state.collected_seeds
	var total = game_state.total_seeds_in_level
	if total <= 0:
		return

	var percent = float(collected) / float(total)

	# 0..3
	var stage_index = int(floor(percent * 4.0))
	if stage_index < 0:
		stage_index = 0
	if stage_index > 3:
		stage_index = 3

	# update_sprite attend 1..4
	update_sprite(stage_index + 1)

# Active un seul des 4 sprites visibles (1..4)
func update_sprite(stage_index):
	for i in range(stages.size()):
		stages[i].visible = (i == stage_index - 1)

# Quand toutes les graines sont collectées
func on_all_seeds_collected():
	update_sprite(4)
	spawn_key()

func spawn_key():
	if key_spawned:
		return
	key_spawned = true

	if not key_scene or not key_spawn:
		return

	var key = key_scene.instantiate()
	key.global_position = key_spawn.global_position

	# Ajoute la clé dans le niveau courant si possible, sinon dans la scène courante
	var parent = null
	if game_state and game_state.current_level:
		parent = game_state.current_level
	else:
		parent = get_tree().current_scene

	if parent:
		parent.call_deferred("add_child", key)
