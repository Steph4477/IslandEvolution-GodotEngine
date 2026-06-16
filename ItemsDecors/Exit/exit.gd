extends Area2D

@export var next_scene_path = "res://Levels/Lvl3/lvl_3.tscn"

func _on_body_entered(body):
	print("EXIT BODY ENTERED : ", body.name)
	if body.name != "Player":
		return

	change_scene()

func change_scene():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return

	gs.unlocked_level_path = next_scene_path
	gs.save_progress()
	print("EXIT NEXT SCENE : ", next_scene_path)
	gs.load_level(next_scene_path)
