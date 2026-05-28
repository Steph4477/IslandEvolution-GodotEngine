extends Node2D

@onready var body = $RigidBody2D
@onready var area = $RigidBody2D/Area2D

@export var throw_velocity = Vector2(0, -450)
@export var random_x = 0
@export var random_rotation = 60
@export var is_template = false
@export var damage = 1000

var did_hit = false


func _ready():
	visible = false
	body.freeze = true
	body.contact_monitor = true
	body.max_contacts_reported = 1


func throw_now():
	z_index = 18
	await get_tree().create_timer(randf_range(0.0, 1.0)).timeout

	visible = true
	body.freeze = false

	body.linear_velocity = Vector2(
		throw_velocity.x + randf_range(-random_x, random_x),
		throw_velocity.y
	)

	body.angular_velocity = randf_range(
		-random_rotation,
		random_rotation
	)


func _on_area_2d_body_entered(body_hit):
	if did_hit:
		return

	if body_hit.is_in_group("Player"):
		did_hit = true
		body_hit.damage_mod.on_hit(damage)
		queue_free()


func _on_rigid_body_2d_body_entered(_body_hit):
	queue_free()
