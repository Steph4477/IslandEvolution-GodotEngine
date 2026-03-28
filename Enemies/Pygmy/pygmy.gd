extends EnemyGroundBase

@export var projectile_scene = preload("res://Shoot/Enemies/Spear/spear.tscn")
@export var projectile_spawn_delay = 0.40
@export var projectile_attack_animation = "attack"
@export var jump_animation_name = "jump"

var fire_interval = 3.0
var melee_distance = 70.0
var chase_distance = 260.0
var min_shoot_distance = 300.0
var max_shoot_distance = 2000.0
var jump_velocity = -600.0

var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()
var jump_mod = EnemyModJumpSync.new()

var projectile_spawn = null

func _ready():
	max_hp = 200
	damage = 100
	speed = 100
	gravity = 1000
	attack_range = 99999
	stop_distance = 40
	attack_anim_name = "cac"

	super._ready()

	projectile_spawn = $Rotator/ProjectileSpawn

	melee_mod.setup(self)
	throw_mod.setup(self)
	jump_mod.setup(self)

	if attack_timer:
		attack_timer.wait_time = 1.0
		attack_timer.stop()

	if projectile_timer:
		projectile_timer.wait_time = fire_interval
		projectile_timer.start()

func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)
	target_player()
	flip()
	jump_mod.update()
	melee_mod.update_state()

	if hit_locked:
		stop_and_slide()
		return

	if not is_on_floor():
		if not is_shooting and not is_attacking:
			if anim.current_animation != jump_animation_name:
				anim.play(jump_animation_name)

		move_and_slide()
		return

	if is_attacking:
		stop_and_slide()
		return

	if in_melee:
		stop_and_slide()
		return

	if is_shooting:
		stop_and_slide()
		return

	if distance <= chase_distance:
		move_to_target()
		move_and_slide()
		return

	stop_and_slide()
	play_idle()

func die():
	in_melee = false
	super.die()

func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()

func _on_projectile_timer_timeout():
	throw_mod.on_timer_timeout()
