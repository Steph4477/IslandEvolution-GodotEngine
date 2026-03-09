extends EnemyBase
class_name EnemyGroundBase

@export var speed = 200
@export var attack_range = 300
@export var stop_distance = 40
@export var gravity = 2000

var dx = 0.0
var distance = 0.0
var base_scale_x = 1

func _ready():
	super._ready()
	base_scale_x = $Rotator.scale.x

func _physics_process(delta):

	apply_gravity(delta)

	if is_dead or is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	if player:
		target_player()
		flip()
		move_to_target()
	else:
		velocity.x = 0
		$Rotator/AnimationPlayer.play("idle")

	move_and_slide()

func apply_gravity(delta):

	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity * delta

func target_player():

	var target_pos = player.get_node("TurnAxis").global_position
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

		if $Rotator/AnimationPlayer.current_animation != "walk":
			$Rotator/AnimationPlayer.play("walk")

	elif distance < attack_range and dx < -stop_distance:

		velocity.x = -speed

		if $Rotator/AnimationPlayer.current_animation != "walk":
			$Rotator/AnimationPlayer.play("walk")

	else:

		velocity.x = 0

		if $Rotator/AnimationPlayer.current_animation != "idle":
			$Rotator/AnimationPlayer.play("idle")
