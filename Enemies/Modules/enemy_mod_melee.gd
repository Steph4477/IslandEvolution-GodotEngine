extends Node
class_name EnemyModMelee

var enemy = null

func setup(parent_enemy):
	enemy = parent_enemy

func update_state():
	if enemy.is_dead:
		enemy.in_melee = false
		enemy.attack_timer.stop()

		if enemy.projectile_timer:
			enemy.projectile_timer.stop()

		return

	if enemy.player == null:
		enemy.refresh_player()

	if enemy.player == null:
		enemy.in_melee = false
		enemy.attack_timer.stop()

		if enemy.projectile_timer:
			enemy.projectile_timer.stop()

		return

	if enemy.distance <= enemy.melee_distance:
		if not enemy.in_melee:
			enemy.in_melee = true
			enemy.is_shooting = false

			if enemy.projectile_timer:
				enemy.projectile_timer.stop()

		if enemy.attack_timer.is_stopped():
			enemy.attack()
			enemy.attack_timer.start()
	else:
		if enemy.in_melee:
			enemy.in_melee = false
			enemy.attack_timer.stop()

			if enemy.projectile_timer:
				enemy.projectile_timer.start()

func on_timer_timeout():
	if enemy.is_dead:
		return

	if enemy.player == null:
		enemy.refresh_player()

	if enemy.player == null:
		enemy.in_melee = false
		enemy.attack_timer.stop()
		return

	if not enemy.in_melee:
		return

	enemy.attack()
	enemy.attack_timer.start()
