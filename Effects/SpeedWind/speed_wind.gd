extends Area2D

@export var boosted_speed = 1500.0    # vitesse boostée dans la zone
var player = null
var original_speed = 0.0

func _ready ():
	$Sprite2D.visible = false

func _physics_process(_delta):
	if player:
		# bloque totalement la gravité
		player.velocity.y = 0

func _on_body_entered(body):
	$Sprite2D.visible = true
	if body.is_in_group("Player"):
		var gs = get_node("/root/GameState")
		player = gs.player
		if player:
			original_speed = player.speed
			player.speed = boosted_speed

func _on_body_exited(body):
	$Sprite2D.visible = false
	if body.is_in_group("Player"):
		if player:
			player.speed = original_speed
		player = null
