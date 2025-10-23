extends Node2D

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.has_flower = true          # enregistre l'état global
			gs.signal_flower_collected()  # émet le signal global

		queue_free()
