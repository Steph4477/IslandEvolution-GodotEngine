extends RigidBody2D

@export var speed = 700.0
@export var lifetime = 2.0
@export var hit_distance = 75.0

var dir = Vector2.ZERO
var heal_amount = 0
var heal_target = null

func setup_target(target):
	heal_target = target


func start(pos, direction, amount):
	global_position = pos
	dir = direction
	heal_amount = amount

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta):
	global_position += dir * speed * delta

	if heal_target == null:
		return

	if not is_instance_valid(heal_target):
		queue_free()
		return

	if heal_target.is_dead:
		queue_free()
		return

	if global_position.distance_to(heal_target.global_position) <= hit_distance:
		heal_target.hp += heal_amount
		heal_target.hp = min(heal_target.hp, heal_target.max_hp)

		if heal_target.hb:
			heal_target.hb.set_value(heal_target.hp)

		queue_free()
