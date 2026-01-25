extends Node2D

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.can_climb = true

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		body.can_climb = false
