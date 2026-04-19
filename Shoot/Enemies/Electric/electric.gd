extends RigidBody2D

@export var speed = 700
@export var life_time = 2.0
@export var damage = 500
@export var homing_time = 1.0
@export var turn_speed = 4.0

var direction = 1
var target = null
var velocity_dir = Vector2.ZERO
var started = false
var homing_active = true

func _ready():
	gravity_scale = 0

	await get_tree().create_timer(homing_time).timeout
	homing_active = false

	await get_tree().create_timer(life_time - homing_time).timeout
	queue_free()

func start(pos, dir):
	global_position = pos
	direction = dir
	started = true

	target = get_tree().get_first_node_in_group("Player")

	velocity_dir = Vector2(direction, 0).normalized()
	linear_velocity = velocity_dir * speed

	$Area2D/CollisionShape2D2.disabled = false

	update_visual_direction()

func _physics_process(delta):
	if not started:
		return

	if homing_active:
		if target == null or not is_instance_valid(target):
			target = get_tree().get_first_node_in_group("Player")

		if target != null and is_instance_valid(target):
			var target_pos = target.global_position

			if target.has_node("TurnAxis"):
				target_pos = target.get_node("TurnAxis").global_position

			var desired_dir = (target_pos - global_position).normalized()

			velocity_dir = velocity_dir.lerp(desired_dir, turn_speed * delta).normalized()

	linear_velocity = velocity_dir * speed

	if velocity_dir.x < 0:
		direction = -1
	else:
		direction = 1

	update_visual_direction()

func update_visual_direction():
	if has_node("ElectricSprite"):
		if direction < 0:
			$ElectricSprite.flip_h = true
		else:
			$ElectricSprite.flip_h = false
	else:
		if direction < 0:
			scale.x = -abs(scale.x)
		else:
			scale.x = abs(scale.x)

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.damage_mod.on_hit(damage)

	$Area2D/CollisionShape2D2.set_deferred("disabled", true)

	if has_node("ElectricSprite"):
		$ElectricSprite.hide()

	queue_free()
