extends Node2D

@onready var player_spawn = $World/Arena/SpawnPoint
@onready var toucan = $World/Toucan
@onready var fake_moko = $World/IntroCinematic/FakeMoko
@onready var fake_moko_anim = $World/IntroCinematic/CameraCinematic/AnimationPlayer
@onready var scene_camera = $World/IntroCinematic/Camera2D

func _ready():
	var gs = get_node("/root/GameState")

	await get_tree().process_frame

	var player = gs.player
	var player_camera = player.get_node("Camera2D")

	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = player_spawn.global_position
	player.scale = Vector2(0.8, 0.8)

	player_camera.enabled = false

	toucan.visible = false
	toucan.process_mode = Node.PROCESS_MODE_DISABLED

	scene_camera.enabled = true
	scene_camera.make_current()

	player_camera.zoom = Vector2(0.75, 0.75)

	fake_moko.visible = true
	fake_moko_anim.play("intro")


func end_intro():
	var gs = get_node("/root/GameState")
	var player = gs.player
	var player_camera = player.get_node("Camera2D")
	var fade = gs.fade

	fade.fade_out()

	await get_tree().create_timer(0.5).timeout

	fake_moko.queue_free()

	player.visible = true
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.global_position = player_spawn.global_position

	toucan.visible = true
	toucan.process_mode = Node.PROCESS_MODE_INHERIT

	await get_tree().process_frame

	scene_camera.enabled = false

	player_camera.enabled = true
	player_camera.make_current()
	player_camera.limit_right = 1900
	player_camera.limit_bottom = 1750

	fade.fade_in()


func _on_animation_player_animation_finished(_anim_name):
	end_intro()
