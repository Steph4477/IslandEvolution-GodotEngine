extends Area2D

var collected = false

func _on_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_stone()
		
		var gs = get_node("/root/GameState")
		if gs.hud:
			gs.hud.update_fire_craft_checklist()
		
		queue_free()
