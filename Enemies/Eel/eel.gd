extends EnemySwimBase
class_name Eel

@export var attack_interval = 2.0
@export var hit_time = 0.2

@export var melee_distance = 70.0
@export var min_shoot_distance = 20.0
@export var max_shoot_distance = 860.0

@export var shoot_interval = 1.6
@export var projectile_attack_animation = "attack"
@export var projectile_spawn_delay = 0.35

@export var shock_damage = 40
@export var shock_screen_time = 2.0

@export var projectile_scene = preload("res://Shoot/Enemies/Electric/electric.tscn")

var is_onhit_playing = false

var throw_mod
var projectile_spawn
var shoot_timer

func _ready():
	super._ready()

	projectile_spawn = $Rotator/ProjectileSpawn
	shoot_timer = $ShootTimer

	if attack_timer:
		attack_timer.wait_time = attack_interval

	if shoot_timer:
		shoot_timer.wait_time = shoot_interval
		shoot_timer.start()

	setup_patrol()

	throw_mod = EnemyModThrowProjectile.new()
	throw_mod.setup(self)

func _physics_process(delta):
	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		refresh_player()

	target = null
	distance = 999999

	if player != null and is_instance_valid(player):
		distance = global_position.distance_to(player.global_position)

		if distance >= min_shoot_distance and distance <= max_shoot_distance:
			target = player

	if is_onhit_playing:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if in_melee:
		velocity = Vector2.ZERO
		move_and_slide()

		if not is_attacking:
			attack()

		return

	if target != null:
		velocity = Vector2.ZERO
		move_and_slide()

		if not is_shooting and not is_attacking:
			play_swim()
	else:
		process_swim_state(delta)

func _process(_delta):
	if is_shooting:
		velocity = Vector2.ZERO

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
	is_shooting = false
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
	if is_dead:
		return

	if is_attacking:
		return

	if is_onhit_playing:
		return

	is_attacking = true
	velocity = Vector2.ZERO

	play_attack()

	await get_tree().create_timer(hit_time).timeout

	if not is_dead and not is_onhit_playing:
		if player != null and is_instance_valid(player):
			player.damage_mod.on_hit(shock_damage)

			if player.effects_mod and player.effects_mod.has_method("start_electric_screen_flash"):
				player.effects_mod.start_electric_screen_flash(shock_screen_time)

	var rest = attack_interval - hit_time
	if rest > 0:
		await get_tree().create_timer(rest).timeout

	is_attacking = false

func _on_patrol_timer_timeout():
	if patrol_mod:
		patrol_mod.on_timeout()

	restart_patrol_timer()

func _on_shoot_timer_timeout():
	if is_dead:
		return

	if is_onhit_playing:
		return

	if in_melee:
		return

	if target == null:
		return

	if distance < min_shoot_distance:
		return

	if distance > max_shoot_distance:
		return

	velocity = Vector2.ZERO
	move_and_slide()

	if throw_mod:
		throw_mod.on_timer_timeout()

func _on_attack_zone_body_entered(body):
	if is_dead:
		return

	if body.is_in_group("Player"):
		in_melee = true

		if not is_attacking and not is_onhit_playing and not is_shooting:
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

	if is_shooting:
		return

	attack()
