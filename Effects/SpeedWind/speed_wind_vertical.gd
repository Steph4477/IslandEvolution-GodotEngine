extends Area2D

#@export var boosted_speed = 1500.0    # vitesse boostée dans la zone
@export var boosted_gravity = -1500.0 # vitesse de gravité
var player = null
#var original_speed = 0.0
var original_gravity = 0.0

#func _physics_process(delta):
	#if player:
		## bloque totalement la gravité
		#player.velocity.y = 0
		## la vitesse horizontale est gérée par le script du Player,
		## mais avec speed boostée => il va filer très vite
		#print("[WindArea] boost actif → speed=", player.speed, " vx=", player.velocity.x)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		var gs = get_node("/root/GameState")
		player = gs.player
		if player:
			original_gravity = 1200.0
			original_gravity = player.gravity
			player.gravity = boosted_gravity
			print("[WindArea] Player détecté:", player.name, " gravité boosté à", player.gravity)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		if player:
			player.gravity = original_gravity
			print("[WindArea] Player sorti → gravité remis à", original_gravity)
		player = null
