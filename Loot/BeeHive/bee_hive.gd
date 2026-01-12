extends Node2D

@export var bee_scene = preload("res://Enemies/Bee/bee.tscn")
@export var honey_loot_scene = preload("res://Loot/Honey/honey.tscn")

@export var bee_count = 5
@export var spawn_radius = 280

@onready var spawn_timer = $SpawnTimer

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		spawn_timer.start()

func _on_spawn_timer_timeout():
	# Spawn des abeilles
	for i in range(bee_count):
		var bee = bee_scene.instantiate()
		get_parent().add_child(bee)

		var offset = Vector2(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(-spawn_radius, spawn_radius)
		)

		bee.global_position = global_position + offset
		bee.z_index = 20

	# Spawn du miel (une seule fois)
	var loot = honey_loot_scene.instantiate()
	get_parent().add_child(loot)
	loot.global_position = global_position
	loot.z_index = 20

	queue_free()
