extends Control

@export var clean_delay = 15.0
var texture = null

@onready var texture_rect = $TextureRect
@onready var anim = $AnimationPlayer


func start():
	# Appliquer la texture reçue au TextureRect
	texture_rect.texture = texture

	# Force la taille du node à celle de la texture
	texture_rect.size = texture.get_size()

	# Centre le point de rotation / scale pour que les animations soient propres.
	texture_rect.pivot_offset = texture_rect.size * 0.5

	anim.play("appear")

	await get_tree().create_timer(clean_delay).timeout

	anim.play("disappear")
	await anim.animation_finished

	queue_free()
