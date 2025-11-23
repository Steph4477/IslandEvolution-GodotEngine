extends Node2D


func _on_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		$AnimationPlayer.play("fade")
		await get_tree().create_timer(0.8).timeout
		$Full.visible = false
