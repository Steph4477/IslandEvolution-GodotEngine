extends EnemyGroundBase

@export var projectile_scene = preload("res://Shoot/Enemies/Gaz/gaz.tscn")
@export var projectile_spawn_delay = 0.0
@export var projectile_attack_animation = "attack"

var fire_interval = 0.0
var min_shoot_distance = 0.0
var max_shoot_distance = 0.0
var melee_distance = 0.0

var target

var throw_mod = EnemyModThrowProjectile.new()
var target_mod = EnemyModTarget.new()

var projectile_spawn = null

func _ready():
	projectile_spawn_delay = 0.40
	fire_interval = GameBalance.ENEMY_COOLDOWN["snake"]
	min_shoot_distance = GameBalance.ENEMY_MIN_SHOOT_DISTANCE["snake"]
	max_shoot_distance = GameBalance.ENEMY_MAX_SHOOT_DISTANCE["snake"]
	melee_distance = GameBalance.ENEMY_MELEE_DISTANCE["snake"]
	projectile_damage = GameBalance.ENEMY_PROJECTILE["gaz"]

	projectile_attack_animation = "attack"

	super._ready()

	projectile_spawn = $Rotator/ProjectileSpawn

	throw_mod.setup(self)
	target_mod.setup(self)

	if projectile_timer:
		projectile_timer.wait_time = fire_interval
		projectile_timer.start()


func _physics_process(_delta):
	if is_dead:
		return

	if player == null:
		refresh_player()

	target_mod.update()

	if target != null:
		player = target

	update_flip()

	if hit_locked:
		return

	if is_attacking:
		return

	if is_shooting:
		return

	if distance >= min_shoot_distance and distance <= max_shoot_distance:
		if projectile_timer and projectile_timer.is_stopped():
			projectile_timer.start()
	else:
		if projectile_timer:
			projectile_timer.stop()

	if anim.current_animation != "idle":
		anim.play("idle")


func update_flip():
	super.flip()


func die():
	target = null

	if projectile_timer:
		projectile_timer.stop()

	super.die()


func _on_projectile_timer_timeout():
	if is_dead:
		return

	if is_attacking:
		return

	if distance < min_shoot_distance:
		return

	if distance > max_shoot_distance:
		return

	throw_mod.on_timer_timeout()
