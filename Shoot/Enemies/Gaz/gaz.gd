extends RigidBody2D

@export var speed = 800.0
@export var life_time = 10.0
@export var damage = 400

var direction = 1
var has_collided = false

func _ready():
	gravity_scale = 0
	$AnimationPlayer.play("gaz")
	$Area2D/CollisionShape2D.disabled = true

	await get_tree().create_timer(life_time).timeout
	queue_free()

func start(pos, dir):
	global_position = pos
	set_direction(dir)
	$Area2D/CollisionShape2D.disabled = false

func set_direction(dir):
	direction = dir
	linear_velocity = Vector2(speed * direction, 0)

	if has_node("Sprite2D"):
		if direction < 0:
			$Sprite2D.flip_h = true
		else:
			$Sprite2D.flip_h = false
	else:
		if direction < 0:
			scale.x = -abs(scale.x)
		else:
			scale.x = abs(scale.x)

func _on_area_2d_body_entered(body):
	if has_collided:
		return

	if not body.is_in_group("Player"):
		return

	has_collided = true

	if body.effects_mod:
		body.effects_mod.apply_gaz()

	if body.damage_mod:
		body.damage_mod.on_hit(damage)

	$Area2D/CollisionShape2D.set_deferred("disabled", true)

	if has_node("Sprite2D"):
		$Sprite2D.hide()

	queue_free()
