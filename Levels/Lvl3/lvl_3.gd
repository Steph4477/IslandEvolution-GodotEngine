extends Node2D

@export var chrono_zone_path = NodePath("Node2D/ChronoZone")
@export var froggle_scene = preload("res://Enemies/Froggle/froggle.tscn")
@export var froggle_spawn_path = NodePath("Node2D/FroggleSpawn")

@onready var anim = $Node2D/World/AnimationPlayer

var _froggle_spawned = false
var focus_cam_frog = false # préparation du focus de la caméra si challenge_win

func _ready():
	# Musiques d’ambiance
	$Node2D/Sound/BirdsSound.play()
	$Node2D/Sound/WaterSound.play()
	
	# Position initiale de l’anim “fall” à 0.0
	if anim.has_animation("fall"):
		anim.current_animation = "fall"
		anim.seek(0.0, true)
		anim.stop()
		
	await get_tree().process_frame
	
	# Assombrissement de Moko au chargement
	var gs = get_node("/root/GameState")
	if gs.player:
		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.4, 0.4, 0.4)

# --- Signals ---
func _on_chrono_zone_challenge_win():
	# 0) Vérifie le flag global
	var gs = get_node("/root/GameState")
	if not gs.focus_cam_frog: # si le challenge n'est pas win on declenche pas le focus
		return
		
	# 1) Chute des lianes
	if anim.has_animation("fall"):
		anim.play("fall")
		await anim.animation_finished
		
	# 2) Attente avant spawn
	await get_tree().create_timer(2.0).timeout
		
	# 3) Spawn grenouille
	_spawn_froggle()
		
	# 4) Focus caméra sur la grenouille
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		var frog = get_node_or_null("Froggle")
		if frog and cam:
			cam.global_position = frog.global_position
			await get_tree().create_timer(1.0).timeout
			
			# 5) Zoom + descente (sans lerp, usage exact de target_offset)
			var original_zoom = cam.zoom                       # position initial du zoom
			var target_zoom_x = 2                              # zoom final (x2)
			var target_offset = 300.0                          # descente totale en px
			var steps = 30                                     # fluidité du zoom (nombre de tours)
			
			# Incréments exacts à chaques tours de boucle
			var dz = (target_zoom_x - original_zoom.x) / steps # zoom par tour
			var dy = target_offset / steps                     # position par tour
			
			# on applique dz et dy à chaques tours
			for i in range(steps):
				cam.zoom.x += dz
				cam.zoom.y += dz
				cam.global_position.y += dy
				await get_tree().process_frame
				
			await get_tree().create_timer(0.5).timeout
			
			# 6) Lancer anim "drool" de la grenouille (forcée)
			var animplayer = frog.get_node("Rotator/AnimationPlayer")
			frog.set_physics_process(false)  # évite qu'idle écrase drool
				
			# 7) Ajout du son
			var drool_sound = frog.get_node_or_null("DroolSound")
			if drool_sound:
				drool_sound.stop()
				drool_sound.play()
			
			animplayer.play("drool")
			await animplayer.animation_finished
			frog.set_physics_process(true)
			
			# 7) Retour de la caméra sur Moko
			for i in range(steps):
				cam.zoom.x -= dz
				cam.zoom.y -= dz
				cam.global_position.y -= dy
				await get_tree().process_frame
				
			# 8) Retour caméra sur le joueur
			cam.global_position = gs.player.global_position

func _spawn_froggle():
	_froggle_spawned = true
	var spawn_node = get_node_or_null(froggle_spawn_path)
	var spawn_pos = Vector2.ZERO
	if spawn_node:
		spawn_pos = spawn_node.global_position
	
	var frog = froggle_scene.instantiate()
	add_child(frog)
	frog.name = "Froggle"
	frog.global_position = spawn_pos
