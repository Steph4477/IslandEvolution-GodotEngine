extends RefCounted
class_name EnemyModThrowProjectile

var enemy = null

func setup(parent_enemy):
	enemy = parent_enemy

func can_throw():
	if enemy.is_dead:
		return false

	if enemy.is_attacking:
		return false

	if enemy.is_shooting:
		return false

	if enemy.in_melee:
		return false

	if enemy.target == null:
		return false

	if not is_instance_valid(enemy.target):
		return false

	if enemy.target.is_dead:
		return false

	if enemy.distance <= enemy.melee_distance:
		return false

	if enemy.distance < enemy.min_shoot_distance:
		return false

	if enemy.distance > enemy.max_shoot_distance:
		return false

	return true

func on_timer_timeout():
	if not can_throw():
		return

	throw_projectile()

func throw_projectile():
	enemy.is_shooting = true
	enemy.velocity.x = 0

	if enemy.anim.current_animation != enemy.projectile_attack_animation:
		enemy.anim.play(enemy.projectile_attack_animation)

	await enemy.get_tree().create_timer(enemy.projectile_spawn_delay).timeout

	if not is_instance_valid(enemy):
		return

	if enemy.is_dead:
		enemy.is_shooting = false
		return

	if enemy.target == null:
		enemy.is_shooting = false
		return

	if not is_instance_valid(enemy.target):
		enemy.is_shooting = false
		return

	if enemy.target.is_dead:
		enemy.is_shooting = false
		return

	if enemy.in_melee:
		enemy.is_shooting = false
		return

	var projectile = enemy.projectile_scene.instantiate()
	enemy.get_tree().current_scene.add_child(projectile)

	var target_pos = enemy.target.global_position

	if enemy.target.has_node("TurnAxis"):
		target_pos = enemy.target.get_node("TurnAxis").global_position

	var dir = target_pos - enemy.projectile_spawn.global_position

	if projectile.has_method("setup_owner"):
		projectile.setup_owner(enemy)

	projectile.start(enemy.projectile_spawn.global_position, dir.normalized())

	enemy.is_shooting = false
