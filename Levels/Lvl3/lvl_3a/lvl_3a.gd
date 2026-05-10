extends Node2D

@onready var moko_back = $MokoBack
@onready var moko_anim = $MokoBack/Anim
@onready var spawn_point = $SpawnPoint
@onready var gate_close_marker = $GateCloseMarker
@onready var corridor_exit = $CorridorExit
@onready var scene_camera = $Camera2D
@onready var gate_anim = $GateFront/Anim

var corridor_speed = 75

var start_scale = Vector2(1, 1)
var end_scale = Vector2(0.20, 0.20)

var start_camera_zoom = Vector2(1, 1)
var end_camera_zoom = Vector2(1.2, 1.2)

var start_moko_color = Color(1, 1, 1, 1)
var end_moko_color = Color(0.207, 0.142, 0.096, 1.0)

var is_transitioning = false
var gate_closed = false

var player = null
var hud = null


func _ready():
	await get_tree().process_frame

	var gs = get_node("/root/GameState")

	player = gs.player
	hud = gs.hud

	scene_camera.make_current()

	player.visible = false
	player.set_physics_process(false)
	player.set_process(false)
	player.get_node("Camera2D").enabled = false

	hud.visible = false

	moko_back.global_position = spawn_point.global_position
	moko_back.scale = start_scale
	moko_back.modulate = start_moko_color

	scene_camera.zoom = start_camera_zoom


func _physics_process(delta):
	if is_transitioning:
		return

	if Input.is_action_pressed("ui_up"):
		move_moko(delta)
		check_gate_close()
	else:
		moko_anim.play("idle")

	check_exit()


func move_moko(delta):
	moko_back.global_position = moko_back.global_position.move_toward(corridor_exit.global_position, corridor_speed * delta)

	moko_anim.play("walk")

	var total_distance = spawn_point.global_position.distance_to(corridor_exit.global_position)
	var current_distance = moko_back.global_position.distance_to(corridor_exit.global_position)

	var progress = 1.0 - current_distance / total_distance

	moko_back.scale = start_scale.lerp(end_scale, progress)
	moko_back.modulate = start_moko_color.lerp(end_moko_color, progress)

	scene_camera.zoom = start_camera_zoom.lerp(end_camera_zoom, progress)


func check_gate_close():
	if gate_closed:
		return

	if moko_back.global_position.y <= gate_close_marker.global_position.y:
		gate_closed = true
		gate_anim.play("close")


func check_exit():
	if moko_back.global_position.distance_to(corridor_exit.global_position) < 10:
		enter_arena()


func enter_arena():
	is_transitioning = true

	moko_anim.play("idle")

	var gs = get_node("/root/GameState")

	await gs.fade.fade_out()

	player.visible = true
	player.set_physics_process(true)
	player.set_process(true)
	player.get_node("Camera2D").enabled = true

	hud.visible = true

	#gs.load_level("res://Levels/lvl_3b_arena.tscn")

	gs.player.popups_mod.show_info("L'arène n'est pas encore prête ! 😂 ")
