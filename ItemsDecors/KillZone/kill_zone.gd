extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	var game_state = get_node_or_null("/root/GameState")
	if body.has_method("on_hit"):
		var damage = game_state.player.max_pv
		body.on_hit(damage)
