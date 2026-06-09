extends RigidBody2D

var damage = 0
var direction = 1
var has_collided = false

const FIRE_IMPACT_SCENE = preload("res://Effects/Fire/Fire_impact/fire_impact.tscn")

func start(pos, dir, projectile_damage):
	damage = projectile_damage
	global_position = pos

	if typeof(dir) == TYPE_VECTOR2:
		if dir.x < 0:
			direction = -1
		else:
			direction = 1
	else:
		direction = dir

	linear_velocity = Vector2(1000 * direction, 0)

	$Area2D/CollisionShape2D.disabled = true

	call_deferred("_enable_hitbox")
	call_deferred("_self_destruct")

func _enable_hitbox():
	await get_tree().process_frame
	$Area2D/CollisionShape2D.disabled = false

func _self_destruct():
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _on_area_2d_body_entered(body):
	if has_collided:
		return

	has_collided = true
	$Area2D/CollisionShape2D.set_deferred("disabled", true)

	if body.is_in_group("Enemies") and body.has_method("on_hit"):
		body.on_hit(damage)

	var impact = FIRE_IMPACT_SCENE.instantiate()
	get_tree().current_scene.add_child(impact)

	if linear_velocity.x < 0:
		impact.global_position = global_position + Vector2(-8, -6)
	else:
		impact.global_position = global_position + Vector2(8, -6)

	impact.play_impact()

	queue_free()
