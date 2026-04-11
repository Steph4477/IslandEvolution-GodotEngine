extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")

var gs

func _ready():
	gs = get_node("/root/GameState")
	
	# Si le sprint est déjà looté, on la supprime
	if gs.sprint_unlocked:
		queue_free()

func dialogue_toucan():
	var moko = gs.player
	
	moko.can_move = false
	
	var dlg = dialogue_scene.instantiate()
	get_tree().root.add_child(dlg)
	dlg.layer = gs.hud.layer + 1  
	
	var lignes = [
		"Bien joué, Moko !",
		"Tu viens d'apprendre la compétence de sprint sauvage.",
		'Maintiens la touche "Shift" pour sprinter !',
		"Attention, ta barre d'endurance se vide quand tu sprintes."
	]
	dlg.start(lignes)
	await dlg.finished
	
	moko.can_move = true

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.collect_skills.collect_sprint()  # Débloque la compétence côté Moko
		$Area2D/Sprite2D.visible = false
		await dialogue_toucan()
		queue_free()
