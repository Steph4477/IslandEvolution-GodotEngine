extends Node2D

var current = Vector2(-120, 0)  # force du courant

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.is_swimming = true
		body.water_current = current

func _on_area_2d_body_exited(body):
	print("[SwimZone] exited:", body.name)
	if body.is_in_group("Player"):
		body.is_swimming = false
		body.water_current = Vector2.ZERO
