extends Node2D

func _ready():
	$Sound/lvl2.play()
	# Répetition du paralaxe
	var paralaxe_fond = $ParalaxeFond
	if paralaxe_fond:
		var pb = paralaxe_fond.get_node("ParallaxBackground")
		if pb:
			var layer = pb.get_node("ParallaxLayer_fond")
			if layer:
				layer.motion_scale = Vector2(0.5, 0.5)
	
	await get_tree().process_frame  
	
	# Assombrissement de Moko
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.player:
		var moko = gs.player
		moko.get_node("Sprite").modulate = Color(0.4, 0.4, 0.4)  
