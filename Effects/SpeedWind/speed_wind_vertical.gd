extends Area2D

@export var boosted_gravity = -1500.0 # vitesse de gravité
var player = null
var original_gravity = 0.0

func _ready ():
	$Sprite2D.visible = false

func _on_body_entered(body):
	$Sprite2D.visible = true
	if body.is_in_group("Player"):
		var gs = get_node("/root/GameState")
		player = gs.player
		if player:
			original_gravity = 1200.0
			original_gravity = player.gravity
			player.gravity = boosted_gravity

func _on_body_exited(body):
	$Sprite2D.visible = false
	if body.is_in_group("Player"):
		if player:
			player.gravity = original_gravity
		player = null
