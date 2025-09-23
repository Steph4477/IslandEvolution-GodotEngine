extends Node2D

@export var key_scene: PackedScene
@onready var key_spawn := $KeySpawn

@onready var stages := [
	$Stage1,
	$Stage2,
	$Stage3,
	$Stage4
]

var game_state: Node = null

func _ready():
	game_state = get_node_or_null("/root/GameState")

	if game_state:
		update_totem_stage()
		game_state.all_seeds_collected.connect(on_all_seeds_collected)

func _process(_delta):
	if game_state:
		update_totem_stage()

# Affiche 1 des 4 étapes en fonction du % de graines collectées
func update_totem_stage() -> void:
	if not game_state or game_state.total_seeds_in_level == 0:
		return

	var collected = game_state.collected_seeds
	var total = game_state.total_seeds_in_level

	var percent := float(collected) / float(total)

	# Détermine l'étape (0 à 3)
	var stage_index := int(floor(percent * 4.0))
	stage_index = clamp(stage_index, 0, 3)

	update_sprite(stage_index + 1)

# Active un seul des 4 sprites visibles
func update_sprite(stage_index: int) -> void:
	for i in range(stages.size()):
		stages[i].visible = (i == stage_index - 1)

# Quand toutes les graines sont collectées
func on_all_seeds_collected():
	print("🔑 [Totem] Toutes les graines ont été collectées !")
	update_sprite(4)
	spawn_key()

func spawn_key():
	if key_scene and key_spawn:
		var key = key_scene.instantiate()
		key.global_position = key_spawn.global_position
		get_tree().current_scene.call_deferred("add_child", key)
