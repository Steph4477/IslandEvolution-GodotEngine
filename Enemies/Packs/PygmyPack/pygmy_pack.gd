extends Node2D


@export var pyg_distance_scene = preload("res://Enemies/Pygmy/PygmyDistance/pygmy_distance.tscn")
@export var pyg_melee_scene = preload("res://Enemies/Pygmy/PygmyMelee/pygmy_melee.tscn")
@export var pyg_heal_scene = preload("res://Enemies/Pygmy/PygmyHeal/pygmy_heal.tscn")

@onready var spawn_1 = $Spawn1
@onready var spawn_2 = $Spawn2
@onready var spawn_3 = $Spawn3

var gs = null


func _ready():
	gs = get_node("/root/GameState")
	spawn_pack()


func spawn_pack():
	if gs.difficulty == "explorer":
		spawn_enemy(pyg_melee_scene, spawn_1)
		spawn_enemy(pyg_melee_scene, spawn_2)
		spawn_enemy(pyg_melee_scene, spawn_3)

	elif gs.difficulty == "survivor":
		spawn_enemy(pyg_melee_scene, spawn_1)
		spawn_enemy(pyg_distance_scene, spawn_2)
		spawn_enemy(pyg_melee_scene, spawn_3)

	elif gs.difficulty == "king":
		spawn_enemy(pyg_melee_scene, spawn_1)
		spawn_enemy(pyg_distance_scene, spawn_2)
		spawn_enemy(pyg_heal_scene, spawn_3)


func spawn_enemy(scene, spawn_point):
	var enemy = scene.instantiate()
	add_child(enemy)
	enemy.global_position = spawn_point.global_position
