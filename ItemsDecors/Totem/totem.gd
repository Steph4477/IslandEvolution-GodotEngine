extends Node2D

@export var key_scene: PackedScene
@onready var key_spawn := $KeySpawn

@onready var stages := [
	$Stage1,
	$Stage2,
	$Stage3,
	$Stage4
]

func update_sprite(stage_index: int) -> void:
	for i in stages.size():
		stages[i].visible = (i == stage_index - 1)


func on_all_seeds_collected():
	update_sprite(4)
	# Fait apparaître la clé !
	spawn_key()

func spawn_key():
	if key_scene and key_spawn:
		var key = key_scene.instantiate()
		key.global_position = key_spawn.global_position
		get_tree().current_scene.add_child(key)
