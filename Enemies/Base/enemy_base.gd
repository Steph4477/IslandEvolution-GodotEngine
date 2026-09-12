extends CharacterBody2D
class_name EnemyBase

@export var max_hp = 100
@export var damage = 10
@export var hit_lock_time = 0.20
@export var attack_anim_name = "attack"
@export var count_in_score = true
@export var enemy_id = ""
@export var melee_attack_cooldown = 1.0
@export var drop_loot_enabled = false
@export_file("*.tscn") var loot_scene_path = ""

var gs = null
var player = null

var hp = 0
var is_dead = false
var is_attacking = false
var is_shooting = false
var hit_locked = false
var knockback_active = false
var in_melee = false
var can_melee_attack = true

var hb = null
var health_bar = null
var anim = null
var spawn_point = null
var attack_timer = null
var projectile_timer = null
var projectile_damage = 0
var patrol_timer = null

func _ready():
	gs = get_node("/root/GameState")

	if enemy_id == "":
		enemy_id = name

	if gs.has_pending_load and gs.killed_enemy_ids.has(enemy_id):
		queue_free()
		return

	setup_common_refs()

	player = gs.player

	apply_evolution_stats()

	hp = max_hp

	if hb:
		hb.set_max(max_hp)
		hb.set_value(hp)


func apply_evolution_stats():
	var multiplier = gs.score_system.get_enemy_evolution_multiplier(gs.enemy_evolution_percent)

	max_hp = int(round(max_hp * multiplier))
	damage = int(round(damage * multiplier))

	if projectile_damage > 0:
		projectile_damage = int(round(projectile_damage * multiplier))

	print("ENEMY EVOLUTION - ", name, " +", gs.enemy_evolution_percent, "%")
	print("ENEMY HP : ", max_hp)
	print("ENEMY DAMAGE : ", damage)

	if projectile_damage > 0:
		print("ENEMY PROJECTILE DAMAGE : ", projectile_damage)


func setup_common_refs():
	if has_node("HealthBar"):
		hb = $HealthBar

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
	
	if has_node("PatrolTimer"):
		patrol_timer = $PatrolTimer


func refresh_player():
	if gs == null:
		gs = get_node("/root/GameState")

	player = gs.player


##########################################################################
#                             ATTAQUE                                    #
########################################################################## 
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

	if not can_melee_attack:
		return false

	return true


func on_hit(amount):
	if is_dead:
		return

	if hit_locked:
		return

	hp -= amount
	hp = max(hp, 0)

	if gs:
		gs.update_boss_fight_hud()

	if hb:
		hb.set_value(hp)

	_show_damage_popup(amount)

	if hp <= 0:
		die()
		return

	hit_locked = true

	if anim and anim.has_animation("onhit"):
		anim.play("onhit")

	await get_tree().create_timer(hit_lock_time).timeout
	hit_locked = false

func apply_knockback(direction: float, force: float):
	knockback_active = true
	velocity.x = direction * force

	await get_tree().create_timer(hit_lock_time).timeout

	knockback_active = false

func start_hit_lock():
	hit_locked = true
	await get_tree().create_timer(hit_lock_time).timeout
	hit_locked = false

func do_attack_damage():
	player.damage_mod.on_hit(damage)

func attack():
	if not can_attack_player():
		return

	is_attacking = true
	can_melee_attack = false
	velocity.x = 0

	if anim.current_animation != attack_anim_name:
		anim.play(attack_anim_name)

	do_attack_damage()

	await get_tree().create_timer(anim.get_animation(attack_anim_name).length).timeout

	is_attacking = false

	await get_tree().create_timer(melee_attack_cooldown).timeout

	can_melee_attack = true


# --- Popup dégâts ---
func _show_damage_popup(amount):
	if health_bar == null:
		return

	var hb_parent = health_bar.get_parent()
	if hb_parent == null:
		return

	var popup = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn").instantiate()
	hb_parent.add_child(popup)

	popup.position = Vector2(0, -20)
	popup.show_damage(amount)


##########################################################################
#                             DIE                                        #
########################################################################## 

func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_shooting = false
	hit_locked = false
	in_melee = false
	can_melee_attack = false
	velocity = Vector2.ZERO

	if attack_timer:
		attack_timer.stop()

	if projectile_timer:
		projectile_timer.stop()

	if anim and anim.has_animation("die"):
		anim.play("die")
		await anim.animation_finished

	# --- Comptage d'ennemis tués pour le score --- 
	if count_in_score:
		gs.score_system.add_enemy_kill()

	if count_in_score and enemy_id != "":
		gs.add_enemy_killed(enemy_id)

	spawn_loot()

	queue_free()


func spawn_loot():
	if not drop_loot_enabled:
		return

	if loot_scene_path == "":
		return

	var scene = load(loot_scene_path)

	if scene == null:
		return

	var loot = scene.instantiate()
	get_tree().current_scene.add_child(loot)
	loot.global_position = global_position

	loot.z_index = 100
