extends Node2D

@onready var player_spawn = $World/Arena/Visual/SpawnPoint
@onready var toucan = $World/Toucan
@onready var fake_moko = $World/IntroCinematic/FakeMoko
@onready var anim = $World/IntroCinematic/CameraCinematic/AnimationPlayer
@onready var scene_camera = $World/IntroCinematic/Camera2D
@onready var tribune_thrower = $World/Arena/TribuneThrower

@onready var snake_spawn_1 = $World/Arena/Visual/WavesEnemies/WaveSnake/Snake
@onready var snake_spawn_2 = $World/Arena/Visual/WavesEnemies/WaveSnake/Snake2
@onready var snake_spawn_3 = $World/Arena/Visual/WavesEnemies/WaveSnake/Snake3

@onready var croco_spawn_1 = $World/Arena/Visual/WavesEnemies/WaveCroco/AmphibiousCroco
@onready var croco_spawn_2 = $World/Arena/Visual/WavesEnemies/WaveCroco/AmphibiousCroco2

@onready var cannibal_spawn_1 = $World/Arena/Visual/WavesEnemies/WaveCannibal/Cannibal
@onready var cannibal_spawn_2 = $World/Arena/Visual/WavesEnemies/WaveCannibal/Cannibal2

@onready var boss_spawn = $World/Arena/Visual/WavesEnemies/WaveBoss/BossCannibal

# --- Discours du boss ---
@onready var text = $World/Arena/Boss_Speech/Box/MarginContainer/Text
@onready var box  = $World/Arena/Boss_Speech/Box
@onready var speech_anim = $World/Arena/Boss_Speech/AnimationPlayer
@onready var reveal_anim = $World/Arena/Visual/AnimationPlayer
@onready var reveal_boss_anim = $World/RevealBoss/AnimationPlayer
@onready var fake_boss = $World/RevealBoss/FakeBoss

@export var speech_snake_wave = [
	"Tu n'aurais jamais dû entrer ici...",
	"Tuez-le ! 😡"
]

@export var speech_croco_wave = [
	"Tu as survécu aux serpents...",
	"Résisteras-tu à mes bêtes ?"
]

@export var speech_cannibals_wave = [
	"Tu tiens encore debout...",
	"Guerriers ! Brisez-le !"
]

@export var speech_combat_boss = [
	"Assez joué...",
	"Je vais m'occuper de toi moi-même !"
]

@export var pause_between_lines = 2.0   # Pause entre les lignes (s)

var intro_finished = false


func _ready():
	disable_enemy(snake_spawn_1)
	disable_enemy(snake_spawn_2)
	disable_enemy(snake_spawn_3)

	disable_enemy(croco_spawn_1)
	disable_enemy(croco_spawn_2)

	disable_enemy(cannibal_spawn_1)
	disable_enemy(cannibal_spawn_2)

	disable_enemy(boss_spawn)
	start_intro()
	
	# --- anim des grilles ---
	await get_tree().create_timer(1.0).timeout
	reveal_anim.play("close_door")

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
#
	## --- Spawn vague de serpents ---
	#await start_speech(speech_snake_wave)
#
	#await get_tree().create_timer(2.0).timeout
	#start_public_anim()
#
	#anim.play("zoom")
	#await anim.animation_finished
	#
	#reveal_anim.play("open_grid_right")
	#await reveal_anim.animation_finished
	#
	#start_snake_wave()
#
	#reveal_anim.play("close_grid_right")
	#await reveal_anim.animation_finished
	#
	#await wait_finish_snake_wave()
#
	## --- Loot fin vague serpents ---
	#anim.play("zoom_out")
	#
	#start_public_anim()
	#
	#await get_tree().create_timer(0.5).timeout
	#tribune_thrower.throw_snake_wave = true
#
	#await get_tree().create_timer(1.0).timeout
	#stop_public_anim()
#
	## --- Spawn vague de crocos ---
	#await start_speech(speech_croco_wave)
#
	#await get_tree().create_timer(2.0).timeout
	#start_public_anim()
	#
	#anim.play("zoom")
	#await anim.animation_finished
#
	#reveal_anim.play("open_grid_left")
	#await reveal_anim.animation_finished
	#
	#start_croco_wave()
#
	#reveal_anim.play("close_grid_left")
	#await reveal_anim.animation_finished
#
#
	#await wait_finish_croco_wave()
#
	## --- Loot fin vague crocos ---
	#anim.play("zoom_out")
	#await anim.animation_finished
	#start_public_anim()
	#
	#await get_tree().create_timer(0.5).timeout
	#tribune_thrower.throw_croco_wave = true
#
	#await get_tree().create_timer(1.0).timeout
	#stop_public_anim()
#
	## --- Spawn vague de cannibales ---
	#await start_speech(speech_cannibals_wave)
#
	#await get_tree().create_timer(2.0).timeout
	#start_public_anim()
	#
	#anim.play("zoom")
	#await anim.animation_finished
	#
	#reveal_anim.play("open_grid_right")
	#await reveal_anim.animation_finished
	#
	#start_cannibal_wave()
#
	#reveal_anim.play("close_grid_right")
	#await reveal_anim.animation_finished
	#
	#await wait_finish_cannibal_wave()
#
	## --- Loot fin vague cannibales ---
	#anim.play("zoom_out")
#
	#start_public_anim()
	#
	#await get_tree().create_timer(0.5).timeout
	#tribune_thrower.throw_cannibal_wave = true
#
	#await get_tree().create_timer(1.0).timeout
	#stop_public_anim()
#
	## --- Discours combat boss ---
	#await start_speech(speech_combat_boss)
#
	#await get_tree().create_timer(1.0).timeout
	#start_public_anim()
#
	## --- Cinematique de l'aparition du boss ---
	#anim.play("zoom_boss")
	#await anim.animation_finished
	#reveal_anim.play("open_door")
	#await reveal_anim.animation_finished
#
	#fake_boss.visible = true
#
	#reveal_boss_anim.play("reveal_boss")
	#await reveal_boss_anim.animation_finished
	#
	#reveal_anim.play("close_door")
	#await reveal_anim.animation_finished
#
	#fake_boss.visible = false
#
	#anim.play("zoom")
	#await anim.animation_finished
	start_boss_wave()

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
	player.scale = Vector2(2, 2)
	player.speed = 800

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

	player.z_index = 40

	toucan.visible = true
	toucan.process_mode = Node.PROCESS_MODE_INHERIT

	await get_tree().process_frame


# ============================================================================
#                           VAGUES D'ENNEMIS
# ============================================================================
func disable_enemy(enemy):
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED

func enable_enemy(enemy):
	enemy.visible = true
	enemy.process_mode = Node.PROCESS_MODE_INHERIT

# --- Vague de Serpents ---
func start_snake_wave():
	spawn_snake(snake_spawn_1)
	spawn_snake(snake_spawn_2)
	spawn_snake(snake_spawn_3)

func spawn_snake(snake):
	enable_enemy(snake)
	snake.add_to_group("snake")
	snake.get_node("Rotator/Sprite2D").scale.x *= -1

func wait_finish_snake_wave():
	await get_tree().process_frame

	while get_tree().get_nodes_in_group("snake").size() > 0:
		await get_tree().process_frame

# --- Vague de Crocos ---
func start_croco_wave():
	spawn_croco(croco_spawn_1)
	spawn_croco(croco_spawn_2)

func spawn_croco(croco):
	enable_enemy(croco)
	croco.add_to_group("croco")

func wait_finish_croco_wave():
	await get_tree().process_frame

	while get_tree().get_nodes_in_group("croco").size() > 0:
		await get_tree().process_frame

# --- Vague de Cannibales ---
func start_cannibal_wave():
	spawn_cannibal(cannibal_spawn_1)
	spawn_cannibal(cannibal_spawn_2)

func spawn_cannibal(cannibal):
	enable_enemy(cannibal)
	cannibal.add_to_group("cannibal")

func wait_finish_cannibal_wave():
	await get_tree().process_frame

	while get_tree().get_nodes_in_group("cannibal").size() > 0:
		await get_tree().process_frame

# --- Vague Boss ---
func start_boss_wave():
	spawn_boss(boss_spawn)

func spawn_boss(boss):
	enable_enemy(boss)
	boss.add_to_group("boss")

# ============================================================================
#                           DISCOURS DU BOSS
# ============================================================================
func start_speech(lines):
	text.text = ""

	for line in lines:
		text.text = "[center][b]" + line + "[/b][/center]"

		speech_anim.play("speech_in")
		await speech_anim.animation_finished

		await get_tree().create_timer(pause_between_lines).timeout

	speech_anim.play("speech_out")
	await speech_anim.animation_finished

	text.text = ""
