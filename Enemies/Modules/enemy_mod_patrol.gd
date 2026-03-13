extends Node
class_name EnemyModPatrol

var enemy = null

func setup(parent_enemy):
	enemy = parent_enemy

func start():
	if enemy == null:
		return

	if not is_instance_valid(enemy):
		return

	change_direction()

	if enemy.patrol_timer:
		enemy.patrol_timer.wait_time = enemy.patrol_change_interval
		enemy.patrol_timer.start()

func update_movement():
	if enemy == null:
		return

	if not is_instance_valid(enemy):
		return

	if enemy.is_dead:
		enemy.velocity.x = 0
		return

	if enemy.is_patrol_paused:
		enemy.velocity.x = 0
		return

	enemy.velocity.x = enemy.patrol_direction * enemy.patrol_speed

func change_direction():
	if enemy == null:
		return

	if not is_instance_valid(enemy):
		return

	enemy.is_patrol_paused = true
	enemy.velocity.x = 0

	if enemy.anim:
		if enemy.anim.current_animation != "idle":
			enemy.anim.play("idle")

	await enemy.get_tree().create_timer(2.0).timeout

	if enemy == null:
		return

	if not is_instance_valid(enemy):
		return

	if enemy.is_dead:
		return

	enemy.is_patrol_paused = false

	var dir = randf_range(-1.0, 1.0)

	if dir < 0:
		enemy.patrol_direction = -1
	else:
		enemy.patrol_direction = 1

func on_timer_timeout():
	if enemy == null:
		return

	if not is_instance_valid(enemy):
		return

	if enemy.is_dead:
		return

	if not enemy.is_patrolling:
		return

	change_direction()
