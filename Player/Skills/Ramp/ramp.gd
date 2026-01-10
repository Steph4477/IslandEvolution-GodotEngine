extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/toucan_dialogue.tscn")

var gs

func _ready():
	gs = get_node("/root/GameState")
	
	# 👇 Si la compétence Ramp est déjà débloquée, on supprime l'orbe
	if gs.ramp_unlocked:
		queue_free()

func dialogue_toucan():
	#on va chercher le joueur du gs et on bloque son mouvement
	if gs.player:
		var moko = gs.player
		
		# 🔒 une fois bloqué on le passe en anim "idle"
		moko.can_move = false
		# passe monko en anim "idle"
		var anim = moko.get_node_or_null("Node2D/Anim")
		anim.play("idle")
		
	# Insertion en enfant de la scène le dialogue du toucan
	var dlg = dialogue_scene.instantiate()
	get_tree().root.add_child(dlg)
	dlg.layer = gs.hud.layer + 1  
	
	# répliques du toucan
	var lignes = [
		"Bien joué, Moko !",
		"Tu viens d'apprendre la compétence pour ramper.",
		'Appuie sur la touche "Contrôle" pour te faufiler partout !',
		"Avance un peu, tu trouveras la sortie 😎"
	]
	dlg.start(lignes)
	await dlg.finished
	
	# 🔓 Réactive le mouvement de Moko après le dialogue
	gs.player.can_move = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	
	# Si déjà débloqué (sécurité supplémentaire), on ne fait rien
	if gs.ramp_unlocked:
		queue_free()
		return
	
	body.unlock_ramp()  # 🧠 Débloque la compétence côté joueur
	
	var loot = $Area2D/Sprite2D
	loot.visible = false
	
	await dialogue_toucan()
	queue_free()  # 🧹 Supprime le loot une fois ramassé
