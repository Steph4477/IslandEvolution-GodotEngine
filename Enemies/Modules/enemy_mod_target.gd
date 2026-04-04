extends RefCounted
class_name EnemyModTarget

var e = null

func setup(enemy):
	e = enemy
	e.target = null

func update():
	if e.is_dead:
		e.target = null
		e.dx = 0
		e.distance = 999999
		return

	if e.player == null:
		e.target = null
		e.dx = 0
		e.distance = 999999
		return

	if not is_instance_valid(e.player):
		e.target = null
		e.dx = 0
		e.distance = 999999
		return

	if e.target == null:
		var first_target_position = e.player.global_position

		if e.player.has_node("TurnAxis"):
			first_target_position = e.player.get_node("TurnAxis").global_position

		var first_to_target = first_target_position - e.global_position
		var first_distance = first_to_target.length()

		if first_distance <= e.attack_range:
			e.target = e.player
		else:
			e.dx = 0
			e.distance = 999999
			return

	if not is_instance_valid(e.target):
		e.target = null
		e.dx = 0
		e.distance = 999999
		return

	var target_position = e.target.global_position

	if e.target.has_node("TurnAxis"):
		target_position = e.target.get_node("TurnAxis").global_position

	var to_target = target_position - e.global_position
	e.dx = to_target.x
	e.distance = to_target.length()

	if e.release_enabled:
		if e.distance > e.release_distance:
			e.target = null
			e.dx = 0
			e.distance = 999999
