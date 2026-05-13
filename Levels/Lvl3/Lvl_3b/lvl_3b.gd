extends Node2D

@onready var player_spawn = $World/Arena/SpawnPoint
@onready var toucan = $World/Toucan
@onready var fake_moko = $World/IntroCinematic/FakeMoko
@onready var anim = $World/IntroCinematic/CameraCinematic/AnimationPlayer
@onready var scene_camera = $World/IntroCinematic/Camera2D
@onready var tribune_thrower = $World/Arena/TribuneThrower

var intro_finished = false

func _ready():
	var gs = get_node("/root/GameState")

	await get_tree().process_frame

	var player = gs.player

	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = player_spawn.global_position
	player.scale = Vector2(0.8, 0.8)

	toucan.visible = false
	toucan.process_mode = Node.PROCESS_MODE_DISABLED

	scene_camera.enabled = true
	scene_camera.make_current()

	fake_moko.visible = true
	anim.play("intro")

	# --- vague de loots intro ---
	await get_tree().create_timer(3.5).timeout
	start_public_anim()

	await get_tree().create_timer(0.5).timeout
	stop_public_anim()
	tribune_thrower.throw_intro_wave = true

	# --- Fermeture barrière de dents ---
	await get_tree().create_timer(1.0).timeout
	anim.play("close")

	await anim.animation_finished

	end_intro()

	# --- Spawn vague de serpents ---
	await get_tree().create_timer(2.5).timeout
	start_public_anim()
	anim.play("after_intro")

func start_public_anim():
	get_tree().call_group("public_cannibal", "start_public_anim")


func stop_public_anim():
	get_tree().call_group("public_cannibal", "stop_public_anim")


func end_intro():
	intro_finished = true

	var gs = get_node("/root/GameState")
	var player = gs.player

	await get_tree().create_timer(0.5).timeout

	fake_moko.visible = false

	player.visible = true
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.global_position = player_spawn.global_position

	toucan.visible = true
	toucan.process_mode = Node.PROCESS_MODE_INHERIT

	await get_tree().process_frame
