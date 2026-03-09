extends Node
class_name EnemyModThrowProjectile

var enemy = null

func setup(parent_enemy):
	enemy = parent_enemy

func on_timer_timeout():
	if enemy.is_dead:
		return

	if enemy.is_attacking:
		return

	if enemy.is_shooting:
		return

	if enemy.hit_locked:
		return

	if enemy.in_melee:
		return

	if enemy.distance < enemy.min_shoot_distance:
		return

	if enemy.distance > enemy.max_shoot_distance:
		return

	if enemy.player.is_dead:
		return

	shoot()

func shoot():
	if enemy.player.is_dead:
		enemy.is_shooting = false
		return

	enemy.is_shooting = true
	enemy.velocity.x = 0
	enemy.anim.play(enemy.projectile_attack_animation)

	await enemy.get_tree().create_timer(enemy.projectile_spawn_delay).timeout

	var projectile = enemy.projectile_scene.instantiate()
	enemy.get_parent().add_child(projectile)

	var dir = 1
	if enemy.dx < 0:
		dir = -1

	projectile.start(enemy.projectile_spawn.global_position, dir)

	var attack_duration = enemy.anim.get_animation(enemy.projectile_attack_animation).length

	if attack_duration > 0:
		await enemy.get_tree().create_timer(attack_duration).timeout

	enemy.is_shooting = false
