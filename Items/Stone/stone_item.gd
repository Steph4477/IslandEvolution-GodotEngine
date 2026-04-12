extends Area2D

var collected = false

func _on_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_items.collect_stone()
		queue_free()
