extends CharacterBody2D

@export var speed = 800
@export var damage = 0
@export var arc_force = -150
@export var gravity_force = 1200

var direction = Vector2.RIGHT
var is_planted = false

func _ready():
	$LootArea/CollisionShape2D.disabled = true

func _physics_process(delta):
	if is_planted:
		return

	velocity.y += gravity_force * delta
	rotation = velocity.angle()

	var collision = move_and_collide(velocity * delta)

	if collision:
		var body = collision.get_collider()

		if body.is_in_group("Enemies") or body.is_in_group("amphibious_croco"):
			if body.has_method("on_hit"):
				body.on_hit(damage)
			queue_free()
			return

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

	velocity = Vector2(
		direction.x * speed,
		direction.y * speed + arc_force
	)

	if direction.x < 0:
		$Sprite.flip_v = true
	else:
		$Sprite.flip_v = false

func plant_spear():
	is_planted = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	$LootArea/CollisionShape2D.disabled = false

func _on_loot_area_body_entered(body):
	if not is_planted:
		return

	if body.is_in_group("Player"):
		body.collect_items.collect_lance()
		queue_free()
