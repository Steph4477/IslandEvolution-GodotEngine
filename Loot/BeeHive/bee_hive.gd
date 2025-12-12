extends Node2D

@export var bee_scene = preload("res://Enemies/Bee/bee.tscn")
@export var spawn_radius = 74.0
@export var one_shot = true

@onready var sprite = $Sprite2D

var has_spawned = false


func _on_area_2d_body_entered(body):
	# On ne réagit qu'au joueur
	if not body.is_in_group("Player"):
		return

	# Si déjà déclenchée et one_shot, on ne refait rien
	if one_shot and has_spawned:
		return

	_spawn_bee()

	# La ruche sert qu'une fois -> on la supprime
	if one_shot:
		queue_free()


func _spawn_bee():
	has_spawned = true

	if not bee_scene:
		return

	# Instanciation d'une seule abeille
	var bee = bee_scene.instantiate()
	get_parent().add_child(bee)
	
	# --- Z-INDEX AU POP ---
	bee.z_index = 20
	
	# Placement de l’abeille autour de la ruche
	var angle = randf() * TAU              # direction aléatoire
	var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
	bee.global_position = global_position + offset
