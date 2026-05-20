extends RigidBody2D

@export var speed = 1000
@export var damage = 500
@export var life_time = 3.0

var direction = 1

@onready var sprite = $HarponSprite
@onready var hitbox = $Area2D/CollisionPolygon2D

func _ready():
	gravity_scale = 0
	hitbox.disabled = true

func start(pos, dir):
	global_position = pos
	direction = dir

	hitbox.disabled = false
	linear_velocity = Vector2(speed * direction, 0)

	if direction < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	await get_tree().create_timer(life_time).timeout
	queue_free()

func _on_area_2d_body_entered(body):
	if not body.is_in_group("Player"):
		return

	body.damage_mod.on_hit(damage)

	hitbox.set_deferred("disabled", true)

	queue_free()
