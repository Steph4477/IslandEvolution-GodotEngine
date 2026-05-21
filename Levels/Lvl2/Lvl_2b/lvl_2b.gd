extends Node2D

@export var dialogue_scene = preload("res://Interface/Dialogue/pyg_dialogue.tscn")

func _ready():
	$Node2D/Sound/lvl2.play()
	await get_tree().process_frame

	var gs = get_node("/root/GameState")
	gs.show_boss_fight_hud(null)

	# Caméra + assombrissement Moko
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.limit_bottom = 1240
		cam.limit_right = 3300
		
		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)
		#moko.can_move = false
#
	## Déjà vu dans cette partie ? -> pas de dialogue, on redonne le contrôle et on garde l'assombrissement
	#if gs.pygmy_dialogue_seen:
		#if gs.player:
			#gs.player.can_move = true
		#return
#
	## Dialogue Pygmée (une seule fois)
	#await get_tree().process_frame
	#await get_tree().create_timer(3).timeout
#
	#var dlg = dialogue_scene.instantiate()
	#dlg.name = "DialogueUI"
	#add_child(dlg)
	#await get_tree().process_frame
	#dlg.start()
	#await dlg.finished
#
	## Marque comme vu
	#gs.pygmy_dialogue_seen = true
#
	## Redonne le contrôle
	#if gs.player:
		#gs.player.can_move = true
