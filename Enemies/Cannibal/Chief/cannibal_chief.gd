extends EnemyGroundBase

@export var projectile_scene = preload("res://Shoot/Enemies/Spear/spear.tscn")
@export var projectile_spawn_delay = 0.40
@export var projectile_attack_animation = "attack"
@export var jump_animation_name = "jump"

@export var charge_speed = 600.0
@export var charge_min_range = 250.0
@export var charge_max_range = 600.0
@export var charge_duration = 0.6
@export var charge_cooldown = 2.5
@export var charge_animation_name = "run"

@export var appear_distance = 200.0

@onready var smoke_spawn = $Rotator/SmokeSpawn
var smoke_scene = preload("res://Enemies/Cannibal/Effects/dust_charge.tscn")

var fire_interval = 3.0
var melee_distance = 70.0
var chase_distance = 260.0
var min_shoot_distance = 300.0
var max_shoot_distance = 2000.0
var jump_velocity = -600.0

var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()
var jump_mod = EnemyModJumpSync.new()
var charge_mod = EnemyModWildCharge.new()

var projectile_spawn = null

var is_jumping = false
var is_charging = false
var charge_dir = 0
var charge_time = 0.0
var charge_cooldown_left = 0.0
var horiz_distance = 0.0

var has_appeared = false

var dust_scene = null
var dust_origin = null


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
	charge_mod.setup(self)

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
	horiz_distance = abs(dx)
	flip()

	if not has_appeared:
		if horiz_distance <= appear_distance:
			anim.play("appear")
			await anim.animation_finished
			has_appeared = true
		else:
			stop_and_slide()
			return

	jump_mod.update()
	melee_mod.update_state()
	charge_mod.update(delta)

	if hit_locked:
		stop_and_slide()
		return

	if is_charging:
		move_and_slide()
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
	charge_mod.cancel_charge()
	super.die()


func _on_attack_timer_timeout():
	if is_charging:
		return
	melee_mod.on_timer_timeout()


func _on_projectile_timer_timeout():
	if not has_appeared:
		return
	if is_charging:
		return
	throw_mod.on_timer_timeout()
