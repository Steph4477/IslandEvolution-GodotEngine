extends EnemyFlightBase

var chase_speed = 0
var attack_range = 0
@export var contact_attack_radius = 24.0
var cooldown = 0
@export var patrol_speed = 80
@export var swarm_count = 3

const PHASE_PATROL = 0
const PHASE_ORBIT = 1
const PHASE_CHARGE = 2

var patrol_change_interval = 2.0

var orbit_radius_x = 90.0
var orbit_radius_y = 55.0
var orbit_angular_speed = 6.0
var orbit_duration = 1.2

var osc_radial_amplitude = 6.0
var osc_radial_frequency = 10.0
var osc_angle_amplitude = 0.12
var osc_angle_frequency = 7.0

var swarm_spawn_radius = 50.0
var swarm_orbit_step_x = 28.0
var swarm_orbit_step_y = 18.0

var phase = PHASE_PATROL

var base_orbit_radius_x = 90.0
var base_orbit_radius_y = 55.0

var swarm_slot = 0
var is_swarm_clone = false
var spawn_swarm_on_ready = true
var swarm_controller = null
var spawned_by_hive = false

var speed = 0
var attack_contact_radius = 0.0

var patrol_mod = EnemyModFlightPatrol.new()
var orbit_mod = EnemyModFlightOrbit.new()
var charge_mod = EnemyModFlightCharge.new()
var swarm_mod = EnemyModFlightSwarm.new()


func _ready():
	max_hp = GameBalance.ENEMY_HP["bee"]
	damage = GameBalance.ENEMY_DAMAGE["bee"]
	chase_speed = GameBalance.ENEMY_SPEED["bee"]
	speed = GameBalance.ENEMY_SPEED["bee"]
	attack_range = GameBalance.ENEMY_RANGE["bee"]
	cooldown = GameBalance.ENEMY_COOLDOWN["bee"]

	contact_attack_radius = 24.0
	patrol_speed = 80
	swarm_count = 3

	patrol_change_interval = 2.0

	orbit_radius_x = 90.0
	orbit_radius_y = 55.0
	orbit_angular_speed = 6.0
	orbit_duration = 1.2

	osc_radial_amplitude = 6.0
	osc_radial_frequency = 10.0
	osc_angle_amplitude = 0.12
	osc_angle_frequency = 7.0

	swarm_spawn_radius = 50.0
	swarm_orbit_step_x = 28.0
	swarm_orbit_step_y = 18.0

	base_orbit_radius_x = orbit_radius_x
	base_orbit_radius_y = orbit_radius_y

	attack_contact_radius = contact_attack_radius

	if is_swarm_clone:
		drop_loot_enabled = false

	if spawned_by_hive:
		drop_loot_enabled = false

	super._ready()

	patrol_mod.setup(self)
	orbit_mod.setup(self)
	charge_mod.setup(self)
	swarm_mod.setup(self)

	if is_swarm_clone:
		if swarm_controller == null:
			swarm_controller = swarm_mod
	else:
		swarm_controller = swarm_mod

	patrol_mod.start()

	if not is_swarm_clone and spawn_swarm_on_ready:
		call_deferred("_build_swarm_deferred")


func _build_swarm_deferred():
	if not is_dead:
		swarm_mod.build_swarm()


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


func update_phase(delta):
	var distance = get_target_distance()

	if distance > attack_range:
		update_patrol_state()
		return

	if phase == PHASE_PATROL:
		start_orbit_state()

	if phase == PHASE_ORBIT:
		update_orbit_state(delta)
		return

	if phase == PHASE_CHARGE:
		update_charge_state()


func update_patrol_state():
	if phase != PHASE_PATROL:
		phase = PHASE_PATROL
		patrol_mod.start()

	if not is_attacking:
		patrol_mod.update()


func start_orbit_state():
	phase = PHASE_ORBIT
	apply_swarm_orbit_values()
	orbit_mod.start()


func update_orbit_state(delta):
	if is_attacking:
		return

	apply_swarm_orbit_values()
	orbit_mod.update(delta)

	if orbit_mod.is_finished():
		if can_swarm_attack_now():
			phase = PHASE_CHARGE
		else:
			orbit_mod.start()


func update_charge_state():
	if is_attacking:
		return

	charge_mod.update()


func check_attack_hit():
	if phase != PHASE_CHARGE:
		return

	if is_attacking:
		return

	if not can_swarm_attack_now():
		return

	if charge_mod.can_hit():
		perform_attack()


func perform_attack():
	is_attacking = true
	stop_flight()

	if anim != null and anim.current_animation != "attack":
		anim.play("attack")

	do_attack_damage()

	await get_tree().create_timer(cooldown).timeout

	is_attacking = false
	notify_swarm_attack_finished()

	if not is_dead:
		phase = PHASE_ORBIT
		orbit_mod.start()


func can_swarm_attack_now():
	if swarm_controller == null:
		return true

	return swarm_controller.can_member_attack(self)


func notify_swarm_attack_finished():
	if swarm_controller != null:
		swarm_controller.notify_member_attack_finished(self)


func apply_swarm_orbit_values():
	var step_x = swarm_orbit_step_x
	var step_y = swarm_orbit_step_y
	var slot = swarm_slot

	if step_x == null:
		step_x = 28.0

	if step_y == null:
		step_y = 18.0

	if slot == null:
		slot = 0

	orbit_radius_x = base_orbit_radius_x + (float(slot) * step_x)
	orbit_radius_y = base_orbit_radius_y + (float(slot) * step_y)


func on_hit(amount):
	if is_dead:
		return

	if swarm_controller != null:
		if not swarm_controller.try_take_swarm_hit():
			return

	super.on_hit(amount)


func _exit_tree():
	if swarm_controller != null:
		swarm_controller.unregister_member(self)


func _on_timer_timeout():
	if phase == PHASE_PATROL:
		patrol_mod.on_timer_timeout()
