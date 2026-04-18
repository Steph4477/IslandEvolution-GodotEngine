extends EnemySwimBase
class_name Pyranha

@export var attack_interval = 1.0
@export var hit_time = 0.6

var patrol_mod
var is_onhit_playing = false

func _ready():
	super._ready()

	if attack_timer:
		attack_timer.wait_time = attack_interval

	patrol_mod = EnemyModSwimPatrol.new()
	patrol_mod.setup(self)

func _physics_process(delta):
	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		refresh_player()

	update_target()

	if is_onhit_playing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if in_melee:
		velocity = Vector2.ZERO
		move_and_slide()

		if not is_attacking:
			play_attack()

		return

	if target != null:
		chase_target()
		play_chase()
	else:
		patrol_mod.process(delta)
		play_swim()

func update_target():
	target = null

	if player == null:
		return

	if player.is_dead:
		return

	if player.is_swimming_under_water:
		target = player

func on_hit(amount):
	if is_dead:
		return

	if hit_locked:
		return

	hp -= amount

	if health_bar:
		health_bar.value = max(hp, 0)

	_show_damage_popup(amount)

	if hp <= 0:
		die()
		return

	hit_locked = true
	is_onhit_playing = true
	is_attacking = false
	velocity = Vector2.ZERO

	if attack_timer:
		attack_timer.stop()

	if anim and anim.has_animation("onhit"):
		anim.play("onhit")
		await anim.animation_finished
	else:
		await get_tree().create_timer(hit_lock_time).timeout

	is_onhit_playing = false
	hit_locked = false

	if in_melee and attack_timer:
		attack_timer.start()

func attack():
	if not can_attack_player():
		return

	is_attacking = true
	velocity = Vector2.ZERO

	play_attack()

	await get_tree().create_timer(hit_time).timeout

	if not is_dead and not is_onhit_playing:
		if player != null and is_instance_valid(player):
			player.damage_mod.on_hit(damage)

	var rest = attack_interval - hit_time
	if rest > 0:
		await get_tree().create_timer(rest).timeout

	is_attacking = false

func _on_patrol_timer_timeout():
	patrol_mod.on_timeout()

func _on_attack_zone_body_entered(body):
	if is_dead:
		return

	if body.is_in_group("Player"):
		in_melee = true

		if not is_attacking and not is_onhit_playing:
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

	if is_onhit_playing:
		return

	attack()
