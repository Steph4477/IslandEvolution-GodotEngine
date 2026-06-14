extends Node2D

@export var chrono_zone_path = NodePath("Node2D/ChronoZone")
@export var froggle_scene = preload("res://Enemies/Froggle/froggle.tscn")
@export var froggle_spawn_path = NodePath("Node2D/FroggleSpawn")

@onready var anim = $Node2D/World/ChronoChallenge/AnimationPlayer

var froggle_spawned = false
var focus_cam_frog = false # préparation du focus de la caméra si challenge_win
var cam
var gs

# --- Réglages du tremblement caméra et dégâts ---
@export var intensity = 50.0   # Intensité du shake de caméra
@export var duration = 3.0     # Durée du tremblement

func _ready():
	# Musiques d’ambiance
	$Sound/BirdsSound.play()
	$Sound/WaterSound.play()
	# --- Limite caméra & assombrissement ---
	await get_tree().process_frame
	gs = get_node("/root/GameState")

	cam = gs.player.get_node("Camera2D")
	cam.enabled = true
	cam.make_current()

	cam.limit_top = -1500
	cam.limit_right = 25000
	cam.limit_bottom = 1400

	# Position initiale ou finale de l’anim “fall”
	if anim.has_animation("fall"):
		if gs.toucan_fall_done:
			anim.play("fall")
			anim.seek(2.9, true)
			anim.pause()
		else:
			anim.play("fall")
			anim.seek(0.0, true)
			anim.pause()

	if gs.toucan_froggle_spawned and not gs.toucan_challenge_done:
		_spawn_froggle()

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
		
		# Tremblement de la camera à l'impact du tronc dans l'eau avec son
		await get_tree().create_timer(0.8).timeout
		$Sound/WaterSplashTree.play()
		camera_shake(intensity, duration)
		
		await anim.animation_finished

		gs.toucan_fall_done = true
		anim.play("fall")
		anim.seek(2.9, true)
		anim.pause()
		
	# 2) Attente avant spawn
	await get_tree().create_timer(2.0).timeout
	
	# 3) Spawn grenouille
	_spawn_froggle()
	
	# 4) Focus caméra sur la grenouille
	if gs.player:
		var frog = get_node_or_null("Froggle")
		if frog and cam:
			cam.position = frog.global_position - gs.player.global_position
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
				
			cam.position = Vector2.ZERO
		
	# Débloque moko après le focus 
	player.can_move = prev_can_move

func _spawn_froggle():
	if get_node_or_null("Froggle"):
		return

	froggle_spawned = true
	gs.toucan_froggle_spawned = true

	var spawn_node = get_node_or_null(froggle_spawn_path)
	var spawn_pos = Vector2.ZERO
	if spawn_node:
		spawn_pos = spawn_node.global_position
	
	var frog = froggle_scene.instantiate()
	add_child(frog)
	frog.name = "Froggle"
	frog.global_position = spawn_pos

func camera_shake(_intensity, _duration):
	if cam == null:
		return
	var t = create_tween()
	var steps = int(duration / 0.1)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		t.tween_property(cam, "offset", offset, 0.05)
	t.tween_property(cam, "offset", Vector2.ZERO, 0.1)
