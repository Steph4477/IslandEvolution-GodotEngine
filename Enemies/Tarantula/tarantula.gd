extends EnemyGroundBase

# --- Exports ---
@export var melee_distance = 80
@export var min_shoot_distance = 100
@export var max_shoot_distance = 1000
@export var projectile_spawn_delay = 0.6
@export var projectile_timer_time = 2.0
@export var patrol_speed = 50
@export var patrol_change_interval = 3.0
@export var jump_velocity = -550
@export var chase_speed_multiplier = 4

@export var add_phase_hp_ratio = 0.5
@export var ceiling_offset = -300
@export var ceiling_move_speed = 4
@export var regen_per_second = 5

# --- Target ---
var target = null

# --- Projectile ---
var projectile_attack_animation = "attack"
var projectile_spawn = null
var projectile_scene = preload("res://Shoot/Enemies/Web/web.tscn")

# --- Modules ---
var patrol_mod = EnemyModPatrol.new()
var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()
var jump_mod = EnemyModJumpSync.new()

#--- Patrol ---
var patrol_timer = null
var patrol_direction = 1
var is_patrolling = true
var is_patrol_paused = false

# --- Intro/death ---
var jump_animation_name = "jump"
var scene_camera = null
var death_requested = false

var death_effect = preload("res://Enemies/Tarantula/effects/enemy_death_particles.tscn")
var descent_intro = preload("res://Enemies/Tarantula/effects/descent.tscn")

# --- Add Phase ---
var add_scene = preload("res://Enemies/Tarantula/addTarantula.tscn")

var add_spawns = []
var spawned_adds = []

var add_phase_used = false
var is_in_add_phase = false
var is_on_ceiling = false
var ground_position = Vector2.ZERO


func _ready():
	attack_anim_name = "attack"

	super._ready()

	projectile_spawn = $Rotator/Muzzle
	patrol_timer = $PatrolTimer

	target_mod.setup(self)
	melee_mod.setup(self)
	throw_mod.setup(self)
	patrol_mod.setup(self)
	jump_mod.setup(self)

	setup_add_spawns()

	await play_plafond_intro()

	projectile_timer.wait_time = projectile_timer_time
	projectile_timer.start()

	patrol_mod.start()
	set_physics_process(true)

	# --- TEST TEMPORAIRE ADD PHASE ---
	await get_tree().create_timer(1.0).timeout
	start_add_phase()


func _physics_process(delta):
	if is_dead:
		return

	update_add_phase_trigger()

	if is_in_add_phase:
		velocity = Vector2.ZERO
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
	shoot_while_jumping()

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

	scene_camera.zoom = Vector2(1.2, 1.2)
	scene_camera.global_position = global_position

	var intro_effect = descent_intro.instantiate()
	intro_effect.global_position = global_position + Vector2(0, -354)
	get_parent().add_child(intro_effect)

	await intro_effect.finished_descent

	global_position += Vector2(0, 250)
	visible = true
	$Rotator.visible = true
	anim.play("idle")

	set_physics_process(true)

	refresh_player()
	await get_tree().create_timer(1.5).timeout

	var player_camera = player.get_node("Camera2D")
	player_camera.make_current()
	player_camera.zoom = Vector2(1, 1)

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

func shoot_while_jumping():
	if is_on_floor():
		return

	if target == null:
		return

	if in_melee:
		return

	throw_mod.on_timer_timeout()


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
# --- Add Spawn Setup ---
func setup_add_spawns():
	var root = get_parent().get_node_or_null("AddSpawns")
	if root == null:
		return

	for spawn in root.get_children():
		add_spawns.append(spawn)


func update_add_phase_trigger():
	if add_phase_used:
		return

	if hp <= max_hp * add_phase_hp_ratio:
		start_add_phase()


# ============================================================================
#                               ADD PHASE START
# ============================================================================

func start_add_phase():
	if is_in_add_phase:
		return

	add_phase_used = true
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

	spawn_adds()

	start_regen_loop()


# ============================================================================
#                               CEILING MOVEMENT
# ============================================================================

func go_to_ceiling():
	var target_pos = ground_position + Vector2(0, ceiling_offset)

	while global_position.y > target_pos.y:
		global_position.y -= ceiling_move_speed
		await get_tree().process_frame

	global_position = target_pos
	is_on_ceiling = true


func go_back_to_ground():
	while global_position.y < ground_position.y:
		global_position.y += ceiling_move_speed
		await get_tree().process_frame

	global_position = ground_position
	is_on_ceiling = false


# ============================================================================
#                               ADD SPAWN
# ============================================================================

func spawn_adds():
	spawned_adds.clear()

	print("SPAWNS FOUND: ", add_spawns.size())

	for spawn in add_spawns:
		print("SPAWN ADD: ", spawn.name, " POS: ", spawn.global_position)

		var add = add_scene.instantiate()
		add.global_position = spawn.global_position
		get_parent().add_child(add)

		spawned_adds.append(add)

# ============================================================================
#                               HEALTH BAR
# ============================================================================

func update_health_bar():
	health_bar.set_value(hp)

# ============================================================================
#                               REGEN
# ============================================================================

func start_regen_loop():
	while is_in_add_phase:
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

	anim.play("die")
	await anim.animation_finished

	var particles = death_effect.instantiate()
	particles.global_position = global_position
	get_parent().add_child(particles)
	particles.get_node("CPUParticles2D").emitting = true

	spawn_loot()
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
