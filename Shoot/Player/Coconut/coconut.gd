extends RigidBody2D

@export var speed = 1000
@export var life_time = 3.0
@export var damage = 100

var direction = 1

const FIRE_IMPACT_SCENE = preload("res://Effects/Fire/Fire_impact/fire_impact.tscn")

func start(pos, dir):
	direction = dir
	global_position = pos
	linear_velocity = Vector2(speed * direction, 0)

	$Area2D/CollisionShape2D.disabled = true

	call_deferred("_enable_hitbox")
	call_deferred("_self_destruct")

func _enable_hitbox():
	await get_tree().process_frame
	$Area2D/CollisionShape2D.disabled = false

func _self_destruct():
	await get_tree().create_timer(life_time).timeout
	queue_free()

func _on_area_2d_body_entered(body):
	if body.is_in_group("Enemies") and body.has_method("on_hit"):
		body.on_hit(damage)

	var impact = FIRE_IMPACT_SCENE.instantiate()
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_position + Vector2(direction * 8, -6)
	impact.play_impact()

	queue_free()
