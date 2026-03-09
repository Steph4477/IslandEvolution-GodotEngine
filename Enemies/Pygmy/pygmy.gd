extends EnemyGroundBase

@export var projectile_scene = preload("res://Shoot/Enemies/Spear/spear.tscn")
@export var fire_interval = 3
@export var melee_distance = 70.0
@export var chase_distance = 260.0
@export var min_shoot_distance = 300.0
@export var max_shoot_distance = 2000.0
@export var jump_velocity = -600.0
@export var projectile_spawn_delay = 0.40
@export var projectile_attack_animation = "attack"
@export var jump_animation_name = "jump"

var loot_lance_scene = preload("res://Loot/Spear/spear.tscn")

@onready var health_bar = $HealthBar/ProgressBar
@onready var rotator = $Rotator
@onready var anim = $Rotator/AnimationPlayer
@onready var sprite = $Rotator/Sprite2D
@onready var projectile_spawn = $Rotator/ProjectileSpawn
@onready var attack_timer = $AttackTimer
@onready var projectile_timer = $ProjectileTimer
@onready var spawn_point = $SpawnPoint

var melee_mod = EnemyModMelee.new()
var throw_mod = EnemyModThrowProjectile.new()
var jump_mod = EnemyModJumpSync.new()

var is_shooting = false
var hit_locked = false
var hit_lock_time = 0.20

func _ready():
	max_hp = 200
	damage = 100
	speed = 100
	gravity = 1000
	attack_range = 99999
	stop_distance = 0

	melee_mod.setup(self)
	throw_mod.setup(self)
	jump_mod.setup(self)

	super._ready()

	base_scale_x = abs(rotator.scale.x)

	attack_timer.wait_time = 1.0
	attack_timer.stop()

	projectile_timer.wait_time = fire_interval
	projectile_timer.start()

func _physics_process(delta):
	if is_dead:
		return

	apply_gravity(delta)
	target_player()
	flip()
	jump_mod.update()
	melee_mod.update_state()

	if hit_locked:
		velocity.x = 0
		move_and_slide()
		return

	if not is_on_floor():
		if not is_shooting and not is_attacking:
			if anim.current_animation != jump_animation_name:
				anim.play(jump_animation_name)
		move_and_slide()
		return

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return

	if in_melee:
		velocity.x = 0
		move_and_slide()
		return

	if is_shooting:
		velocity.x = 0
		move_and_slide()
		return

	if distance <= chase_distance:
		chase_player()
		move_and_slide()
		return

	velocity.x = 0
	move_and_slide()

	if anim.current_animation != "idle":
		anim.play("idle")

func chase_player():
	if dx > melee_distance:
		velocity.x = speed
	elif dx < -melee_distance:
		velocity.x = -speed
	else:
		velocity.x = 0

	if velocity.x != 0:
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		if anim.current_animation != "idle":
			anim.play("idle")

func attack():
	if player.is_dead:
		in_melee = false
		return

	if is_dead:
		return

	if is_attacking:
		return

	is_attacking = true
	velocity.x = 0
	anim.play("cac")
	player.damage_mod.on_hit(damage)
	await get_tree().create_timer(anim.get_animation("cac").length).timeout
	is_attacking = false

func on_hit(amount):
	if is_dead:
		return

	if hit_locked:
		return

	pv -= amount
	health_bar.value = max(pv, 0)

	_show_damage_popup(amount)

	hit_locked = true
	anim.play("onhit")
	await get_tree().create_timer(hit_lock_time).timeout
	hit_locked = false

	if pv <= 0:
		die()

func die():
	if is_dead:
		return

	is_dead = true
	in_melee = false

	attack_timer.stop()
	projectile_timer.stop()

	velocity = Vector2.ZERO

	anim.play("die")
	await anim.animation_finished

	var loot = loot_lance_scene.instantiate()
	get_parent().add_child(loot)
	loot.global_position = spawn_point.global_position

	queue_free()

func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()

func _on_projectile_timer_timeout():
	throw_mod.on_timer_timeout()
