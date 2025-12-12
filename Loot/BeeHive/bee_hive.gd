extends Node2D

@export var bee_scene = preload("res://Enemies/Bee/bee.tscn")
@export var honey_loot_scene = preload("res://Loot/Honey/honey.tscn")

@onready var spawn_timer = $SpawnTimer

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		spawn_timer.start()

func _on_spawn_timer_timeout():
	var bee = bee_scene.instantiate()
	get_parent().add_child(bee)
	bee.global_position = global_position
	bee.z_index = 20

	var loot = honey_loot_scene.instantiate()
	get_parent().add_child(loot)
	loot.global_position = global_position
	loot.z_index = 20

	queue_free()
