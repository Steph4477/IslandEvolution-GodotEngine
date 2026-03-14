extends EnemyFlightBase

const DEFAULT_CHASE_SPEED = 220.0
const DEFAULT_ATTACK_RANGE = 500.0
const DEFAULT_CONTACT_ATTACK_RADIUS = 12.0
const DEFAULT_COOLDOWN = 1.2

const DEFAULT_ORBIT_RADIUS_X = 90.0
const DEFAULT_ORBIT_RADIUS_Y = 55.0
const DEFAULT_ORBIT_ANGULAR_SPEED = 7.0
const DEFAULT_ORBIT_DURATION = 1.2

const DEFAULT_OSC_RADIAL_AMPLITUDE = 4.0
const DEFAULT_OSC_RADIAL_FREQUENCY = 8.0
const DEFAULT_OSC_ANGLE_AMPLITUDE = 0.08
const DEFAULT_OSC_ANGLE_FREQUENCY = 6.0

const DEFAULT_SWARM_COUNT = 3
const DEFAULT_SWARM_SPAWN_RADIUS = 50.0
const DEFAULT_SWARM_ORBIT_STEP_X = 28.0
const DEFAULT_SWARM_ORBIT_STEP_Y = 18.0

const PHASE_PATROL = 0
const PHASE_ORBIT = 1

@export var chase_speed = DEFAULT_CHASE_SPEED
@export var attack_range = DEFAULT_ATTACK_RANGE
@export var contact_attack_radius = DEFAULT_CONTACT_ATTACK_RADIUS
@export var cooldown = DEFAULT_COOLDOWN

@export var orbit_radius_x = DEFAULT_ORBIT_RADIUS_X
@export var orbit_radius_y = DEFAULT_ORBIT_RADIUS_Y
@export var orbit_angular_speed = DEFAULT_ORBIT_ANGULAR_SPEED
@export var orbit_duration = DEFAULT_ORBIT_DURATION

@export var osc_radial_amplitude = DEFAULT_OSC_RADIAL_AMPLITUDE
@export var osc_radial_frequency = DEFAULT_OSC_RADIAL_FREQUENCY
@export var osc_angle_amplitude = DEFAULT_OSC_ANGLE_AMPLITUDE
@export var osc_angle_frequency = DEFAULT_OSC_ANGLE_FREQUENCY

@export var swarm_count = DEFAULT_SWARM_COUNT
@export var swarm_spawn_radius = DEFAULT_SWARM_SPAWN_RADIUS
@export var swarm_orbit_step_x = DEFAULT_SWARM_ORBIT_STEP_X
@export var swarm_orbit_step_y = DEFAULT_SWARM_ORBIT_STEP_Y

var phase = PHASE_PATROL

var base_orbit_radius_x = null
var base_orbit_radius_y = null

var swarm_slot = 0
var is_swarm_clone = false
var spawn_swarm_on_ready = true
var swarm_controller = null

var patrol_mod = EnemyModFlightPatrol.new()
var orbit_mod = EnemyModFlightOrbit.new()
var swarm_mod = EnemyModFlightSwarm.new()

func _ready():
	max_hp = 20
	damage = 20
	attack_anim_name = "attack"

	ensure_orbit_defaults()

	super._ready()

	patrol_mod.setup(self)
	orbit_mod.setup(self)

	if is_swarm_clone:
		if swarm_controller == null:
			swarm_controller = swarm_mod
	else:
		swarm_mod.setup(self)
		swarm_controller = swarm_mod

	apply_swarm_orbit_values()
	patrol_mod.start()

	if not is_swarm_clone and spawn_swarm_on_ready:
		call_deferred("_build_swarm_deferred")

func _build_swarm_deferred():
	if is_dead:
		return

	if swarm_controller == null:
		return

	swarm_controller.build_swarm()

func _physics_process(delta):
	if is_dead:
		return

	if player == null:
		refresh_player()
		if player == null:
			return

	if not is_instance_valid(player):
		return

	update_phase(delta)
	update_flip()
	move_flight()
	check_attack_hit()

func get_target_position():
	if player == null:
		refresh_player()
		if player == null:
			return global_position

	if player.has_node("TurnAxis"):
		return player.get_node("TurnAxis").global_position

	return player.global_position

func update_phase(delta):
	var distance = get_target_distance()

	if distance > attack_range:
		update_chase_state()
		return

	phase = PHASE_ORBIT
	update_orbit_or_attack_state(delta)

func update_orbit_or_attack_state(delta):
	if is_attacking:
		return

	if can_swarm_attack_now():
		update_attack_run_state()
		return

	apply_swarm_orbit_values()
	orbit_mod.update(delta)

	if orbit_mod.is_finished():
		orbit_mod.start()

func update_chase_state():
	phase = PHASE_PATROL

	var target = get_target_position()
	var direction = (target - global_position).normalized()

	flight_velocity = direction * chase_speed
	play_flight_anim("flight")

func update_attack_run_state():
	var target = get_target_position()
	var direction = (target - global_position).normalized()

	flight_velocity = direction * chase_speed
	play_flight_anim("flight")

func check_attack_hit():
	if phase != PHASE_ORBIT:
		return

	if is_attacking:
		return

	if not can_swarm_attack_now():
		return

	if get_target_distance() > contact_attack_radius:
		return

	perform_attack()

func perform_attack():
	is_attacking = true
	stop_flight()

	if anim != null:
		if anim.current_animation != "attack":
			anim.play("attack")

	do_attack_damage()

	await get_tree().create_timer(cooldown).timeout

	is_attacking = false
	notify_swarm_attack_finished()

	if not is_dead:
		apply_swarm_orbit_values()
		orbit_mod.start()

func can_swarm_attack_now():
	if swarm_controller == null:
		return true

	return swarm_controller.can_member_attack(self)

func notify_swarm_attack_finished():
	if swarm_controller == null:
		return

	swarm_controller.notify_member_attack_finished(self)

func ensure_orbit_defaults():
	if chase_speed == null:
		chase_speed = DEFAULT_CHASE_SPEED

	if attack_range == null:
		attack_range = DEFAULT_ATTACK_RANGE

	if contact_attack_radius == null:
		contact_attack_radius = DEFAULT_CONTACT_ATTACK_RADIUS

	if cooldown == null:
		cooldown = DEFAULT_COOLDOWN

	if orbit_radius_x == null:
		orbit_radius_x = DEFAULT_ORBIT_RADIUS_X

	if orbit_radius_y == null:
		orbit_radius_y = DEFAULT_ORBIT_RADIUS_Y

	if orbit_angular_speed == null:
		orbit_angular_speed = DEFAULT_ORBIT_ANGULAR_SPEED

	if orbit_duration == null:
		orbit_duration = DEFAULT_ORBIT_DURATION

	if osc_radial_amplitude == null:
		osc_radial_amplitude = DEFAULT_OSC_RADIAL_AMPLITUDE

	if osc_radial_frequency == null:
		osc_radial_frequency = DEFAULT_OSC_RADIAL_FREQUENCY

	if osc_angle_amplitude == null:
		osc_angle_amplitude = DEFAULT_OSC_ANGLE_AMPLITUDE

	if osc_angle_frequency == null:
		osc_angle_frequency = DEFAULT_OSC_ANGLE_FREQUENCY

	if swarm_count == null:
		swarm_count = DEFAULT_SWARM_COUNT

	if swarm_spawn_radius == null:
		swarm_spawn_radius = DEFAULT_SWARM_SPAWN_RADIUS

	if swarm_orbit_step_x == null:
		swarm_orbit_step_x = DEFAULT_SWARM_ORBIT_STEP_X

	if swarm_orbit_step_y == null:
		swarm_orbit_step_y = DEFAULT_SWARM_ORBIT_STEP_Y

	if swarm_slot == null:
		swarm_slot = 0

	if base_orbit_radius_x == null:
		base_orbit_radius_x = orbit_radius_x

	if base_orbit_radius_y == null:
		base_orbit_radius_y = orbit_radius_y

func apply_swarm_orbit_values():
	ensure_orbit_defaults()

	var bx = base_orbit_radius_x
	var by = base_orbit_radius_y
	var sx = swarm_orbit_step_x
	var sy = swarm_orbit_step_y
	var slot = swarm_slot

	if bx == null:
		bx = DEFAULT_ORBIT_RADIUS_X

	if by == null:
		by = DEFAULT_ORBIT_RADIUS_Y

	if sx == null:
		sx = DEFAULT_SWARM_ORBIT_STEP_X

	if sy == null:
		sy = DEFAULT_SWARM_ORBIT_STEP_Y

	if slot == null:
		slot = 0

	orbit_radius_x = bx + (float(slot) * sx)
	orbit_radius_y = by + (float(slot) * sy)

func on_hit(amount):
	if is_dead:
		return

	if swarm_controller != null:
		if not swarm_controller.can_take_swarm_hit():
			return

	super.on_hit(amount)

func _unlock_swarm_hit():
	if swarm_controller == null:
		return

	swarm_controller.unlock_swarm_hit()

func die():
	if is_dead:
		return

	if swarm_controller != null:
		swarm_controller.unregister_member(self)

	super.die()
