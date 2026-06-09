# res://Shoot/Enemies/Bone/bone.gd


extends RigidBody2D

@export var speed = 1000
@export var max_distance = 800
var damage = 0

var direction = Vector2.RIGHT
var start_position = Vector2.ZERO
var has_initialized_trajectory = false
var did_hit = false

@onready var shape = $Area2D/CollisionShape2D
@onready var spr = $BoneSprite

func _ready():
	gravity_scale = 1.0
	linear_damp = 0
	angular_damp = 0
	freeze = false

	if shape:
		shape.disabled = true

	set_physics_process(true)

func start(pos, dir, projectile_damage):
	damage = projectile_damage
	global_position = pos
	start_position = global_position
	has_initialized_trajectory = false
	did_hit = false

	if shape:
		shape.disabled = false

	if typeof(dir) == TYPE_VECTOR2:
		direction = dir.normalized()
	else:
		if dir < 0:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT

func _physics_process(_delta):
	if did_hit:
		return

	if has_initialized_trajectory == false:
		has_initialized_trajectory = true

		if direction.length() == 0:
			direction = Vector2.RIGHT

		linear_velocity = direction.normalized() * speed

		if direction.x < 0:
			angular_velocity = -10.0
		else:
			angular_velocity = 10.0

	var vx = linear_velocity.x

	if spr:
		if vx < 0:
			spr.flip_h = false
		else:
			spr.flip_h = true
	else:
		if vx < 0:
			scale.x = abs(scale.x)
		else:
			scale.x = -abs(scale.x)

	var traveled = global_position.distance_to(start_position)
	if traveled >= max_distance:
		_finish()

func _impact():
	did_hit = true
	set_physics_process(false)

	if shape:
		shape.set_deferred("disabled", true)

	if spr:
		spr.hide()

	_finish()

func _finish():
	queue_free()

func _on_area_2d_body_entered(body):
	if did_hit:
		return

	if body.is_in_group("Player"):
		body.damage_mod.on_hit(damage)

	_impact()
