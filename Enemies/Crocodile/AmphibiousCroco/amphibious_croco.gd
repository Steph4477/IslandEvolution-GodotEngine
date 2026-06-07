extends EnemyBase

@export var speed = 200
@export var attack_range = 600
@export var stop_distance = 100
@export var cooldown = 1

const GRAVITY = 2000

@onready var rotator = $Rotator

var target = null
var target_mod = EnemyModTarget.new()
var melee_mod = EnemyModMelee.new()
var dodge_mod = EnemyModDodgeJump.new()
var jump_animation_name = "recoil"
var patrol_mod = EnemyModPatrol.new()

var is_patrolling = true
var is_patrol_paused = false
var patrol_direction = 1
var patrol_enabled = true
var patrol_pause_time = 2.0
var patrol_speed = 120.0
var patrol_change_interval = 4.0

var is_swim_croco = false
var is_hurt = false
var is_roaring = false
var has_roared = false

var base_scale_x = 0.0
var dx = 0.0
var distance = 0.0

# Reçu depuis la WaterZone
var water_current = Vector2.ZERO

# Zones d'attaque 
var in_swim_zone = false
var in_floor_zone = false


func _ready():
	setup_common_refs()

	gs = get_node("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "_on_player_changed"))

	apply_evolution_stats()

	hp = max_hp

	if hb:
		hb.set_max(max_hp)
		hb.set_value(hp)

	base_scale_x = rotator.scale.x

	target_mod.setup(self)
	melee_mod.setup(self)
	patrol_mod.setup(self)
	dodge_mod.setup(self)

	attack_timer.wait_time = cooldown
	attack_timer.stop()

	patrol_timer.wait_time = patrol_change_interval
	patrol_timer.start()

	patrol_mod.start()

	dodge_mod.hits_before_dodge = 1
	dodge_mod.dodge_speed = 600
	dodge_mod.dodge_jump_velocity = 0
	dodge_mod.dodge_duration = 0.45

# =============================================================
#                      PHYSICS PROCESS
# =============================================================
func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_swim_croco:
		velocity.y = water_current.y
	else:
		apply_gravity(delta)

	if dodge_mod.is_dodging:
		move_and_slide()
		return

	if is_swim_croco and is_patrol_paused:
		if anim.current_animation != "swim":
			anim.play("swim")

	target_mod.update()
	update_flip()
	update_logic()

	move_and_slide()


# =============================================================
#                         GRAVITÉ
# =============================================================
func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += GRAVITY * delta


# =============================================================
#                     PLAYER / FLIP
# =============================================================
func _on_player_changed(new_player):
	player = new_player

func update_flip():
	if is_patrolling:
		if patrol_direction < 0:
			rotator.scale.x = base_scale_x
		else:
			rotator.scale.x = -base_scale_x
	else:
		if dx > 0:
			rotator.scale.x = -base_scale_x
		elif dx < 0:
			rotator.scale.x = base_scale_x

# =============================================================
#             LOGIQUE PRINCIPALE 
# =============================================================
func update_patrol_zone():
	in_melee = false
	has_roared = false
	is_patrolling = true

	attack_timer.stop()
	$Sound/Roar.stop()

	if patrol_timer.is_stopped():
		patrol_timer.start()

	if is_swim_croco:
		is_patrol_paused = false

		patrol_mod.update_movement()

		if anim.current_animation != "swim":
			anim.play("swim")

		return

	patrol_mod.update_movement()

	if abs(velocity.x) > 0:
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		if anim.current_animation != "idle":
			anim.play("idle")

func update_logic():
	if is_dead:
		velocity.x = 0
		return

	if is_attacking or is_hurt or is_roaring:
		velocity.x = 0
		return

	if target == null:
		update_patrol_zone()
		return

	var horiz_distance = distance

	is_patrolling = false

	if not is_swim_croco:
		if not $Sound/Roar.playing:
			$Sound/Roar.play()
	else:
		$Sound/Roar.stop()

	if not is_swim_croco and not has_roared:
		velocity.x = 0

		if not is_roaring:
			roar()

		return

	if horiz_distance > stop_distance:
		in_melee = false
		attack_timer.stop()

		var dir = sign(dx)

		if is_swim_croco:
			velocity.x = dir * speed + water_current.x

			if anim.current_animation != "swim":
				anim.play("swim")
		else:
			velocity.x = dir * speed

			if anim.current_animation != "walk":
				anim.play("walk")

		return

	velocity.x = 0
	in_melee = false

	if is_swim_croco and in_swim_zone:
		in_melee = true

		if attack_timer.is_stopped():
			attack()
	elif not is_swim_croco and in_floor_zone:
		in_melee = true

		if attack_timer.is_stopped():
			attack()
	else:
		attack_timer.stop()


func attack():
	if is_attacking or is_hurt or is_roaring:
		return

	if target == null:
		return

	if distance > stop_distance:
		return

	if is_swim_croco:
		if not in_swim_zone:
			return

		attack_timer.start()
		attack_swim()
		return

	if not in_floor_zone:
		return

	attack_timer.start()
	attack_on_floor()

# =============================================================
#                         ROAR (SOL UNIQUEMENT)
# =============================================================
func roar():
	if is_dead:
		return
	if is_roaring:
		return
	if is_swim_croco:
		return

	is_roaring = true
	is_attacking = false
	is_hurt = false
	velocity.x = 0

	if not $Sound/Roar.playing:
		$Sound/Roar.play()

	if anim.has_animation("roar"):
		anim.play("roar")
		await anim.animation_finished

	is_roaring = false
	has_roared = true

# =============================================================
#                         ATTAQUES
# =============================================================
func attack_on_floor():
	if is_dead:
		return
	if is_attacking or is_hurt or is_roaring:
		return
	if not is_on_floor():
		return
	if is_swim_croco:
		return

	is_attacking = true
	velocity.x = 0

	if anim.has_animation("floor_attack"):
		anim.play("floor_attack")

		var impact_timer = get_tree().create_timer(0.2)
		await impact_timer.timeout

		if is_instance_valid(player) and not is_dead:
			player.damage_mod.on_hit(damage)

		await anim.animation_finished

		dx = -sign(dx)

		await dodge_mod.start_dodge()

	is_attacking = false


func attack_swim():
	if is_dead:
		return
	if is_attacking or is_hurt or is_roaring:
		return
	if not is_swim_croco:
		return

	is_attacking = true
	velocity = water_current

	if anim.has_animation("swim_attack"):
		anim.play("swim_attack")

		if is_instance_valid(player) and not is_dead:
			player.damage_mod.on_hit(damage)

		await anim.animation_finished

	is_attacking = false


# =============================================================
#                 DOMMAGES / MORT
# =============================================================
func on_hit(damage_taken):
	if is_dead:
		return

	is_attacking = false
	is_roaring = false
	velocity.x = 0

	var play_onhit = false

	hp -= damage_taken
	if hp < 0:
		hp = 0

	if hb:
		hb.set_value(hp)

	_show_damage_popup(damage_taken)

	if hp <= 0:
		die()
		return

	dodge_mod.register_hit()

	if is_swim_croco:
		is_hurt = false
	else:
		is_hurt = true
		if anim.has_animation("onhit"):
			anim.play("onhit")
			play_onhit = true

	if play_onhit:
		await anim.animation_finished

	is_hurt = false

func _show_damage_popup(amount):
	var scene = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn")
	var popup = scene.instantiate()
	$HealthBar.add_child(popup)
	$HealthBar.move_child(popup, 0)
	popup.position = Vector2(0, -30)
	popup.scale.x = 1
	popup.show_damage(amount)


func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_hurt = false
	is_roaring = false
	velocity = Vector2.ZERO
	$Sound/Roar.stop()

	if is_swim_croco:
		queue_free()
		return

	if anim.has_animation("die"):
		anim.play("die")
		await anim.animation_finished

	queue_free()


# =======================================================
# =                           ZONES                     =
# ======================================================= 
func _on_swim_area_body_entered(body):
	if not (body.is_in_group("Player") or body.name == "Player"):
		return
	in_swim_zone = true


func _on_swim_area_body_exited(body):
	if not (body.is_in_group("Player") or body.name == "Player"):
		return
	in_swim_zone = false


func _on_floor_area_body_entered(body):
	if not (body.is_in_group("Player") or body.name == "Player"):
		return
	in_floor_zone = true


func _on_floor_area_body_exited(body):
	if not (body.is_in_group("Player") or body.name == "Player"):
		return
	in_floor_zone = false

func _on_attack_timer_timeout():
	melee_mod.on_timer_timeout()

func _on_patrol_timer_timeout():
	patrol_mod.on_timer_timeout()
