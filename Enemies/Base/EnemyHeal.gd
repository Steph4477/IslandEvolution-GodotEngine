extends EnemyGroundBase
class_name EnemyHeal

@export var balance_id = "cannibal_heal"

var melee_distance = 0
var fire_interval = 3.0
var projectile_spawn_delay = 0.40
var projectile_scene = null
var projectile_spawn = null

var projectile_attack_animation = "attack"
var jump_animation_name = "jump"
var heal_animation_name = "attack"
var animation_walk = "walk"

var jump_velocity = -600.0
var target = null
var can_jump = true

var heal_range = 400.0
var heal_amount = 40
var safe_distance = 350
var follow_distance = 500

var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var jump_mod = EnemyModJumpSync.new()
var heal_mod = EnemyModHealProjectile.new()


func _ready():
	max_hp = GameBalance.ENEMY_HP[balance_id]
	damage = GameBalance.ENEMY_DAMAGE[balance_id]
	speed = GameBalance.ENEMY_SPEED[balance_id]
	attack_range = GameBalance.ENEMY_RANGE[balance_id]
	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE[balance_id]
	fire_interval = GameBalance.ENEMY_FIRE_INTERVAL[balance_id]
	projectile_scene = load(GameBalance.ENEMY_PROJECTILE_SCENE[balance_id])
	projectile_attack_animation = GameBalance.ENEMY_ANIMATION_SHOOT[balance_id]
	heal_animation_name = GameBalance.ENEMY_ANIMATION_SHOOT[balance_id]
	animation_walk = GameBalance.ENEMY_ANIMATION_WALK[balance_id]
	can_jump = GameBalance.ENEMY_CAN_JUMP[balance_id]

	attack_anim_name = GameBalance.ENEMY_ANIMATION_ATTACK[balance_id]

	super._ready()

	hp = max_hp

	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

	projectile_spawn = $Rotator/ProjectileSpawn
	patrol_timer = $PatrolTimer

	target_mod.setup(self)
	melee_mod.setup(self)

	if can_jump:
		jump_mod.setup(self)

	patrol_mod.setup(self)
	heal_mod.setup(self)

	if projectile_timer:
		projectile_timer.wait_time = fire_interval
		projectile_timer.start()

	if attack_timer:
		attack_timer.wait_time = GameBalance.ENEMY_COOLDOWN[balance_id]
		attack_timer.stop()

	if patrol_timer:
		patrol_timer.wait_time = patrol_change_interval
		patrol_timer.start()

	patrol_mod.start()


func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)

	if knockback_active:
		move_and_slide()
		return

	target_mod.update()

	flip()

	if can_jump:
		jump_mod.update()

	melee_mod.update_state()

	if hit_locked:
		stop_and_slide()
		return

	if not is_on_floor():
		if can_jump and not is_shooting and not is_attacking:
			if anim.current_animation != jump_animation_name:
				anim.play(jump_animation_name)

		move_and_slide()
		return

	if try_priority_heal():
		return

	if move_to_wounded_ally():
		return

	if target == null:
		update_patrol_zone()
		return

	if is_attacking:
		velocity.x = 0
		stop_and_slide()
		return

	if is_shooting:
		velocity.x = 0
		stop_and_slide()
		return

	if in_melee:
		velocity.x = 0
		stop_and_slide()
		return

	if distance < melee_distance:
		velocity.x = 0
		stop_and_slide()
		return

	if distance < safe_distance:
		if dx > 0:
			velocity.x = -speed
		else:
			velocity.x = speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

		move_and_slide()
		return

	if distance > follow_distance:
		if dx > 0:
			velocity.x = speed
		else:
			velocity.x = -speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

		move_and_slide()
		return

	velocity.x = 0
	play_idle()
	move_and_slide()


func update_patrol_zone():
	is_patrolling = true

	if patrol_timer and patrol_timer.is_stopped():
		patrol_timer.start()

	patrol_mod.update_movement()

	if patrol_direction < 0:
		$Rotator.scale.x = -base_scale_x
	else:
		$Rotator.scale.x = base_scale_x

	move_and_slide()

	if abs(velocity.x) > 0:
		if anim.current_animation != animation_walk:
			anim.play(animation_walk)
	else:
		play_idle()


func try_priority_heal():
	if is_shooting:
		return true

	if heal_mod.can_heal():
		velocity.x = 0
		stop_and_slide()
		heal_mod.throw_heal_projectile()
		return true

	return false


func move_to_wounded_ally():
	var ally = heal_mod.find_any_wounded_ally()

	if ally == null:
		return false

	var dist = global_position.distance_to(ally.global_position)

	if dist <= heal_range:
		return false

	var dir = ally.global_position.x - global_position.x

	if dir > 0:
		velocity.x = speed
	else:
		velocity.x = -speed

	if anim.current_animation != animation_walk:
		anim.play(animation_walk)

	move_and_slide()
	return true


func die():
	in_melee = false
	super.die()


func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()


func _on_projectile_timer_timeout():
	heal_mod.on_timer_timeout()


func _on_patrol_timer_timeout():
	patrol_mod.on_timer_timeout()
