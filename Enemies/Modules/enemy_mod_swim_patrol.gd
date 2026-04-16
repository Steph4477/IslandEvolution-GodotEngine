extends Node
class_name EnemyModSwimPatrol

var enemy

func setup(e):
	enemy = e

func start():
	enemy.set_random_swim_dir()
	enemy.play_swim()
	enemy.patrol_timer.start()

func update():
	if enemy.is_dead:
		return

	if enemy.dir == Vector2.ZERO:
		enemy.set_random_swim_dir()

	enemy.play_swim()

func on_timer_timeout():
	enemy.set_random_swim_dir()
	enemy.patrol_timer.start()
