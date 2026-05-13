extends Node2D

@onready var player_spawn = $World/Arena/Visual/SpawnPoint
@onready var toucan = $World/Toucan
@onready var fake_moko = $World/IntroCinematic/FakeMoko
@onready var anim = $World/IntroCinematic/CameraCinematic/AnimationPlayer
@onready var scene_camera = $World/IntroCinematic/Camera2D
@onready var tribune_thrower = $World/Arena/TribuneThrower

@onready var snake_spawn_1 = $World/Arena/WavesEnemies/WaveSnake/SnakeSpawn1
@onready var snake_spawn_2 = $World/Arena/WavesEnemies/WaveSnake/SnakeSpawn2
@onready var snake_spawn_3 = $World/Arena/WavesEnemies/WaveSnake/SnakeSpawn3

var intro_finished = false
var enemies_alive = 0
var snake_wave_finished = false

var snake_scene = preload("res://Enemies/Snake/snake.tscn")

func _ready():
	start_intro()

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
	anim.play("zoom_out_camera")
	start_snake_wave()

func _process(_delta):

	# --- Verification des serpents encore vivants ---
	if enemies_alive > 0 and snake_wave_finished == false:

		update_wave_state()

		if enemies_alive <= 0:
			snake_wave_finished = true
			end_snake_wave()

# ============================================================================
#                          MAITRISE DU PUBLIQUE
# ============================================================================
func start_public_anim():
	get_tree().call_group("public_cannibal", "start_public_anim")


func stop_public_anim():
	get_tree().call_group("public_cannibal", "stop_public_anim")

# ============================================================================
#                           CINEMATIQUE D'INTRODUCTION
# ============================================================================
func start_intro():
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

# ============================================================================
#                           VAGUES D'ENEMIES
# ============================================================================

# --- Vague de serpents ---
func start_snake_wave():
	spawn_snake(snake_spawn_1.global_position)
	spawn_snake(snake_spawn_2.global_position)
	spawn_snake(snake_spawn_3.global_position)

	await get_tree().process_frame

	update_wave_state()

func spawn_snake(spawn_position):
	var snake = snake_scene.instantiate()
	$World/Arena/WavesEnemies.add_child(snake)
	snake.global_position = spawn_position
	snake.add_to_group("snake")
	snake.z_index = 15
	snake.get_node("Rotator/Sprite2D").scale.x *= -1

func update_wave_state():
	var snakes = get_tree().get_nodes_in_group("snake")
	enemies_alive = snakes.size()

func end_snake_wave():
	start_public_anim()
	
	await get_tree().create_timer(0.5).timeout
	tribune_thrower.throw_snake_wave = true

	await get_tree().create_timer(0.5).timeout
	stop_public_anim()
