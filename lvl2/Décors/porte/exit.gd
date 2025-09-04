extends Area2D

@export var next_scene_path: String = "res://lvl2/lvl2b.tscn"

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	var anim_player = body.get_node("Anim")
	if anim_player.has_animation("door"):
		body.animation_locked = true
		anim_player.play("door")
		await anim_player.animation_finished
		body.set_physics_process(false)
		await change_scene()

func change_scene() -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return

	#if gs.fade:
		#await gs.fade.fade_out()

	await get_tree().create_timer(0.2).timeout
	gs.change_scene(next_scene_path)
