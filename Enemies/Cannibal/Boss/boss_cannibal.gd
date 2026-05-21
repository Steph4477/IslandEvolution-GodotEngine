extends EnemyGroundBase

@export var projectile_scene = preload("res://Shoot/Enemies/Harpon/harpon.tscn")
@export var projectile_spawn_delay = 0.40

@export var melee_distance = 120.0
@export var min_shoot_distance = 120.0
@export var max_shoot_distance = 2000.0

@export var jump_attack_interval = 15.0
@export var jump_velocity = -900.0

@export var quake_duration = 2.5
@export var quake_damage = 50

var projectile_attack_animation = "attack"
var jump_animation_name = "jump"

var fire_interval = 3.0

var target = null
var projectile_spawn = null

var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()

var is_quaking = false
var is_quake_jumping = false
var has_left_floor = false

@onready var jump_timer = $JumpTimer

# ============================================================================
#                                  READY
# ============================================================================
func _ready():
	attack_anim_name = "cac"

	super._ready()

	set_meta("boss_portrait", preload("res://Hud/BossHud/HudFightBoss/HudBoss/Cannibale/cannibale.png"))
	set_meta("boss_name", preload("res://Hud/BossHud/HudFightBoss/HudBoss/Cannibale/cannibaleName.png"))

	min_shoot_distance = melee_distance
	stop_distance = melee_distance - 10.0
	attack_range = max_shoot_distance

	projectile_spawn = $Rotator/ProjectileSpawn

	target_mod.setup(self)
	melee_mod.setup(self)
	throw_mod.setup(self)

	attack_timer.wait_time = 1.0
	attack_timer.stop()

	projectile_timer.wait_time = fire_interval
	projectile_timer.start()

	jump_timer.wait_time = jump_attack_interval
	jump_timer.start()

# ============================================================================
#                                  PHYSICS
# ============================================================================
func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)

	update_quake_jump()

	if is_quake_jumping:
		move_and_slide()
		return

	target_mod.update()
	flip()
	melee_mod.update_state()

	if hit_locked:
		stop_and_slide()
		return

	if is_quaking:
		velocity.x = 0

		if anim.current_animation != "jump_quake":
			anim.play("jump_quake")

		stop_and_slide()
		return

	if not is_on_floor():
		update_air_state()
		move_and_slide()
		return

	if target == null:
		velocity.x = 0
		stop_and_slide()
		play_idle()
		return

	if is_attacking or in_melee or is_shooting:
		stop_and_slide()
		return

	update_walk_state()

	move_and_slide()

# ============================================================================
#                            SAUT / TREMBLEMENT DE TERRE
# ============================================================================
# --- Etats de déplacement ---
func update_air_state():
	if not is_shooting and not is_attacking:
		if anim.current_animation != jump_animation_name:
			anim.play(jump_animation_name)

func update_walk_state():
	if distance > stop_distance:
		if dx > 0:
			velocity.x = speed
		else:
			velocity.x = -speed

		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity.x = 0
		play_idle()

# --- Saut puissant ---
func start_quake_jump():
	if is_dead:
		return

	if is_quaking:
		return

	if is_quake_jumping:
		return

	if player == null:
		return

	is_quaking = true
	is_quake_jumping = true
	has_left_floor = false

	is_attacking = false
	is_shooting = false

	projectile_timer.stop()
	attack_timer.stop()

	velocity.x = 0
	velocity.y = jump_velocity

	anim.play("jump")

func update_quake_jump():
	if not is_quake_jumping:
		return

	if not is_on_floor():
		has_left_floor = true

	if has_left_floor and is_on_floor():
		start_quake()

func start_quake():
	is_quake_jumping = false

	velocity.x = 0
	velocity.y = 0

	anim.play("jump_quake")

	await shake_camera_and_damage_player()

	is_quaking = false

	target_mod.update()

	if target != null:
		if distance >= min_shoot_distance and distance <= max_shoot_distance:
			throw_mod.on_timer_timeout()

	projectile_timer.start()

	if in_melee:
		attack_timer.start()

# --- Shake caméra et dégâts ---
func shake_camera_and_damage_player():
	var cam = get_viewport().get_camera_2d()

	var original_offset = cam.offset
	var elapsed = 0.0

	while elapsed < quake_duration:
		cam.offset = Vector2(
			randf_range(-20.0, 20.0),
			randf_range(-15.0, 15.0)
		)

		if player.is_on_floor():
			player.damage_mod.on_hit(quake_damage)

		await get_tree().create_timer(0.5).timeout

		elapsed += 0.5

	cam.offset = original_offset


# ============================================================================
#                                  ON HIT
# ============================================================================
func on_hit(amount):
	if is_dead:
		return

	if hit_locked:
		return

	super.on_hit(amount)

	gs.update_boss_fight_hud()


# ============================================================================
#                                   DIE
# ============================================================================
func die():
	in_melee = false

	is_quaking = false
	is_quake_jumping = false
	has_left_floor = false

	jump_timer.stop()

	var cam = get_viewport().get_camera_2d()

	if cam:
		cam.offset = Vector2.ZERO

	gs.hide_boss_fight_hud()

	super.die()

# ============================================================================
#                                  TIMERS
# ============================================================================
func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()

func _on_projectile_timer_timeout():
	if is_quaking:
		return

	throw_mod.on_timer_timeout()

func _on_jump_timer_timeout():
	start_quake_jump()
