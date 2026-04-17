extends EnemySwimBase
class_name Pyranha

@export var attack_interval = 1.0

var target_mod
var patrol_mod

func _ready():
	super._ready()
	if attack_timer:
		attack_timer.wait_time = attack_interval

	target_mod = EnemyModTarget.new()
	target_mod.setup(self)

	patrol_mod = EnemyModSwimPatrol.new()
	patrol_mod.setup(self)

func _physics_process(delta):
	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		refresh_player()

	if target == null:
		target_mod.update()

	if in_melee:
		velocity = Vector2.ZERO

		if not is_attacking:
			play_attack()

		return

	if target != null:
		chase_target()
		play_chase()
	else:
		patrol_mod.process(delta)
		play_swim()

func attack():
	if not can_attack_player():
		return

	is_attacking = true
	velocity = Vector2.ZERO

	play_attack()

	if player != null and is_instance_valid(player):
		player.damage_mod.on_hit(damage)

	await get_tree().create_timer(attack_interval).timeout

	is_attacking = false

func _on_patrol_timer_timeout():
	patrol_mod.on_timeout()

func _on_attack_zone_body_entered(body):
	if is_dead:
		return

	if body.is_in_group("Player"):
		in_melee = true

		if not is_attacking:
			attack()

		if attack_timer:
			attack_timer.start()

func _on_attack_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false

		if attack_timer:
			attack_timer.stop()

func _on_attack_timer_timeout():
	if is_dead:
		return

	if not in_melee:
		return

	if is_attacking:
		return

	attack()
