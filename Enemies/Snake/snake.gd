extends EnemyGroundBase

@export var projectile_scene = preload("res://Shoot/Enemies/Gaz/gaz.tscn")
@export var projectile_spawn_delay = 0.40
@export var projectile_attack_animation = "attack"

var fire_gaz = false
var fire_interval = 2.0
var melee_distance = 200.0
var chase_distance = 460.0
var min_shoot_distance = 201.0
var max_shoot_distance = 360.0

var patrol_speed = 120.0
var patrol_change_interval = 1.0

var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()
var patrol_mod = EnemyModPatrol.new()

var projectile_spawn = null
var patrol_timer = null

var is_patrolling = true
var is_patrol_paused = false
var patrol_direction = 1

func _ready():
	max_hp = 400
	damage = 200
	speed = 200
	gravity = 2000
	attack_range = 99999
	stop_distance = 40
	attack_anim_name = "attack"

	super._ready()

	projectile_spawn = $Rotator/ProjectileSpawn
	patrol_timer = $PatrolTimer

	melee_mod.setup(self)
	throw_mod.setup(self)
	patrol_mod.setup(self)

	if attack_timer:
		attack_timer.wait_time = 1.0
		attack_timer.stop()

	if projectile_timer:
		projectile_timer.wait_time = fire_interval
		projectile_timer.start()

	if patrol_timer:
		patrol_timer.wait_time = patrol_change_interval
		patrol_timer.start()

	patrol_mod.start()

func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)
	target_player()
	melee_mod.update_state()
	update_flip()

	if hit_locked:
		stop_and_slide()
		return

	if not is_on_floor():
		update_air_state()
		return

	if is_attacking:
		stop_and_slide()
		return

	if in_melee:
		update_melee_state()
		return

	if is_shooting:
		update_shooting_state()
		return

	if distance >= min_shoot_distance and distance <= max_shoot_distance:
		update_shoot_zone()
		return

	if distance > max_shoot_distance and distance <= chase_distance:
		update_chase_zone()
		return

	update_patrol_zone()

func update_flip():
	if is_patrolling:
		if patrol_direction < 0:
			$Rotator.scale.x = -base_scale_x
		else:
			$Rotator.scale.x = base_scale_x
	else:
		super.flip()

func update_air_state():
	if not is_shooting and not is_attacking:
		if anim.current_animation != "idle":
			anim.play("idle")

	move_and_slide()

func update_melee_state():
	is_patrolling = false
	fire_gaz = false

	if patrol_timer:
		patrol_timer.stop()

	if projectile_timer:
		projectile_timer.stop()

	stop_and_slide()

func update_shooting_state():
	is_patrolling = false

	if patrol_timer:
		patrol_timer.stop()

	stop_and_slide()

func update_shoot_zone():
	is_patrolling = false

	if patrol_timer:
		patrol_timer.stop()

	if not fire_gaz:
		fire_gaz = true
		throw_mod.on_timer_timeout()

	if projectile_timer and projectile_timer.is_stopped():
		projectile_timer.start()

	stop_and_slide()

func update_chase_zone():
	is_patrolling = false
	fire_gaz = false

	if patrol_timer and patrol_timer.is_stopped():
		patrol_timer.start()

	if projectile_timer:
		projectile_timer.stop()

	move_to_target()
	move_and_slide()

func update_patrol_zone():
	is_patrolling = true
	fire_gaz = false

	if patrol_timer and patrol_timer.is_stopped():
		patrol_timer.start()

	if projectile_timer:
		projectile_timer.stop()

	patrol_mod.update_movement()
	move_and_slide()

	if abs(velocity.x) > 0:
		if anim.current_animation != "patrol":
			anim.play("patrol")
	else:
		if anim.current_animation != "idle":
			anim.play("idle")

func die():
	in_melee = false
	is_patrolling = false
	is_patrol_paused = false

	if patrol_timer:
		patrol_timer.stop()

	if projectile_timer:
		projectile_timer.stop()

	super.die()

func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()

func _on_projectile_timer_timeout():
	if is_dead:
		return

	if in_melee:
		return

	if is_attacking:
		return

	if distance < min_shoot_distance:
		return

	if distance > max_shoot_distance:
		return

	throw_mod.on_timer_timeout()

func _on_patrol_timer_timeout():
	patrol_mod.on_timer_timeout()
