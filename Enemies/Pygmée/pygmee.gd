extends CharacterBody2D

# ========================== RÉGLAGES ==========================
@export var lance_scene = preload("res://Tir/lance_trap.tscn")
@export var fire_interval = 3.0
@export var move_speed = 100.0
@export var melee_damage = 100
@export var cac_anim_duration = 0.6

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
func _physics_process(_dt):
	if is_dead:
		return

	# Pendant le onhit, on ne joue pas d'autres anims
	if hit_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_face_player()

	if in_cac:
		if not is_attacking:
			_start_cac_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if in_melee:
		_walk_towards_player()
		return

	if is_shooting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = Vector2.ZERO
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
	velocity = Vector2(dir_x * move_speed, 0)
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
	# pas de anim.play("idle") ici

# ========================= CORPS À CORPS ======================
func _start_cac_attack():
	is_attacking = true
	can_flip = false
	anim.play("cac")

	velocity = Vector2.ZERO
	move_and_slide()

	player.on_hit(melee_damage)

	await get_tree().create_timer(anim.get_animation("cac").length).timeout

	is_attacking = false
	can_flip = not (in_melee or in_cac)
	# pas de anim.play("idle") ici

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
