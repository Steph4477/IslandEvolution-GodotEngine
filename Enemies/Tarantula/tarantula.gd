extends EnemyGroundBase

# --- Exports ---
var melee_distance = 0
var min_shoot_distance = 0
var max_shoot_distance = 0
var projectile_spawn_delay = 0.2
var projectile_timer_time = 0
@export var jump_velocity = -550
@export var chase_speed_multiplier = 4

@export var add_phase_hp_ratio = 0.5
@export var ceiling_offset = -300
@export var ceiling_move_speed = 4
@export var regen_per_second = 20

@export var add_spawn_offset_x = 220
@export var add_spawn_interval_min = 0.35
@export var add_spawn_interval_max = 1.0

# --- Target ---
var target = null

# --- Projectile ---
var projectile_attack_animation = "attack"
var projectile_spawn = null
var projectile_scene = preload("res://Shoot/Enemies/Web/web.tscn")

# --- Modules ---
var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()
var jump_mod = EnemyModJumpSync.new()
var dodge_mod = EnemyModDodgeJump.new()

# --- Intro/death ---
var jump_animation_name = "jump"
var scene_camera = null
var death_requested = false

var death_effect = preload("res://Enemies/Tarantula/Effects/enemy_death_particles.tscn")
var clim = preload("res://Enemies/Tarantula/Effects/ClimTarantula/clim_tarantula.tscn")

# --- Add Phase ---
var add_scene = preload("res://Enemies/Tarantula/addTarantula.tscn")

var add_spawns = []
var spawned_adds = []

var next_add_phase_hp = 0
var is_in_add_phase = false
var ceiling_point = null
var on_ceiling = false
var ceiling_effect = null
var ground_position = Vector2.ZERO


func _ready():
	max_hp = GameBalance.ENEMY_HP["boss_tarantula"]
	damage = GameBalance.ENEMY_DAMAGE["boss"]
	projectile_damage = GameBalance.ENEMY_PROJECTILE["web"]

	speed = GameBalance.ENEMY_SPEED["boss_tarantula"]
	attack_range = GameBalance.ENEMY_RANGE["boss_tarantula"]

	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE["boss_tarantula"]

	min_shoot_distance = GameBalance.ENEMY_MIN_SHOOT_DISTANCE["boss_tarantula"]
	max_shoot_distance = GameBalance.ENEMY_MAX_SHOOT_DISTANCE["boss_tarantula"]

	projectile_timer_time = GameBalance.ENEMY_COOLDOWN["boss_tarantula"]
	
	randomize()

	attack_anim_name = "attack"
	ceiling_point = get_parent().get_node("CeilingPoint")
	super._ready()

	projectile_spawn = $Rotator/Muzzle
	patrol_timer = $PatrolTimer

	target_mod.setup(self)
	melee_mod.setup(self)
	throw_mod.setup(self)
	patrol_mod.setup(self)
	jump_mod.setup(self)
	dodge_mod.setup(self)

	setup_add_spawns()

	await play_plafond_intro()

	
	projectile_timer.wait_time = projectile_timer_time
	projectile_timer.start()

	patrol_mod.start()
	set_physics_process(true)
	next_add_phase_hp = hp * add_phase_hp_ratio


func _physics_process(delta):
	if is_dead:
		return

	update_add_phase_trigger()

	if is_in_add_phase:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if dodge_mod.is_dodging:
		apply_gravity(delta)
		move_and_slide()
		return

	if is_attacking:
		move_and_slide()
		return

	if is_shooting:
		apply_gravity(delta)
		velocity.x = 0
		move_and_slide()
		return

	refresh_player()
	target_mod.update()
	melee_mod.update_state()
	jump_mod.update()
	update_projectile_animation()

	apply_gravity(delta)
	flip()
	update_movement()

	move_and_slide()


# ============================================================================
#                               INTRO PLAFOND
# ============================================================================
func play_plafond_intro():
	refresh_player()
	await get_tree().process_frame
	player.can_move = false
	
	visible = false
	set_physics_process(false)

	while scene_camera == null:
		await get_tree().process_frame
		scene_camera = get_viewport().get_camera_2d()

	scene_camera.global_position = global_position

	var effect = clim.instantiate()
	effect.global_position = ceiling_point.global_position
	get_parent().add_child(effect)

	effect.start_clim_down()

	visible = false
	set_physics_process(false)

	await effect.finished_clim_down

	global_position += Vector2(0, 450)
	visible = true
	$Rotator.visible = true
	anim.play("idle")

	set_physics_process(true)

	refresh_player()
	await get_tree().create_timer(1.5).timeout

	var player_camera = player.get_node("Camera2D")
	player_camera.make_current()

	await get_tree().process_frame
	player_camera.global_position = player.global_position

	player.can_move = true


# ============================================================================
#                               MOVEMENT
# ============================================================================

func update_movement():
	if target == null:
		is_patrolling = true
		is_patrol_paused = false
		patrol_mod.update_movement()
		play_patrol_animation()
	else:
		is_patrolling = false
		chase_target()


func chase_target():
	var current_speed = speed

	if distance > attack_range:
		current_speed = speed * chase_speed_multiplier

	if distance <= max_shoot_distance and distance >= min_shoot_distance:
		velocity.x = 0
		return

	if dx > stop_distance:
		velocity.x = current_speed
		anim.play("walk")
	elif dx < -stop_distance:
		velocity.x = -current_speed
		anim.play("walk")
	else:
		velocity.x = 0
		play_idle()


# ============================================================================
#                               PROJECTILE ATTACK
# ============================================================================
func update_projectile_animation():
	if is_on_floor():
		projectile_attack_animation = "attack"
	else:
		projectile_attack_animation = "jump"


# ============================================================================
#                               ANIMATIONS
# ============================================================================

func play_patrol_animation():
	if velocity.x != 0:
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		play_idle()


# ============================================================================
#                               MELEE ATTACK
# ============================================================================

func attack():
	if not can_attack_player():
		return

	is_attacking = true
	velocity.x = 0
	anim.play(attack_anim_name)

	await get_tree().create_timer(anim.get_animation(attack_anim_name).length).timeout

	do_attack_damage()
	is_attacking = false


# ============================================================================
#                               ADD PHASE SETUP
# ============================================================================

func setup_add_spawns():
	var root = get_parent().get_node_or_null("AddSpawns")
	if root == null:
		return

	for spawn in root.get_children():
		add_spawns.append(spawn)


func update_add_phase_trigger():
	if is_in_add_phase:
		return

	if hp <= 0:
		return

	if hp <= next_add_phase_hp:
		start_add_phase()


# ============================================================================
#                               ADD PHASE START
# ============================================================================

func start_add_phase():
	if is_in_add_phase:
		return

	is_in_add_phase = true
	is_attacking = false
	is_shooting = false
	in_melee = false
	velocity = Vector2.ZERO

	ground_position = global_position

	attack_timer.stop()
	projectile_timer.stop()
	patrol_timer.stop()

	anim.play("idle")

	await go_to_ceiling()

	if is_dead:
		return

	await spawn_adds()

	if is_dead:
		return

	start_regen_loop()


# ============================================================================
#                               CEILING MOVEMENT
# ============================================================================

func go_to_ceiling():
	ceiling_effect = clim.instantiate()
	ceiling_effect.global_position = ceiling_point.global_position
	get_parent().add_child(ceiling_effect)

	visible = false
	$Rotator.visible = false
	set_physics_process(false)

	ceiling_effect.start_clim_up()

	await ceiling_effect.finished_clim_up

	global_position = ceiling_point.global_position
	on_ceiling = true
	set_physics_process(true)


func go_back_to_ground():
	if ceiling_effect:
		ceiling_effect.queue_free()
		ceiling_effect = null

	var effect = clim.instantiate()
	effect.global_position = ceiling_point.global_position
	get_parent().add_child(effect)

	visible = false
	$Rotator.visible = false
	set_physics_process(false)

	effect.start_clim_down()

	await effect.finished_clim_down

	global_position = ground_position
	visible = true
	$Rotator.visible = true
	on_ceiling = false
	set_physics_process(true)


# ============================================================================
#                               ADD SPAWN
# ============================================================================

func spawn_adds():
	spawned_adds.clear()

	for spawn in add_spawns:
		if is_dead:
			return

		var add = add_scene.instantiate()
		var offset_x = randf_range(-add_spawn_offset_x, add_spawn_offset_x)

		add.global_position = spawn.global_position + Vector2(offset_x, 0)
		get_parent().add_child(add)

		spawned_adds.append(add)

		var delay = randf_range(add_spawn_interval_min, add_spawn_interval_max)
		await get_tree().create_timer(delay).timeout


# ============================================================================
#                               HEALTH BAR
# ============================================================================

func update_health_bar():
	health_bar.set_value(hp)

	gs.update_boss_fight_hud()


# ============================================================================
#                               REGEN
# ============================================================================

func start_regen_loop():
	while is_in_add_phase:
		if is_dead:
			return

		clean_dead_adds()

		if spawned_adds.size() == 0:
			end_add_phase()
			return

		hp += regen_per_second

		if hp > max_hp:
			hp = max_hp

		update_health_bar()

		await get_tree().create_timer(1.0).timeout


func clean_dead_adds():
	var alive_adds = []

	for add in spawned_adds:
		if is_instance_valid(add) and not add.is_dead:
			alive_adds.append(add)

	spawned_adds = alive_adds


# ============================================================================
#                               ADD PHASE END
# ============================================================================

func end_add_phase():
	is_in_add_phase = false

	await go_back_to_ground()

	is_attacking = false
	is_shooting = false
	in_melee = false
	velocity = Vector2.ZERO

	projectile_timer.start()
	patrol_timer.start()
	patrol_mod.start()

	anim.play("idle")
	next_add_phase_hp = hp * add_phase_hp_ratio


# ============================================================================
#                               ON HIT / DODGE
# ============================================================================

func on_hit(amount):
	if is_dead:
		return

	if hit_locked:
		return

	if is_in_add_phase:
		super.on_hit(amount)

		gs.update_boss_fight_hud()
		return

	dodge_mod.register_hit()
	super.on_hit(amount)

	gs.update_boss_fight_hud()


# ============================================================================
#                               DEATH
# ============================================================================

func die():
	if death_requested:
		return

	death_requested = true
	call_deferred("_do_die")


func _do_die():
	if is_dead:
		return

	var died_on_ceiling = on_ceiling

	is_dead = true
	is_attacking = false
	is_shooting = false
	hit_locked = false
	in_melee = false
	is_in_add_phase = false
	velocity = Vector2.ZERO

	attack_timer.stop()
	projectile_timer.stop()
	patrol_timer.stop()

	for add in spawned_adds:
		if is_instance_valid(add):
			add.queue_free()

	spawned_adds.clear()

	if ceiling_effect:
		ceiling_effect.queue_free()
		ceiling_effect = null

	if died_on_ceiling:
		visible = true
		$Rotator.visible = true
		set_physics_process(false)

		global_position = ceiling_point.global_position
		anim.play("jump")

		var tween = create_tween()
		tween.tween_property(self, "global_position", ground_position, 0.8)
		await tween.finished

		on_ceiling = false

	anim.play("die")
	await anim.animation_finished

	var particles = death_effect.instantiate()
	particles.global_position = global_position
	get_parent().add_child(particles)
	particles.get_node("CPUParticles2D").emitting = true

	spawn_loot()

	gs.hide_boss_fight_hud()

	queue_free()


# ============================================================================
#                               SIGNALS
# ============================================================================

func _on_timer_timeout():
	melee_mod.on_timer_timeout()


func _on_projectile_timer_timeout():
	throw_mod.on_timer_timeout()


func _on_patrol_timer_timeout():
	patrol_mod.on_timer_timeout()
