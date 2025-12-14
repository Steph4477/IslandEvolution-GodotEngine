extends Node2D

func _on_area_2d_body_entered(body):
	if body.has_method("collect_double_jump"):
		body.collect_double_jump()
	queue_free()
