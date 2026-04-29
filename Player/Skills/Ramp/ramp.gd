extends Node2D

var gs

func _ready():
	gs = get_node("/root/GameState")
	
	# Si le sprint est déjà looté, on la supprime
	if gs.sprint_unlocked:
		queue_free()

func _on_area_2d_body_entered(body):
	if not body.is_in_group("Player"):
		return
	
	body.collect_skills.collect_ramp()
	
	if body.popups_mod:
		body.popups_mod.show_info("Appuie sur 'Ctrl' pour ramper")
	
	queue_free()
