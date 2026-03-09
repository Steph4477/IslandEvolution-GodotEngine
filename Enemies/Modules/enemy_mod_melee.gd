extends Node
class_name EnemyModMelee

var enemy = null

func setup(parent_enemy):

	enemy = parent_enemy

func on_body_entered(body):

	if body.is_in_group("Player"):

		enemy.in_melee = true
		enemy.attack()

		enemy.attack_timer.start()

func on_body_exited(body):

	if body.is_in_group("Player"):

		enemy.in_melee = false
		enemy.attack_timer.stop()

func on_timer_timeout():

	if enemy.is_dead:
		return

	if enemy.in_melee:
		enemy.attack()
