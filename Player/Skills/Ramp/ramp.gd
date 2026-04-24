extends Node2D

func _on_area_2d_body_entered(body):
	if not body.is_in_group("Player"):
		return
	
	body.collect_skills.collect_ramp()
	
	if body.popups_mod:
		body.popups_mod.show_info("Appuie sur 'Ctrl' pour ramper")
	
	queue_free()
