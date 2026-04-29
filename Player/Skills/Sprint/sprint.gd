extends Node2D

var gs

func _ready():
	gs = get_node("/root/GameState")
	
	# Si le sprint est déjà looté, on la supprime
	if gs.sprint_unlocked:
		queue_free()

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.collect_skills.collect_sprint()  # Débloque la compétence côté Moko
		$Area2D/Sprite2D.visible = false

		queue_free()
