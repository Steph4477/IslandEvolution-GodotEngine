extends Area2D

@export var next_scene_path: String

func _on_body_entered(body):
	if body.name == "Player": 
		if body.has_node("anim"):
			var anim_player = body.get_node("anim")
			if anim_player is AnimationPlayer and anim_player.has_animation("door"):

				# 🔒 Verrouille mouvement + anim
				body.animation_locked = true
				body.set_physics_process(false)

				anim_player.play("door")
				await anim_player.animation_finished
				change_scene()

func change_scene():
	await get_tree().create_timer(0.2).timeout
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.load_level(next_scene_path)
