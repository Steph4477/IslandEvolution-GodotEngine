extends Node2D


func _ready():
	#$Node2D/Sound/lvl2.play()
	await get_tree().process_frame

	var gs = get_node("/root/GameState")

	if gs.hud:
		gs.hud.visible = false

	if gs.player:
		var cam = gs.player.get_node("Camera2D")
		cam.limit_bottom = 1080
		cam.limit_right = 1920
		
		var moko = gs.player
		moko.scale = Vector2(2, 2)
		
		moko.speed = 800


func await_sound_cinematic():
	await get_tree().create_timer(5).timeout
	$Node2D/Sound/lvl2.play()
