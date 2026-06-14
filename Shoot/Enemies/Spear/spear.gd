extends CharacterBody2D

@export var speed = 800
@export var damage = 0
@export var arc_force = -150
@export var gravity_force = 1200

var direction = Vector2.RIGHT

func _ready():
	get_node("Area2D/CollisionPolygon2D").disabled = true

func _physics_process(delta):
	velocity.y += gravity_force * delta
	rotation = velocity.angle()

	var collision = move_and_collide(velocity * delta)

	if collision:
		queue_free()

func start(pos, dir, projectile_damage):
	damage = projectile_damage
	global_position = pos

	if typeof(dir) == TYPE_VECTOR2:
		direction = dir.normalized()
	else:
		if dir < 0:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT

	get_node("Area2D/CollisionPolygon2D").disabled = false

	velocity = Vector2(
		direction.x * speed,
		direction.y * speed + arc_force
	)

	if direction.x < 0:
		get_node("SpearSprite").flip_v = true
	else:
		get_node("SpearSprite").flip_v = false

func _on_area_2d_body_entered(body):
	if not body.is_in_group("Player"):
		return

	body.damage_mod.on_hit(damage)
	queue_free()
