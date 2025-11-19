extends Node2D

@export var chrono_zone_path = NodePath("Node2D/ChronoZone")
@export var froggle_scene = preload("res://Enemies/Froggle/froggle.tscn")
@export var froggle_spawn_path = NodePath("Node2D/FroggleSpawn")

@onready var anim = $Node2D/World/AnimationPlayer

var froggle_spawned = false
var focus_cam_frog = false # préparation du focus de la caméra si challenge_win
var cam
var gs

func _ready():
	# Musiques d’ambiance
	$Node2D/Sound/BirdsSound.play()
	$Node2D/Sound/WaterSound.play()
	# --- Limite caméra & assombrissement ---
	await get_tree().process_frame
	gs = get_node("/root/GameState")
	cam = gs.player.get_node("Camera2D")
	cam.limit_top = -250000
	cam.limit_right = 12000
	
	# Position initiale de l’anim “fall” à 0.0
	if anim.has_animation("fall"):
		anim.current_animation = "fall"
		anim.seek(0.0, true)
		anim.stop()
		
	await get_tree().process_frame

# --- Signals ---
func _on_chrono_zone_challenge_win():
	if not gs.focus_cam_frog:
		return
		
	# Bloque Moko pendant tout le focus 
	var player = gs.player
	var prev_can_move = true
	prev_can_move = player.can_move
	player.can_move = false
	
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
		var frog = get_node_or_null("Froggle")
		if frog and cam:
			cam.global_position = frog.global_position
			await get_tree().create_timer(1.0).timeout
			
			var original_zoom = cam.zoom
			var target_zoom_x = 2
			var target_offset = 300.0
			var steps = 30
			var dz = (target_zoom_x - original_zoom.x) / steps
			var dy = target_offset / steps
			
			for i in range(steps):
				cam.zoom.x += dz
				cam.zoom.y += dz
				cam.global_position.y += dy
				await get_tree().process_frame
				
			await get_tree().create_timer(0.5).timeout
			
			var animplayer = frog.get_node("Rotator/AnimationPlayer")
			frog.set_physics_process(false)
			var drool_sound = frog.get_node_or_null("DroolSound")
			if drool_sound:
				drool_sound.stop()
				drool_sound.play()
			animplayer.play("drool")
			await animplayer.animation_finished
			frog.set_physics_process(true)
			
			for i in range(steps):
				cam.zoom.x -= dz
				cam.zoom.y -= dz
				cam.global_position.y -= dy
				await get_tree().process_frame
				
			cam.global_position = gs.player.global_position
		
	# Débloque moko après le focus 
	player.can_move = prev_can_move

func _spawn_froggle():
	froggle_spawned = true
	var spawn_node = get_node_or_null(froggle_spawn_path)
	var spawn_pos = Vector2.ZERO
	if spawn_node:
		spawn_pos = spawn_node.global_position
	
	var frog = froggle_scene.instantiate()
	add_child(frog)
	frog.name = "Froggle"
	frog.global_position = spawn_pos
