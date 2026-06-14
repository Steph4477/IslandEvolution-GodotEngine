extends CharacterBody2D

@export var speed = 800
@export var damage = 0
@export var arc_force = -150
@export var gravity_force = 1200

var direction = Vector2.RIGHT
var is_planted = false

func _ready():
	$LootArea/CollisionShape2D.disabled = true
	$Area2D/CollisionPolygon2D.disabled = true

func _physics_process(delta):
	if is_planted:
		return

	velocity.y += gravity_force * delta
	rotation = velocity.angle()

	var collision = move_and_collide(velocity * delta)

	if collision:
		plant_spear()

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

	$Area2D/CollisionPolygon2D.disabled = false

	velocity = Vector2(
		direction.x * speed,
		direction.y * speed + arc_force
	)

	if direction.x < 0:
		$SpearSprite.flip_v = true
	else:
		$SpearSprite.flip_v = false

func plant_spear():
	is_planted = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	$Area2D/CollisionPolygon2D.disabled = true
	$LootArea/CollisionShape2D.disabled = false

func _on_area_2d_body_entered(body):
	if is_planted:
		return

	if not body.is_in_group("Player"):
		return

	body.damage_mod.on_hit(damage)
	queue_free()

func _on_loot_area_body_entered(body):
	if not is_planted:
		return

	if not body.is_in_group("Player"):
		return

	body.collect_items.collect_lance()
	queue_free()
