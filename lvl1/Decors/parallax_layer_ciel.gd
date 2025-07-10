extends ParallaxLayer

@export var scroll_factor := Vector2(-0.1, 0.2)  # Facteur de parallaxe léger pour le ciel

func _process(delta):
	var camera := get_viewport().get_camera_2d()
	if camera:
		motion_offset = camera.global_position * scroll_factor
