extends RigidBody2D

@export var speed = 800.0
@export var life_time = 3.0
@export var damage = 10

var direction = Vector2.RIGHT
var has_collided = false
var shooter_node = null

func _ready():
	top_level = true
	gravity_scale = 0
	z_index = 100
	visible = true

	$Sprite2D.visible = true
	$Sprite2D.z_index = 100
	$Sprite2D.modulate = Color(1, 1, 1, 1)

	$Area2D/CollisionShape2D.disabled = true
	$AnimationPlayer.play("gaz")

	await get_tree().create_timer(life_time).timeout
	queue_free()

func setup_owner(shooter):
	shooter_node = shooter

func start(pos, dir):
	global_position = pos
	set_direction(dir)

	await get_tree().create_timer(0.2).timeout
	$Area2D/CollisionShape2D.disabled = false

func set_direction(dir):
	if typeof(dir) == TYPE_VECTOR2:
		direction = dir.normalized()
	else:
		direction = Vector2(dir, 0).normalized()

	linear_velocity = direction * speed

	if direction.x < 0:
		$Sprite2D.flip_h = true
	else:
		$Sprite2D.flip_h = false

func _on_area_2d_body_entered(body):
	if body == shooter_node:
		return

	if body is StaticBody2D:
		return

	if has_collided:
		return

	if not body.is_in_group("Player"):
		return

	has_collided = true

	if body.effects_mod:
		body.effects_mod.apply_gaz()

	if body.damage_mod:
		body.damage_mod.on_hit(damage)

	queue_free()
