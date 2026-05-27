extends Node
class_name HarpoonPull

var owner_node = null
var target_node = null

var pull_speed = 450.0
var stop_distance = 60.0
var max_duration = 2.0

var is_pulling = false
var pull_time = 0.0

func setup(parent_owner):
	owner_node = parent_owner

func start_pull(target):
	if is_pulling:
		return

	if owner_node == null:
		return

	if target == null:
		return

	target_node = target
	is_pulling = true
	pull_time = 0.0

func _physics_process(delta):
	if not is_pulling:
		return

	if owner_node == null:
		stop_pull()
		return

	if target_node == null:
		stop_pull()
		return

	pull_time += delta

	if pull_time >= max_duration:
		stop_pull()
		return

	var dir = target_node.global_position.direction_to(owner_node.global_position)

	target_node.velocity.x = dir.x * pull_speed
	target_node.move_and_slide()

	var distance = target_node.global_position.distance_to(owner_node.global_position)

	if distance <= stop_distance:
		stop_pull()

func stop_pull():
	if target_node != null:
		target_node.stop_harpooned()

	is_pulling = false
	pull_time = 0.0
	target_node = null
