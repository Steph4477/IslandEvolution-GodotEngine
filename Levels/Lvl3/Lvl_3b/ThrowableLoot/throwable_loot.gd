extends Node2D

@onready var body = $RigidBody2D

@export var loot_scene: PackedScene
@export var throw_velocity = Vector2(250, -450)
@export var random_x = 50
@export var random_rotation = 8
@export var is_template = false

var loot_spawned = false


func _ready():
	visible = false
	body.freeze = true
	body.sleeping = true


func throw_now():
	await get_tree().create_timer(randf_range(0.0, 1.0)).timeout

	if loot_spawned == false:
		var loot = loot_scene.instantiate()
		body.add_child(loot)
		loot.position = Vector2.ZERO
		loot_spawned = true

	visible = true
	body.visible = true
	body.z_index = 18

	body.freeze = false
	body.sleeping = false

	await get_tree().physics_frame

	var target = get_tree().get_first_node_in_group("loot_target")
	var dir_x = 0.0

	if target:
		dir_x = sign(target.global_position.x - global_position.x)

	body.linear_velocity = Vector2(
	dir_x * abs(throw_velocity.x) + randf_range(-random_x, random_x),
	throw_velocity.y
	)

	body.angular_velocity = randf_range(
		-random_rotation,
		random_rotation
	)
