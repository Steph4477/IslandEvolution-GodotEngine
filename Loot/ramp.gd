extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("unlock_ramp"):
			body.unlock_ramp()  # 🧠 Débloque la compétence côté joueur
		queue_free()  # 🧹 Supprime le loot une fois ramassé
