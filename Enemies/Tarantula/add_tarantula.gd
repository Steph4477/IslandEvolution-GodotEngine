extends EnemyGroundBase

# --- Export ---
@export var melee_distance = 80
@export var patrol_speed = 50
@export var patrol_change_interval = 3.0
@export var jump_velocity = -450
@export var chase_speed_multiplier = 3

# --- Target ---
var target = null

# --- Modules
var patrol_mod = EnemyModPatrol.new()
var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var jump_mod = EnemyModJumpSync.new()

# --- Patrol
var patrol_timer = null
var patrol_direction = 1
var is_patrolling = true
var is_patrol_paused = false

# -- death 
var jump_animation_name = "jump"
var scene_camera = null
var death_requested = false

var clim = preload("res://Enemies/Tarantula/Effects/ClimAdd/clim_Add.tscn")


# ============================================================================
#                               READY
# ============================================================================

func _ready():
	attack_anim_name = "attack"

	super._ready()

	patrol_timer = $PatrolTimer

	target_mod.setup(self)
	melee_mod.setup(self)
	patrol_mod.setup(self)
	jump_mod.setup(self)

	await play_plafond_intro()

	patrol_mod.start()
	set_physics_process(true)


# ============================================================================
#                               PHYSICS PROCESS
# ============================================================================

func _physics_process(delta):
	if is_dead:
		return

	if is_attacking:
		move_and_slide()
		return

	refresh_player()
	target_mod.update()
	melee_mod.update_state()
	jump_mod.update()

	apply_gravity(delta)
	flip()
	update_movement()

	move_and_slide()


# ============================================================================
#                               INTRO PLAFOND
# ============================================================================

func play_plafond_intro():
	visible = false
	set_physics_process(false)

	var effect = clim.instantiate()
	effect.global_position = global_position
	get_parent().add_child(effect)

	effect.start_clim_down()

	await effect.finished_clim_down

	global_position += Vector2(0, 700)
	visible = true
	$Rotator.visible = true
	anim.play("idle")

	set_physics_process(true)

	await effect.finished_clim_down

	global_position += Vector2(0, 700)
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
	hit_locked = false
	in_melee = false
	velocity = Vector2.ZERO

	attack_timer.stop()
	patrol_timer.stop()

	anim.play("die")
	await anim.animation_finished

	queue_free()


# ============================================================================
#                               SIGNALS
# ============================================================================

func _on_timer_timeout():
	melee_mod.on_timer_timeout()


func _on_patrol_timer_timeout():
	patrol_mod.on_timer_timeout()
