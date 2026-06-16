extends Node2D

@onready var marker = $IntroToucanSpawn

func _ready():
	await get_tree().process_frame

	var gs = get_node("/root/GameState")

	gs.unlocked_level_path = "res://Levels/Lvl2/lvl_2a/lvl_2a.tscn"
	gs.save_progress()

	if gs.player:
		gs.player.visible = false
		gs.player.set_physics_process(false)
		gs.player.set_process(false)
		gs.player.velocity = Vector2.ZERO
		
	$Node2D/Sound/lvl2.play()
	await get_tree().process_frame

	start_cinematic()

	
	# Caméra + assombrissement Moko
	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.limit_bottom = 1100
		cam.limit_right = 2500

		var moko = gs.player
		moko.get_node("Node2D/Sprite").modulate = Color(0.985, 0.791, 0.76, 1.0)

func start_cinematic():
	var cine = preload("res://Levels/Lvl2/lvl_2a/CinematicToucan/cinematic_toucan.tscn").instantiate()
	get_tree().current_scene.add_child(cine)
	
	# Position sur le marker
	cine.global_position = marker.global_position
