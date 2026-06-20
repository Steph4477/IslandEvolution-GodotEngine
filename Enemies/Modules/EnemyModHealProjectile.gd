extends RefCounted
class_name EnemyModHealProjectile

var enemy = null
var heal_target = null

func setup(parent_enemy):
	enemy = parent_enemy


func can_heal():
	if enemy.is_dead:
		return false

	if enemy.is_attacking:
		return false

	if enemy.is_shooting:
		return false

	heal_target = find_heal_target()

	if heal_target == null:
		return false

	return true


func find_heal_target():
	var allies = enemy.get_tree().get_nodes_in_group("Enemies")
	var best_target = null
	var best_missing_hp = 0

	for ally in allies:
		if ally == enemy:
			continue

		if not is_instance_valid(ally):
			continue

		if not ally is EnemyBase:
			continue

		if ally.is_dead:
			continue

		if ally.hp >= ally.max_hp:
			continue

		var dist = enemy.global_position.distance_to(ally.global_position)

		if dist > enemy.heal_range:
			continue

		var missing_hp = ally.max_hp - ally.hp

		if missing_hp > best_missing_hp:
			best_missing_hp = missing_hp
			best_target = ally

	return best_target


func on_timer_timeout():
	if not can_heal():
		return

	throw_heal_projectile()


func throw_heal_projectile():
	enemy.is_shooting = true
	enemy.velocity.x = 0

	if enemy.anim.current_animation != enemy.heal_animation_name:
		enemy.anim.play(enemy.heal_animation_name)

	await enemy.get_tree().create_timer(enemy.projectile_spawn_delay).timeout

	if not is_instance_valid(enemy):
		return

	if enemy.is_dead:
		enemy.is_shooting = false
		return

	if heal_target == null:
		enemy.is_shooting = false
		return

	if not is_instance_valid(heal_target):
		enemy.is_shooting = false
		return

	if heal_target.is_dead:
		enemy.is_shooting = false
		return

	var projectile = enemy.projectile_scene.instantiate()
	enemy.get_parent().add_child(projectile)

	if projectile.has_method("setup_target"):
		projectile.setup_target(heal_target)

	var dir = heal_target.global_position - enemy.projectile_spawn.global_position
	projectile.start(enemy.projectile_spawn.global_position, dir.normalized(), enemy.heal_amount)

	enemy.is_shooting = false
	
func find_any_wounded_ally():
	var allies = enemy.get_tree().get_nodes_in_group("Enemies")
	var best_target = null
	var best_missing_hp = 0

	for ally in allies:
		if ally == enemy:
			continue

		if not is_instance_valid(ally):
			continue

		if not ally is EnemyBase:
			continue

		if ally.is_dead:
			continue

		if ally.hp >= ally.max_hp:
			continue

		var missing_hp = ally.max_hp - ally.hp

		if missing_hp > best_missing_hp:
			best_missing_hp = missing_hp
			best_target = ally

	return best_target
