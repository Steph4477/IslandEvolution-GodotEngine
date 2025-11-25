extends Node2D

func _ready():
	$LeafSprite.visible = true
	$HoleSprite.visible = false
	
	# Le piège est actif au départ
	$LeafArea/CollisionShape2D.disabled = false
	$Harrow.visible = false

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		# Visuel
		$LeafSprite.visible = false
		$HoleSprite.visible = true
		$Harrow.visible = true
		
		# Désactive la colision des feuilles en differé
		$LeafArea/CollisionShape2D.set_deferred("disabled", true)
