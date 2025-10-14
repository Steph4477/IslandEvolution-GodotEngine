extends Node2D

func _ready():
	## Musique de fond
	$Node2D/Sound/lvl2.play()
	
	## On attend pour tout charger
	await get_tree().process_frame
#
	## Récupéreration du game state
	var gs = get_node("/root/GameState")
	
	# Assombrissement de Moko
	if gs.player:
		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)
		
