extends RefCounted
class_name EnemyModFlightSwarm

var enemy = null
var members = []
var current_attack_index = 0
var hit_locked = false
var has_built_swarm = false

func setup(owner):
	enemy = owner

func build_swarm():
	if has_built_swarm:
		return

	has_built_swarm = true

	members.clear()
	members.append(enemy)

	var parent = enemy.get_parent()

	var count = enemy.swarm_count
	if count == null:
		count = 1

	count = int(count)

	for i in range(1, count):
		var clone = enemy.duplicate()

		clone.is_swarm_clone = true
		clone.spawn_swarm_on_ready = false
		clone.swarm_slot = i
		clone.swarm_controller = self

		clone.chase_speed = enemy.chase_speed
		clone.attack_range = enemy.attack_range
		clone.contact_attack_radius = enemy.contact_attack_radius
		clone.cooldown = enemy.cooldown
		clone.patrol_speed = enemy.patrol_speed
		clone.patrol_change_interval = enemy.patrol_change_interval

		clone.base_orbit_radius_x = enemy.base_orbit_radius_x
		clone.base_orbit_radius_y = enemy.base_orbit_radius_y

		clone.orbit_radius_x = enemy.base_orbit_radius_x
		clone.orbit_radius_y = enemy.base_orbit_radius_y
		clone.orbit_angular_speed = enemy.orbit_angular_speed
		clone.orbit_duration = enemy.orbit_duration

		clone.osc_radial_amplitude = enemy.osc_radial_amplitude
		clone.osc_radial_frequency = enemy.osc_radial_frequency
		clone.osc_angle_amplitude = enemy.osc_angle_amplitude
		clone.osc_angle_frequency = enemy.osc_angle_frequency

		clone.swarm_count = enemy.swarm_count
		clone.swarm_spawn_radius = enemy.swarm_spawn_radius
		clone.swarm_orbit_step_x = enemy.swarm_orbit_step_x
		clone.swarm_orbit_step_y = enemy.swarm_orbit_step_y

		parent.add_child(clone)
		clone.global_position = enemy.global_position + get_spawn_offset(i)

		members.append(clone)

	current_attack_index = 0

func get_spawn_offset(slot):
	var count = enemy.swarm_count
	if count == null:
		count = 1

	count = int(count)

	var radius = enemy.swarm_spawn_radius
	if radius == null:
		radius = 0.0

	var angle_step = TAU / count
	var angle = angle_step * slot

	return Vector2(cos(angle), sin(angle)) * radius

func can_member_attack(member):
	cleanup_dead()

	if members.is_empty():
		return false

	if current_attack_index >= members.size():
		current_attack_index = 0

	return members[current_attack_index] == member

func notify_member_attack_finished(member):
	cleanup_dead()

	if members.is_empty():
		return

	if current_attack_index >= members.size():
		current_attack_index = 0

	if members[current_attack_index] != member:
		return

	current_attack_index += 1

	if current_attack_index >= members.size():
		current_attack_index = 0

func unregister_member(member):
	var idx = members.find(member)
	if idx == -1:
		return

	members.remove_at(idx)

	if current_attack_index > idx:
		current_attack_index -= 1

	if current_attack_index >= members.size():
		current_attack_index = 0

func cleanup_dead():
	for i in range(members.size() - 1, -1, -1):
		if not is_instance_valid(members[i]):
			members.remove_at(i)

	if current_attack_index >= members.size():
		current_attack_index = 0

func can_take_swarm_hit():
	if hit_locked:
		return false

	hit_locked = true


	enemy.call_deferred("unlock_swarm_hit")
	return true

func unlock_swarm_hit():
	hit_locked = false
