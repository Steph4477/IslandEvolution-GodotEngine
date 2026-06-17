extends Node2D

var gs

func _ready():
	gs = get_node("/root/GameState")

	if gs.ramp_unlocked:
		queue_free()

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
	
		body.collect_skills.collect_ramp()
	
		queue_free()
