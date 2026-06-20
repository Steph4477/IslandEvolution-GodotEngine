extends EnemyGroundBase

@export var projectile_scene = preload("res://Shoot/Enemies/Bone/bone.tscn")
@export var projectile_spawn_delay = 0.40
@onready var smoke_charge_scene = preload("res://Enemies/Cannibal/Effects/dust_charge.tscn")

var melee_distance = 0
var min_shoot_distance = 0
var max_shoot_distance = 0

var projectile_attack_animation = "attack"
var jump_animation_name = "jump"
var charge_animation_name = "walk"

var fire_interval = 0.0
var jump_velocity = -600.0
var target = null

var is_charging = false
var was_charging = false
var charge_dir = 1
var charge_time = 0.0
var charge_duration = 0.70
var charge_speed = 850.0
var charge_cooldown = 3.0
var charge_cooldown_left = 1.0
var charge_min_range = 180.0
var charge_max_range = 700.0
var horiz_distance = 999999

var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()
var jump_mod = EnemyModJumpSync.new()
var charge_mod = EnemyModWildCharge.new()

var projectile_spawn = null
var smoke_spawn = null


func _ready():
	max_hp = GameBalance.ENEMY_HP["cannibal"]
	damage = GameBalance.ENEMY_DAMAGE["cannibal"]
	projectile_damage = GameBalance.ENEMY_PROJECTILE["bone"]
	speed = GameBalance.ENEMY_SPEED["cannibal"]
	attack_range = GameBalance.ENEMY_RANGE["cannibal"]
	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE["cannibal"]
	min_shoot_distance = GameBalance.ENEMY_MIN_SHOOT_DISTANCE["cannibal"]
	max_shoot_distance = GameBalance.ENEMY_MAX_SHOOT_DISTANCE["cannibal"]
	fire_interval = GameBalance.ENEMY_COOLDOWN["cannibal"]
	
	attack_anim_name = "cac"

	super._ready()

	projectile_spawn = $Rotator/ProjectileSpawn
	patrol_timer = $PatrolTimer
	smoke_spawn = $Rotator/SmokeSpawn

	target_mod.setup(self)
	melee_mod.setup(self)
	throw_mod.setup(self)
	jump_mod.setup(self)
	charge_mod.setup(self)
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
	target_mod.update()
	update_charge_distance()

	was_charging = is_charging

	if is_charging:
		charge_mod.update(delta)
		move_and_slide()
		return

	flip()
	jump_mod.update()
	melee_mod.update_state()
	charge_mod.update(delta)

	if not was_charging and is_charging:
		spawn_charge_smoke()

	if hit_locked:
		stop_and_slide()
		return

	if not is_on_floor():
		if not is_shooting and not is_attacking:
			if anim.current_animation != jump_animation_name:
				anim.play(jump_animation_name)

		move_and_slide()
		return

	if target == null:
		update_patrol_zone()
		return

	if is_attacking:
		velocity.x = 0
		stop_and_slide()
		return

	if in_melee:
		velocity.x = 0
		stop_and_slide()
		return

	if is_shooting:
		velocity.x = 0
		stop_and_slide()
		return

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

	move_and_slide()


func spawn_charge_smoke():
	var smoke = smoke_charge_scene.instantiate()
	get_parent().add_child(smoke)
	smoke.global_position = smoke_spawn.global_position
	smoke.scale.x = $Rotator.scale.x

	var smoke_anim = smoke.get_node("AnimationPlayer")
	smoke_anim.play("fade")


func update_charge_distance():
	if target == null:
		horiz_distance = 999999
		return

	horiz_distance = abs(target.global_position.x - global_position.x)


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
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		play_idle()


func die():
	in_melee = false
	charge_mod.cancel_charge()
	super.die()


func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()


func _on_projectile_timer_timeout():
	throw_mod.on_timer_timeout()


func _on_patrol_timer_timeout():
	patrol_mod.on_timer_timeout()
