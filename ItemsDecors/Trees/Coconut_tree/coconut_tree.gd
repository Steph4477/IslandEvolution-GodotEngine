extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("set_can_climb"):
		body.set_can_climb(true, "climb_coco")  # ou "climb_coco"

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") and body.has_method("set_can_climb"):
		body.set_can_climb(false)
