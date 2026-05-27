extends Node
class_name HarpoonPull

var owner_node
var target_node

var pull_speed = 450.0
var stop_distance = 60.0
var max_duration = 2.0

var is_pulling = false
var pull_time = 0.0

func setup(parent_owner):
	owner_node = parent_owner
	print("SETUP OWNER :", owner_node)

func start_pull(target):
	target_node = target
	is_pulling = true
	pull_time = 0.0
	print("START PULL :", target_node)

func process_pull(delta):

	if not is_pulling:
		return

	if owner_node == null:
		print("OWNER NULL")
		stop_pull()
		return

	if target_node == null:
		print("TARGET NULL")
		stop_pull()
		return

	pull_time += delta

	print("PULL TIME :", pull_time)

	if pull_time >= max_duration:
		print("STOP MAX DURATION")
		stop_pull()
		return

	var direction = owner_node.global_position - target_node.global_position
	var distance = direction.length()

	print("DISTANCE :", distance)

	if distance <= stop_distance:
		print("STOP DISTANCE")
		stop_pull()
		return

	target_node.global_position += direction.normalized() * pull_speed * delta

	print("TARGET POS :", target_node.global_position)

func stop_pull():
	is_pulling = false
	target_node = null
	pull_time = 0.0

	print("STOP PULL")
