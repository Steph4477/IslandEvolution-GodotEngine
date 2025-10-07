extends Area2D

@export var next_scene_path: String = "res://lvl3/lvl3.tscn"

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	change_scene()

func change_scene():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	gs.change_scene(next_scene_path)
