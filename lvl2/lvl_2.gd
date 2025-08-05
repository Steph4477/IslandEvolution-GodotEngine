extends Node2D

func _ready():
	print_tree_pretty()
	var paralaxe_fond = $ParalaxeFond
	if paralaxe_fond:
		var pb = paralaxe_fond.get_node("ParallaxBackground")
		if pb:
			var layer = pb.get_node("ParallaxLayer_fond")
			if layer:
				layer.motion_scale = Vector2(0.5, 0.5)
			
