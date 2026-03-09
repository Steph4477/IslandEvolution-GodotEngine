extends RigidBody2D

@export var speed = 1000
@export var life_time = 3.0
@export var damage = 100

var direction = 1

func _ready():
	gravity_scale = 0

	await get_tree().create_timer(life_time).timeout
	queue_free()

func start(pos, dir):
	global_position = pos
	set_direction(dir)
	$Area2D/CollisionPolygon2D.disabled = false

func set_direction(dir):
	direction = dir
	linear_velocity = Vector2(speed * direction, 0)

	if has_node("SpearSprite"):
		if direction < 0:
			$SpearSprite.flip_h = true
		else:
			$SpearSprite.flip_h = false
	else:
		if direction < 0:
			scale.x = -abs(scale.x)
		else:
			scale.x = abs(scale.x)

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.damage_mod.on_hit(damage)

	$Area2D/CollisionPolygon2D.set_deferred("disabled", true)

	if has_node("SpearSprite"):
		$SpearSprite.hide()

	queue_free()
