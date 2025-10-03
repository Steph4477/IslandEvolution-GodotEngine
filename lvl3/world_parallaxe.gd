extends ParallaxBackground

@export var water_speed: Vector2 = Vector2(-40.0, 0.0)  # vitesse de l’eau (rapide)
@onready var water_layer: ParallaxLayer = $WaterLayer

func _process(delta: float) -> void:
	if water_layer:
		water_layer.motion_offset += water_speed * delta
