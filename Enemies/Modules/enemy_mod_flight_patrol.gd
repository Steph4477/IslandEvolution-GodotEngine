extends RefCounted

var enemy = null
var patrol_direction = Vector2.ZERO

func setup(e):
	enemy = e

func start():
	change_direction()

	if enemy.attack_timer:
		enemy.attack_timer.wait_time = enemy.patrol_change_interval
		enemy.attack_timer.start()

func update():
	enemy.flight_velocity = patrol_direction * enemy.patrol_speed
	enemy.play_flight_anim("patrol")

func change_direction():
	var angle = randf() * TAU
	patrol_direction = Vector2(cos(angle), sin(angle)).normalized()

func on_timer_timeout():
	change_direction()
