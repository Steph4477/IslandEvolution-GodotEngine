extends Node
class_name EnemyModMelee

var enemy = null

func setup(parent_enemy):
	enemy = parent_enemy

func update_state():
	if enemy.is_dead:
		enemy.in_melee = false
		enemy.attack_timer.stop()
		return

	if enemy.distance <= enemy.melee_distance:
		if not enemy.in_melee:
			enemy.in_melee = true
			enemy.attack()
			enemy.attack_timer.start()
	else:
		if enemy.in_melee:
			enemy.in_melee = false
			enemy.attack_timer.stop()

func on_timer_timeout():
	if enemy.is_dead:
		return

	if not enemy.in_melee:
		return

	enemy.attack()
