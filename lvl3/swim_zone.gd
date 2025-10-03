extends Node2D

@onready var parallax = $ParallaxBackground
@export var scroll_speed: float = 50.0  # règle la vitesse du courant

func _process(delta):
	parallax.scroll_offset.x += scroll_speed * delta
	# Boucle l’offset pour éviter de gros chiffres
	if parallax.scroll_offset.x > 1024:
		parallax.scroll_offset.x = 0

func _on_area2d_body_entered(body):
	if body.is_in_group("Player"):
		body.is_swimming = true
		#body.$Anim.play("swim")
		#body.$Sprite.position.y = 8  # petit effet immergé

func _on_area2d_body_exited(body):
	if body.is_in_group("Player"):
		body.is_swimming = false
		#body.$Anim.play("idle")
		#body.$Sprite.position.y = 0
