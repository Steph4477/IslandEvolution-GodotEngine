extends Node2D

func _ready():
	$LeafSprite.visible = true
	$HoleSprite.visible = false
	$Harrow.visible = false

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		# Visuel
		$LeafSprite.visible = false
		$HoleSprite.visible = true
		$Harrow.visible = true
