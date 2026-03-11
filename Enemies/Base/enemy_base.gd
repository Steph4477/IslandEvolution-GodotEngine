extends CharacterBody2D
class_name EnemyBase

@export var max_hp = 100
@export var damage = 10
@export var hit_lock_time = 0.20
@export var attack_anim_name = "attack"

var gs = null
var player = null

var hp = 0
var is_dead = false
var is_attacking = false
var is_shooting = false
var hit_locked = false
var in_melee = false

var health_bar = null
var anim = null
var spawn_point = null
var attack_timer = null
var projectile_timer = null
var loot_scene = null

func _ready():
	setup_common_refs()

	gs = get_node("/root/GameState")
	player = gs.player
	hp = max_hp

	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

func setup_common_refs():
	if has_node("HealthBar/ProgressBar"):
		health_bar = $HealthBar/ProgressBar

	if has_node("Rotator/AnimationPlayer"):
		anim = $Rotator/AnimationPlayer

	if has_node("SpawnPoint"):
		spawn_point = $SpawnPoint

	if has_node("AttackTimer"):
		attack_timer = $AttackTimer
	elif has_node("Timer"):
		attack_timer = $Timer

	if has_node("ProjectileTimer"):
		projectile_timer = $ProjectileTimer
	elif has_node("Rotator/ProjectileTimer"):
		projectile_timer = $Rotator/ProjectileTimer

func refresh_player():
	if gs == null:
		gs = get_node("/root/GameState")

	player = gs.player

func on_hit(amount):
	if is_dead:
		return

	if hit_locked:
		return

	hp -= amount

	if health_bar:
		health_bar.value = max(hp, 0)

	_show_damage_popup(amount)

	if hp <= 0:
		die()
		return

	hit_locked = true

	if anim:
		anim.play("onhit")

	await get_tree().create_timer(hit_lock_time).timeout
	hit_locked = false

func can_attack_player():
	if player == null:
		refresh_player()
		if player == null:
			return false

	if player.is_dead:
		in_melee = false
		return false

	if is_dead:
		return false

	if is_attacking:
		return false

	return true

func do_attack_damage():
	player.damage_mod.on_hit(damage)

func attack():
	if not can_attack_player():
		return

	is_attacking = true
	velocity.x = 0

	if anim:
		if anim.current_animation != attack_anim_name:
			anim.play(attack_anim_name)

	do_attack_damage()

	if anim:
		await get_tree().create_timer(anim.get_animation(attack_anim_name).length).timeout

	is_attacking = false

func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_shooting = false
	hit_locked = false
	in_melee = false
	velocity = Vector2.ZERO

	if attack_timer:
		attack_timer.stop()

	if projectile_timer:
		projectile_timer.stop()

	if anim:
		anim.play("die")
		await anim.animation_finished

	if loot_scene:
		var loot = loot_scene.instantiate()
		get_parent().add_child(loot)

		if spawn_point:
			loot.global_position = spawn_point.global_position
		else:
			loot.global_position = global_position

	queue_free()

func _show_damage_popup(amount):
	pass
