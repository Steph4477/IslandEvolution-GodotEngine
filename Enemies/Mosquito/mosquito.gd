extends EnemyFlightBase

var chase_speed = 0
var attack_range = 0
@export var contact_attack_radius = 24.0
var cooldown = 0.8
@export var patrol_speed = 80
@export var patrol_change_interval = 2.0

@export var orbit_radius_x = 90.0
@export var orbit_radius_y = 55.0
@export var orbit_angular_speed = 6.0
@export var orbit_duration = 1.2

@export var osc_radial_amplitude = 6.0
@export var osc_radial_frequency = 10.0
@export var osc_angle_amplitude = 0.12
@export var osc_angle_frequency = 7.0

const PHASE_PATROL = 0
const PHASE_ORBIT = 1
const PHASE_CHARGE = 2

var phase = PHASE_PATROL

var speed = 0.0
var attack_contact_radius = 0.0

var patrol_mod = EnemyModFlightPatrol.new()
var orbit_mod = EnemyModFlightOrbit.new()
var charge_mod = EnemyModFlightCharge.new()

func _ready():
	max_hp = GameBalance.ENEMY_HP["mosquito"]
	damage = GameBalance.ENEMY_DAMAGE["mosquito"]

	chase_speed = GameBalance.ENEMY_SPEED["mosquito"]
	speed = GameBalance.ENEMY_SPEED["mosquito"]

	attack_range = GameBalance.ENEMY_RANGE["mosquito"]
	cooldown = GameBalance.ENEMY_COOLDOWN["mosquito"]

	attack_anim_name = "attack"
	attack_contact_radius = contact_attack_radius

	super._ready()

	patrol_mod.setup(self)
	orbit_mod.setup(self)
	charge_mod.setup(self)
	patrol_mod.start()

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
	if player.has_node("TurnAxis"):
		return player.get_node("TurnAxis").global_position
	return player.global_position

func update_phase(delta):
	var distance = get_target_distance()

	if distance > attack_range:
		update_patrol_state()
		return

	if phase == PHASE_PATROL:
		phase = PHASE_ORBIT
		orbit_mod.start()

	if phase == PHASE_ORBIT:
		if not is_attacking:
			orbit_mod.update(delta)
			if orbit_mod.is_finished():
				phase = PHASE_CHARGE
		return

	if phase == PHASE_CHARGE:
		if not is_attacking:
			charge_mod.update()

func update_patrol_state():
	if phase != PHASE_PATROL:
		phase = PHASE_PATROL
		patrol_mod.start()

	if not is_attacking:
		patrol_mod.update()

func check_attack_hit():
	if phase != PHASE_CHARGE:
		return

	if is_attacking:
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

	if not is_dead:
		phase = PHASE_ORBIT
		orbit_mod.start()

func on_hit(amount):
	if is_dead:
		return
	super.on_hit(amount)

func die():
	if is_dead:
		return
	super.die()

func _on_timer_timeout():
	if phase == PHASE_PATROL:
		patrol_mod.on_timer_timeout()
