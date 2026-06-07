extends EnemyBase
class_name EnemyGroundBase

@export var speed = 350
@export var attack_range = 300
@export var gravity = 2000
@export var stop_distance = 40

@export var patrol_enabled = true

@export var patrol_speed = 120.0
@export var patrol_change_interval = 4.0
@export var patrol_pause_time = 2.0

var dx = 0
var distance = 0
var base_scale_x = 1
var rotator = null
var sprite = null

var patrol_mod = EnemyModPatrol.new()

var is_patrolling = true
var is_patrol_paused = false
var patrol_direction = 1


func _ready():
	super._ready()

	if has_node("Rotator"):
		rotator = $Rotator
		base_scale_x = abs(rotator.scale.x)

	if has_node("Rotator/Sprite2D"):
		sprite = $Rotator/Sprite2D

	is_patrolling = patrol_enabled


func apply_gravity(delta):
	if is_on_floor() and velocity.y >= 0:
		velocity.y = 0
	else:
		velocity.y += gravity * delta


func target_player():
	if player == null:
		refresh_player()

		if player == null:
			dx = 0
			distance = 999999
			return

	var target_pos = player.global_position

	if player.has_node("TurnAxis"):
		target_pos = player.get_node("TurnAxis").global_position

	var to_target = target_pos - global_position
	dx = to_target.x
	distance = to_target.length()


func flip():
	if dx > 1:
		$Rotator.scale.x = base_scale_x
	elif dx < -1:
		$Rotator.scale.x = -base_scale_x


func move_to_target():
	if distance < attack_range and dx > stop_distance:
		velocity.x = speed

		if anim.current_animation != "walk":
			anim.play("walk")

	elif distance < attack_range and dx < -stop_distance:
		velocity.x = -speed

		if anim.current_animation != "walk":
			anim.play("walk")

	else:
		velocity.x = 0
		play_idle()


func stop_and_slide():
	velocity.x = 0
	move_and_slide()


func play_idle():
	if anim.current_animation != "idle":
		anim.play("idle")
