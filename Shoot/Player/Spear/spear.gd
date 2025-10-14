extends RigidBody2D

@export var speed = 1000
@export var life_time = 3.0
@export var damage = 100

var direction = 1  # 1 = droite, -1 = gauche

func _ready():
	# Empêche la gravité et active le mode "bullet"
	gravity_scale = 0

	# Auto-destruction après life_time secondes
	await get_tree().create_timer(life_time).timeout
	queue_free()

func start(pos, dir):
	position = pos
	set_direction(dir)
	$Area2D/CollisionPolygon2D.disabled = false

func set_direction(dir):
	direction = dir
	linear_velocity = Vector2(speed * direction, 0)

	# 🔁 Flip visuel 
	if has_node("SpearSprite"):
		if direction < 0:
			$SpearSprite.flip_h = false
		else:
			$SpearSprite.flip_h = true
	else:
		if direction < 0:
			scale.x = abs(scale.x)
		else:
			scale.x = -abs(scale.x)

func _on_area_2d_body_entered(body):
	if body.is_in_group("Enemies") and body.has_method("on_hit"):
		body.on_hit(damage)

	$Area2D/CollisionPolygon2D.set_deferred("disabled", true)
	if has_node("SpearSprite"):
		$SpearSprite.hide()
	queue_free()
