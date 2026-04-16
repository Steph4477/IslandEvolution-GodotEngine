extends Node
class_name EnemyModSwimAggroChase

var enemy

func setup(parent_enemy):
	enemy = parent_enemy

func update_target():
	if not enemy.player:
		enemy.is_chasing = false
		return

	var dist = enemy.global_position.distance_to(enemy.player.global_position)

	if not enemy.is_chasing:
		if dist <= enemy.detection_range:
			enemy.is_chasing = true
	else:
		if dist > enemy.lose_range:
			enemy.is_chasing = false

func chase():
	if not enemy.player:
		enemy.is_chasing = false
		return

	var dir_to_player = enemy.player.global_position - enemy.global_position

	if dir_to_player == Vector2.ZERO:
		enemy.velocity = Vector2.ZERO
		enemy.move_and_slide()
		return

	dir_to_player = dir_to_player.normalized()
	enemy.velocity = dir_to_player * enemy.chase_speed
	enemy.move_and_slide()

	if dir_to_player.x < 0:
		enemy.rotator.scale.x = -1
	elif dir_to_player.x > 0:
		enemy.rotator.scale.x = 1
