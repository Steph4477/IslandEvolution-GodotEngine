extends RigidBody2D

@export var speed = 800
@export var damage = GameBalance.ENEMY_PROJECTILE["lance"]
@export var arc_force = -150
@export var gravity_force = 1.2

var direction = Vector2.RIGHT

@onready var sprite = $SpearSprite
@onready var hitbox = $Area2D/CollisionPolygon2D

func _ready():
	gravity_scale = gravity_force
	hitbox.disabled = true
	contact_monitor = true
	max_contacts_reported = 1

func _physics_process(_delta):
	rotation = linear_velocity.angle()

func start(pos, dir):
	global_position = pos

	if typeof(dir) == TYPE_VECTOR2:
		direction = dir.normalized()
	else:
		if dir < 0:
			direction = Vector2.LEFT
		else:
			direction = Vector2.RIGHT

	hitbox.disabled = false
	linear_velocity = Vector2(direction.x * speed, direction.y * speed + arc_force)

	if direction.x < 0:
		sprite.flip_v = true
	else:
		sprite.flip_v = false

func _on_area_2d_body_entered(body):
	if not body.is_in_group("Player"):
		return

	body.damage_mod.on_hit(damage)
	queue_free()

func _on_body_entered(_body):
	queue_free()
