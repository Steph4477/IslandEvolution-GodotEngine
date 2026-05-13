extends Node2D

@onready var body = $RigidBody2D

@export var loot_scene: PackedScene
@export var throw_velocity = Vector2(250, -450)
@export var random_x = 150
@export var random_rotation = 8
@export var is_template = false

var loot_spawned = false


func _ready():
	if is_template:
		visible = false
		body.freeze = true
		return

	visible = false
	body.freeze = true


func throw_now():
	z_index = 18
	await get_tree().create_timer(randf_range(0.0, 1)).timeout

	if loot_spawned == false:
		var loot = loot_scene.instantiate()
		body.add_child(loot)
		loot.position = Vector2.ZERO
		loot_spawned = true

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
