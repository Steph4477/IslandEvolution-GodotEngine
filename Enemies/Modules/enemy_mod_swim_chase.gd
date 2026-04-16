extends Node
class_name EnemyModSwimChase

var enemy

var aggro_range = 220.0
var attack_range = 40.0
var lose_range = 320.0

func setup(e):
	enemy = e

func process():
	if enemy.is_dead:
		return

	if enemy.is_attacking:
		return

	if enemy.player == null:
		return

	var dist = enemy.get_distance_to_player()

	if dist > lose_range:
		enemy.player = null
		return

	if dist <= attack_range:
		enemy.stop_swim()
		enemy.face_player()
		enemy.attack()
		return

	if dist <= aggro_range:
		enemy.dir = enemy.get_dir_to_player()
		enemy.play_swim()
