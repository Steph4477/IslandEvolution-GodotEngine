extends ParallaxBackground
#
#@export var layer_path: NodePath = NodePath("WaterLayer")
#@export var sprite_path: NodePath = NodePath("WaterLayer/WaterSprite")
#@export var scroll_speed: Vector2 = Vector2(50.0, 0.0) # px/s
#@export var fallback_texture_size: Vector2 = Vector2(1024, 512) # au cas où
#
#var layers = null
#var sprite = null
#
#func _ready():
	##scroll_ignore_camera = true
#
	#layers = get_node_or_null(layer_path)
	#if layer == null:
		#push_error("[Water] ParallaxLayer introuvable au path: " + str(layer_path))
		#return
#
	#sprite = get_node_or_null(sprite_path)
	#if sprite == null:
		#push_error("[Water] Sprite2D introuvable au path: " + str(sprite_path))
		#return
#
	## S'assure que le Sprite a le temps de charger sa texture
	#await get_tree().process_frame
	#await get_tree().process_frame
#
	#var tex_size = Vector2.ZERO
	#if sprite.texture != null:
		#tex_size = sprite.texture.get_size() * sprite.scale
	#else:
		#push_warning("[Water] Aucune texture sur le Sprite2D. J'utilise la taille de secours.")
		#tex_size = fallback_texture_size * sprite.scale
#
	## Important : Centered OFF sur le Sprite2D pour éviter une couture visible
	## (à régler dans l’inspecteur)
	#layers.motion_mirroring = tex_size
	#sprite.position = Vector2.ZERO
#
#func _process(delta):
	#scroll_offset += scroll_speed * delta
	## on évite les gros nombres
	#if scroll_offset.x > 4096.0:
		#scroll_offset.x = 0.0
	#if scroll_offset.y > 4096.0:
		#scroll_offset.y = 0.0
