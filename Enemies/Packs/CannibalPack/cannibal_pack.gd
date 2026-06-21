extends Node2D


@export var cannibal_distance_scene = preload("res://Enemies/Cannibal/CannibalDistance/cannibal_distance.tscn")
@export var cannibal_melee_scene = preload("res://Enemies/Cannibal/CannibalMelee/cannibal_melee.tscn")
@export var cannibal_heal_scene = preload("res://Enemies/Cannibal/CannibalHeal/cannibal_heal.tscn")

@onready var spawn_1 = $Spawn1
@onready var spawn_2 = $Spawn2
@onready var spawn_3 = $Spawn3

var gs = null


func _ready():
	gs = get_node("/root/GameState")
	spawn_pack()


func spawn_pack():
	if gs.difficulty == "explorer":
		spawn_enemy(cannibal_distance_scene, spawn_1)
		spawn_enemy(cannibal_distance_scene, spawn_2)
		spawn_enemy(cannibal_distance_scene, spawn_3)

	elif gs.difficulty == "survivor":
		spawn_enemy(cannibal_distance_scene, spawn_1)
		spawn_enemy(cannibal_melee_scene, spawn_2)
		spawn_enemy(cannibal_melee_scene, spawn_3)

	elif gs.difficulty == "king":
		spawn_enemy(cannibal_distance_scene, spawn_1)
		spawn_enemy(cannibal_melee_scene, spawn_2)
		spawn_enemy(cannibal_heal_scene, spawn_3)


func spawn_enemy(scene, spawn_point):
	var enemy = scene.instantiate()
	add_child(enemy)
	enemy.global_position = spawn_point.global_position
