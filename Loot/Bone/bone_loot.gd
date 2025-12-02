extends Node2D

@export var bone_value = 1
@export var activate_shooting = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("collect_bone"):
		body.collect_bone(3, true)  
		queue_free()
