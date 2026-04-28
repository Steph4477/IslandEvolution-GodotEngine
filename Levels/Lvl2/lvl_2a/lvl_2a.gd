extends Node2D

func _ready():
	$Node2D/Sound/lvl2.play()
	await get_tree().process_frame

	var gs = get_node("/root/GameState")
	
	# Caméra + assombrissement Moko
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.limit_bottom = 1100
		cam.limit_right = 2500

		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.985, 0.791, 0.76, 1.0)
