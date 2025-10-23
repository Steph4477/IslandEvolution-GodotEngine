extends Node2D

signal flower_collected

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		emit_signal("flower_collected")

		var gs = get_node_or_null("/root/GameState")
		if gs:
			gs.has_key = true
			gs.emit_signal("flower_collected")  # ✅ GameState relaie l'info

		queue_free()
