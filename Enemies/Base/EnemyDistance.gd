extends EnemyGroundBase
class_name EnemyDistance

@export var balance_id = "snake_distance"

var min_shoot_distance = 0
var max_shoot_distance = 0
var fire_interval = 1.0
var projectile_spawn_delay = 0.4
var projectile_scene = null
var projectile_spawn = null
var projectile_attack_animation = "attack"
var animation_walk = "walk"
var target = null
var melee_distance = 0
var attack_cooldown = 1.0

var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()


func _ready():
	super._ready()

	max_hp = GameBalance.ENEMY_HP[balance_id]
	hp = max_hp
	damage = GameBalance.ENEMY_DAMAGE[balance_id]
	projectile_damage = GameBalance.ENEMY_PROJECTILE_DAMAGE[balance_id]
	speed = GameBalance.ENEMY_SPEED[balance_id]
	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE[balance_id]
	attack_cooldown = GameBalance.ENEMY_COOLDOWN[balance_id]
	attack_anim_name = GameBalance.ENEMY_ANIMATION_ATTACK[balance_id]

	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

	if attack_timer:
		attack_timer.wait_time = attack_cooldown
		attack_timer.stop()

	melee_mod.setup(self)

	min_shoot_distance = GameBalance.ENEMY_MIN_SHOOT_DISTANCE[balance_id]
	max_shoot_distance = GameBalance.ENEMY_MAX_SHOOT_DISTANCE[balance_id]
	fire_interval = GameBalance.ENEMY_FIRE_INTERVAL[balance_id]
	projectile_scene = load(GameBalance.ENEMY_PROJECTILE_SCENE[balance_id])
	projectile_attack_animation = GameBalance.ENEMY_ANIMATION_SHOOT[balance_id]
	animation_walk = GameBalance.ENEMY_ANIMATION_WALK[balance_id]

	attack_range = max_shoot_distance

	projectile_spawn = $Rotator/ProjectileSpawn

	if projectile_timer:
		projectile_timer.wait_time = fire_interval
		projectile_timer.start()

	throw_mod.setup(self)


func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)

	if knockback_active:
		move_and_slide()
		return

	target_player()
	target = player
	flip()

	melee_mod.update_state()

	if in_melee:
		velocity.x = 0
		move_and_slide()
		return

	if is_shooting:
		velocity.x = 0
	elif distance < min_shoot_distance:
		move_away_from_target()
	elif distance <= max_shoot_distance:
		velocity.x = 0
		play_idle()
	else:
		move_to_target()

	move_and_slide()


func move_to_target():
	if dx > stop_distance:
		velocity.x = speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	elif dx < -stop_distance:
		velocity.x = -speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	else:
		velocity.x = 0
		play_idle()


func move_away_from_target():
	if dx > 0:
		velocity.x = -speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	elif dx < 0:
		velocity.x = speed

		if anim.current_animation != animation_walk:
			anim.play(animation_walk)

	else:
		velocity.x = 0
		play_idle()


func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()


func _on_projectile_timer_timeout():
	throw_mod.on_timer_timeout()
