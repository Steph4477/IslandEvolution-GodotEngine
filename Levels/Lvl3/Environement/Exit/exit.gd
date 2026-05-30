extends Area2D

@export var next_scene_path = "res://Levels/Lvl4/lvl_4.tscn"

func _on_body_entered(_body):
	change_scene()

func change_scene():
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return

	# --- Affichage des statistiques de fin de niveau ---
	gs.score_system.print_level_stats()

	gs.load_level(next_scene_path)
