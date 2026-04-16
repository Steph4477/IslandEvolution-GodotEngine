extends EnemyBase
class_name EnemySwimBase

@export var swim_speed = 120.0
@export var chase_speed = 160.0
@export var attack_range = 250.0
@export var min_change_time = 1.5
@export var max_change_time = 3.5

var dir = Vector2.ZERO
var min_bound = Vector2.ZERO
var max_bound = Vector2.ZERO

var dx = 0
var distance = 999999
var target = null

var rotator
var patrol_timer
var bounds_shape

func _ready():
	super._ready()

	rotator = $Rotator
	patrol_timer = $PatrolTimer
	bounds_shape = $Bounds/CollisionShape2D

	setup_swim_bounds()

func setup_swim_bounds():
	var rect = bounds_shape.shape.get_rect()
	min_bound = bounds_shape.global_position + rect.position * bounds_shape.global_scale
	max_bound = min_bound + rect.size * bounds_shape.global_scale

func chase_target():
	if target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target_position = target.global_position

	if target.has_node("TurnAxis"):
		target_position = target.get_node("TurnAxis").global_position

	var to_target = target_position - global_position

	if to_target == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var chase_dir = to_target.normalized()
	velocity = chase_dir * chase_speed
	move_and_slide()

	if chase_dir.x < 0:
		rotator.scale.x = -1
	elif chase_dir.x > 0:
		rotator.scale.x = 1

func play_swim():
	if anim:
		if anim.current_animation != "swim":
			anim.play("swim")

func play_chase():
	if anim:
		if anim.current_animation != "chase":
			anim.play("chase")
