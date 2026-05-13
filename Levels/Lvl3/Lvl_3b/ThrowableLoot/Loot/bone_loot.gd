extends Node2D

@export var bone_value = 1
@export var activate_shooting = false

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.collect_items.collect_bone(3, true)
		queue_free()
