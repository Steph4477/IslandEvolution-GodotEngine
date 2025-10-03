extends ParallaxBackground

@export var sky_speed: Vector2 = Vector2(8.0, 0.0)     # vitesse du ciel (lent)
@export var water_speed: Vector2 = Vector2(-60.0, 0.0)  # vitesse de l’eau (rapide)

@onready var sky_layer: ParallaxLayer = $SkyLayer
@onready var water_layer: ParallaxLayer = $WaterLayer

func _process(delta: float) -> void:
	if sky_layer:
		sky_layer.motion_offset += sky_speed * delta
	if water_layer:
		water_layer.motion_offset += water_speed * delta
