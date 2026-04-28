extends Node2D

func _ready():
	$Node2D/Sound/lvl2.play()
	await get_tree().process_frame

	var gs = get_node("/root/GameState")

	# Caméra + assombrissement Moko
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.zoom = Vector2(1, 1) # point de départ

		var tween = create_tween()
		tween.tween_property(cam, "zoom", Vector2(0.6, 0.6), 2.0)
		cam.limit_right = 4700
		cam.limit_bottom = 3500
	
		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)
