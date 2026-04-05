extends Node
class_name EnemyModJumpSync

var enemy = null
var player_prev_on_floor = true

func setup(parent_enemy):
	enemy = parent_enemy

func update():
	if enemy.target == null:
		return

	if not is_instance_valid(enemy.target):
		return

	var p_on_floor = enemy.target.is_on_floor()
	var player_started_jump = false

	if player_prev_on_floor and not p_on_floor and enemy.target.velocity.y < 0:
		player_started_jump = true

	player_prev_on_floor = p_on_floor

	if player_started_jump and enemy.is_on_floor():
		enemy.velocity.y = enemy.jump_velocity

		if not enemy.is_shooting and not enemy.is_attacking:
			enemy.anim.play(enemy.jump_animation_name)
