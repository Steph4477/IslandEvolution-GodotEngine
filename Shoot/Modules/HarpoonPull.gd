extends Node
class_name HarpoonPull

var owner_node = null
var target_node = null
var rope = null

var pull_speed = 450.0
var stop_distance = 60.0
var max_duration = 2.0

var is_pulling = false
var pull_time = 0.0

var rope_scene = preload("res://Shoot/HarpoonRope/harpoon_rope.tscn")

func setup(parent_owner):
	owner_node = parent_owner

func create_rope(point_a, point_b):
	stop_rope()

	rope = rope_scene.instantiate()
	get_tree().current_scene.add_child(rope)
	rope.start(point_a, point_b)

func set_rope_target(target):
	if rope == null:
		return

	rope.point_b = target

func stop_rope():
	if rope != null:
		rope.stop()
		rope = null

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
	if rope != null:
		rope.update_rope()

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
	stop_rope()

	if target_node != null:
		target_node.stop_harpooned()

	is_pulling = false
	pull_time = 0.0
	target_node = null
