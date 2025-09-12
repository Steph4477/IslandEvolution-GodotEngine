extends Area2D

@export var boosted_speed = 1500.0    # vitesse boostée dans la zone
var player = null
var original_speed = 0.0

func _physics_process(delta):
	if player:
		# bloque totalement la gravité
		player.velocity.y = 0
		# la vitesse horizontale est gérée par le script du Player,
		# mais avec speed boostée => il va filer très vite
		print("[WindArea] boost actif → speed=", player.speed, " vx=", player.velocity.x)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var gs = get_node("/root/GameState")
		player = gs.player
		if player:
			original_speed = player.speed
			player.speed = boosted_speed
			print("[WindArea] Player détecté:", player.name, " speed boosté à", player.speed)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		if player:
			player.speed = original_speed
			print("[WindArea] Player sorti → speed remis à", original_speed)
		player = null
