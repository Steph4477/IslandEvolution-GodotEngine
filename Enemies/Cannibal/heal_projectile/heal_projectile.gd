extends RigidBody2D

@export var speed = 900.0
@export var lifetime = 4.0
@export var hit_distance = 90.0

var heal_amount = 0
var heal_target = null


func _ready():
	top_level = true
	gravity_scale = 0
	freeze = true
	collision_layer = 0
	collision_mask = 0

	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true

	if has_node("Area2D/CollisionShape2D"):
		$Area2D/CollisionShape2D.disabled = true


func setup_target(target):
	heal_target = target


func start(pos, _direction, amount):
	global_position = pos
	heal_amount = amount

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _physics_process(delta):
	if heal_target == null:
		return

	if not is_instance_valid(heal_target):
		queue_free()
		return

	if heal_target.is_dead:
		queue_free()
		return

	var dir = heal_target.global_position - global_position

	if dir.length() <= hit_distance:
		heal_target.hp += heal_amount
		heal_target.hp = min(heal_target.hp, heal_target.max_hp)

		if heal_target.hb:
			heal_target.hb.set_value(heal_target.hp)

		if heal_target.health_bar:
			heal_target.health_bar.value = heal_target.hp

		queue_free()
		return

	global_position += dir.normalized() * speed * delta
