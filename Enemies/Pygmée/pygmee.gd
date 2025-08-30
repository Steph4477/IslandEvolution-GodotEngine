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
var anim_busy = false
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

	_face_player()

	if in_cac and player.is_dead:
		in_cac = false
		is_attacking = false
		can_flip = true
		return

	if in_cac:
		if not is_attacking:
			_start_cac_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if in_melee:
		_walk_towards_player()
		return

	if anim_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = Vector2.ZERO
	move_and_slide()
	anim.play("idle")

# ========================= ORIENTATION ========================
func _face_player():
	if is_attacking or anim_busy or not can_flip or is_dead:
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
	if is_attacking or anim_busy or is_dead:
		return

	var dir_x = sign(player.global_position.x - global_position.x)
	velocity.x = dir_x * move_speed
	velocity.y = 0
	move_and_slide()
	anim.play("walk")

# ============================ TIR =============================
func _on_lance_timer_timeout():
	if is_dead or in_melee or in_cac or is_attacking or anim_busy:
		return
	_shoot_lance()

func _shoot_lance():
	can_flip = false
	anim.play("attack")
	anim_busy = true

	await get_tree().create_timer(0.40).timeout

	var lance = lance_scene.instantiate()
	get_tree().current_scene.add_child(lance)

	lance.global_position = lance_spawn.global_position
	lance.direction = Vector2(facing, 0)

	var attack_len = anim.get_animation("attack").length
	var remaining = attack_len - 0.20
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout

	anim_busy = false
	can_flip = not (in_melee or in_cac)
	anim.play("idle")

# ========================= CORPS À CORPS ======================
func _start_cac_attack():
	if is_attacking or is_dead or player.is_dead:
		return

	is_attacking = true
	can_flip = false
	anim.play("cac")
	anim_busy = true

	velocity = Vector2.ZERO
	move_and_slide()

	if not player.is_dead and player.has_method("on_hit"):
		player.on_hit(melee_damage)

	var wait_s = anim.get_animation("cac").length
	await get_tree().create_timer(wait_s).timeout

	is_attacking = false
	anim_busy = false
	can_flip = not (in_melee or in_cac)
	anim.play("idle")

# ============================ ZONES ===========================
func _on_melee_zone_body_entered(body):
	in_melee = true
	can_flip = false

func _on_melee_zone_body_exited(body):
	in_melee = false
	if not in_cac:
		can_flip = true

func _on_cac_zone_body_entered(body):
	if player.is_dead:
		return
	in_cac = true
	can_flip = false
	if not is_attacking:
		_start_cac_attack()

func _on_cac_zone_body_exited(body):
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
	else:
		hit_locked = true
		anim_busy = true
		can_flip = false
		anim.play("onhit")
		await anim.animation_finished
		anim_busy = false
		can_flip = true
		await get_tree().create_timer(hit_lock_time).timeout
		hit_locked = false

func _die():
	if is_dead:
		return
	is_dead = true

	anim_busy = true

	anim.play("die")
	await anim.animation_finished
	queue_free()
