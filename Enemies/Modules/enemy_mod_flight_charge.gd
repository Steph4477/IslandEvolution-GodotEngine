extends RefCounted

var enemy = null

func setup(e):
	enemy = e

func update():

	var target = enemy.get_target_position()

	var direction = (target - enemy.global_position).normalized()

	enemy.flight_velocity = direction * enemy.speed

	enemy.play_flight_anim("flight")

func can_hit():

	var target = enemy.get_target_position()

	var distance = enemy.global_position.distance_to(target)

	return distance <= enemy.attack_contact_radius
