extends RigidBody2D

@export var flaque_texture: Texture2D

func _ready() -> void:
	# Joue l'animation d'écrasement
	$AnimationPlayer.play("splat_flatten")
	
	await $AnimationPlayer.animation_finished

	# Figer la bave : elle ne doit plus bouger
	freeze = true
	gravity_scale = 2
	linear_velocity = Vector2.ZERO
	angular_velocity = 2

	# Applique la texture aplatie
	$Sprite2D.texture = flaque_texture
	
