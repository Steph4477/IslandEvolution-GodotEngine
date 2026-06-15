extends Node2D

func _ready():
	var gs = get_node_or_null("/root/GameState")

	if gs and gs.has_flower:
		queue_free()
		return

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		var gs = get_node_or_null("/root/GameState")

		if gs:
			gs.has_flower = true
			gs.signal_flower_collected()

		queue_free()
