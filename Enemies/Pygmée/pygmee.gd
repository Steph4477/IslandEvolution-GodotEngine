extends CharacterBody2D

# ========================== RÉGLAGES ==========================
@export var lance_scene = preload("res://Tir/lance_trap.tscn")
@export var fire_interval = 2.0
@export var move_speed = 100.0
@export var melee_damage = 100
@export var gravity = 1200.0
@export var jump_velocity = -600.0

# ============================ NODES ===========================
@onready var rig = $Rig
@onready var anim = $Rig/AnimationPlayer
@onready var lance_spawn = $Rig/Lance
@onready var melee_zone = $Rig/MeleeZone
@onready var cac_zone = $Rig/CacZone
@onready var lance_timer = $LanceTimer

# ============================= ÉTAT ===========================
var player = null
var in_melee = false
var in_cac = false
var is_attacking = false
var is_shooting = false
var can_flip = true
var facing = 1
var base_scale_x = 1.0

var max_pv = 200
var pv = 200
var hit_locked = false
var hit_lock_time = 0.20
var is_dead = false

# suivi pour détecter le début de saut de Moko
var player_prev_on_floor = true

# ============================ READY ===========================
func _ready():
	base_scale_x = abs(rig.scale.x)
	var gs = get_node("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "_on_player_changed"))
	lance_timer.wait_time = fire_interval
	lance_timer.start()

func _on_player_changed(p):
	player = p

# ======================= BOUCLE PHYSIQUE ======================
func _physics_process(delta):
	if is_dead:
		return

	# Gravité 
	if not is_on_floor():
		velocity.y += gravity * delta

	# Saut synchronisé : si Moko démarre un saut, le pyg saute aussi 
	var p_on_floor = player.is_on_floor()
	var player_started_jump = player_prev_on_floor and not p_on_floor and player.velocity.y < 0
	player_prev_on_floor = p_on_floor
	if player_started_jump and is_on_floor():
		velocity.y = jump_velocity
		if not is_shooting and not is_attacking:
			anim.play("jump")

	# Pendant le onhit : fige et n'écrase pas l'anim
	if hit_locked:
		velocity.x = 0
		move_and_slide()
		return

	# En l'air : garder l'anim "jump" (sauf si on tire ou cac)
	if not is_on_floor():
		if not is_shooting and not is_attacking:
			if anim.current_animation != "jump":
				anim.play("jump")
		move_and_slide()
		return

	_face_player()

	if in_cac:
		if not is_attacking:
			_start_cac_attack()
		velocity.x = 0
		move_and_slide()
		return

	if in_melee:
		_walk_towards_player()
		return

	if is_shooting:
		velocity.x = 0
		move_and_slide()
		return

	velocity.x = 0
	move_and_slide()
	anim.play("idle")

# ========================= ORIENTATION ========================
func _face_player():
	if not can_flip or is_attacking or is_dead:
		return
	var dx = player.global_position.x - global_position.x
	if dx < 0 and facing != -1:
		facing = -1
		rig.scale.x = -base_scale_x
	elif dx > 0 and facing != 1:
		facing = 1
		rig.scale.x = base_scale_x

# ========================= DÉPLACEMENT ========================
func _walk_towards_player():
	if is_attacking or is_dead:
		return
	var dir_x = sign(player.global_position.x - global_position.x)
	velocity.x = dir_x * move_speed  
	move_and_slide()
	anim.play("walk")

# ============================ TIR =============================
func _on_lance_timer_timeout():
	if is_dead or in_melee or in_cac or is_attacking or is_shooting or hit_locked:
		return
	_shoot_lance()

func _shoot_lance():
	is_shooting = true
	can_flip = false
	anim.play("attack")

	await get_tree().create_timer(0.40).timeout

	var lance = lance_scene.instantiate()
	get_tree().current_scene.add_child(lance)
	lance.global_position = lance_spawn.global_position
	lance.direction = Vector2(facing, 0)

	var remaining = anim.get_animation("attack").length - 0.20
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout

	is_shooting = false
	can_flip = not (in_melee or in_cac)

# ========================= CORPS À CORPS ======================
func _start_cac_attack():
	is_attacking = true
	can_flip = false
	anim.play("cac")

	velocity.x = 0
	move_and_slide()

	player.on_hit(melee_damage)

	await get_tree().create_timer(anim.get_animation("cac").length).timeout

	is_attacking = false
	can_flip = not (in_melee or in_cac)

# ============================ ZONES ===========================
func _on_melee_zone_body_entered(_body):
	in_melee = true
	can_flip = false

func _on_melee_zone_body_exited(_body):
	in_melee = false
	if not in_cac:
		can_flip = true

func _on_cac_zone_body_entered(_body):
	if in_cac:
		return
	in_cac = true
	can_flip = false
	if not is_attacking:
		_start_cac_attack()

func _on_cac_zone_body_exited(_body):
	in_cac = false
	if not in_melee:
		can_flip = true

# ========================= VIE / DÉGÂTS =======================
func on_hit(amount):
	if is_dead or hit_locked:
		return

	pv -= amount
	if pv <= 0:
		_die()
		return

	hit_locked = true
	anim.play("onhit")
	await get_tree().create_timer(hit_lock_time).timeout
	hit_locked = false

func _die():
	if is_dead:
		return
	is_dead = true
	anim.play("die")
	await anim.animation_finished
	queue_free()
