extends Node
class_name EnemyModDodgeJump

var enemy

var hit_count = 0

@export var hits_before_dodge = 2
@export var dodge_speed = 1020
@export var dodge_jump_velocity = -1020
@export var dodge_duration = 0.45

var is_dodging = false

func setup(e):
	enemy = e

func register_hit():
	if is_dodging:
		return

	hit_count += 1

	if hit_count >= hits_before_dodge:
		hit_count = 0
		start_dodge()

func start_dodge():
	if is_dodging:
		return

	is_dodging = true

	enemy.is_attacking = false
	enemy.is_shooting = false
	enemy.in_melee = false

	var dir = 1
	if randi() % 2 == 0:
		dir = -1

	enemy.velocity.x = dir * dodge_speed
	enemy.velocity.y = dodge_jump_velocity

	enemy.anim.play(enemy.jump_animation_name)

	await enemy.get_tree().create_timer(dodge_duration).timeout

	is_dodging = false
