extends Node2D

@export var chrono_zone_path = NodePath("Node2D/ChronoZone")
@export var froggle_scene = preload("res://Enemies/Froggle/froggle.tscn")   
@export var froggle_spawn_path = NodePath("Node2D/FroggleSpawn")            

@onready var anim = $Node2D/World/AnimationPlayer

var _froggle_spawned = false

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
	# 1) Lance la chute des lianes
	if anim.has_animation("fall"):
		anim.play("fall")
		await anim.animation_finished
		
	# 2) Attente de 2 secondes avant le spawn
	await get_tree().create_timer(2.0).timeout
		
	# 3) Spawn de la grenouille
	_spawn_froggle()

func _spawn_froggle():
	_froggle_spawned = true
	var spawn_node = get_node_or_null(froggle_spawn_path)
	var spawn_pos = Vector2.ZERO
	if spawn_node:
		spawn_pos = spawn_node.global_position
	
	var frog = froggle_scene.instantiate()
	add_child(frog)
	frog.global_position = spawn_pos
