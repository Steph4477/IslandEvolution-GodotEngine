
extends Node2D

@export var seed_value = 1

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("collect_seed"):
		body.collect_seed(1) 
		queue_free()
