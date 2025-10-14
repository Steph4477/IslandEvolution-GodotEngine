extends Area2D

@export var next_scene_path = "res://Levels/lvl2/Lvl_2b/lvl_2b.tscn"

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return

	var anim_player = body.get_node("Node2D/Anim")
	if anim_player.has_animation("door_2"):
		body.animation_locked = true
		anim_player.play("door_2")
		await anim_player.animation_finished
		body.set_physics_process(false)
		change_scene()

func change_scene():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	gs.change_scene(next_scene_path)
