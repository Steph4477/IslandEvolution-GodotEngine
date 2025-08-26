extends CharacterBody2D

# =========================
#   PARAMS (Inspector)
# =========================
@export var lance_scene = preload("res://Tir/lance_trap.tscn")
@export var fire_interval = 3.0
@export var move_speed = 100.0
@export var melee_damage = 100
@export var cac_anim_duration = 0.6

# =========================
#   NODES
# =========================
@onready var rig = $Rig
@onready var anim = $Rig/AnimationPlayer
@onready var lance_spawn = $Rig/Lance
@onready var melee_zone = $Rig/MeleeZone
@onready var cac_zone = $Rig/CacZone
@onready var lance_timer = $LanceTimer

# =========================
#   STATE
# =========================
var player = null
var in_melee = false
var in_cac = false
var is_attacking = false
var anim_busy = false
var logic_locked = false
var facing = 1
var base_scale_x = 1.0
var can_flip = true
var max_pv = 200
var pv = max_pv

# =========================
#   READY
# =========================
func _ready():
	base_scale_x = abs(rig.scale.x)
	_play("idle")

	var gs = get_node_or_null("/root/GameState")
	if gs and gs.player:
		player = gs.player
		if not gs.is_connected("player_updated", Callable(self, "_on_player_changed")):
			gs.connect("player_updated", Callable(self, "_on_player_changed"))

	if lance_timer:
		lance_timer.wait_time = fire_interval
		if lance_timer.is_stopped():
			lance_timer.start()

func _on_player_changed(p):
	player = p

# =========================
#   LOOP
# =========================
func _physics_process(_dt):
	if logic_locked or not is_instance_valid(player):
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

	if anim_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if velocity != Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
	_play("idle")

# =========================
#   FLIP
# =========================
func _face_player():
	if not is_instance_valid(player):
		return
	if is_attacking or anim_busy or not can_flip:
		return

	var dx = player.global_position.x - global_position.x
	if dx < 0 and facing != -1:
		facing = -1
		rig.scale.x = -base_scale_x
	elif dx > 0 and facing != 1:
		facing = 1
		rig.scale.x = base_scale_x

# =========================
#   MELEE MOVE
# =========================
func _walk_towards_player():
	if not is_instance_valid(player) or is_attacking:
		return
	var dir_x = sign(player.global_position.x - global_position.x)
	velocity.x = dir_x * move_speed
	velocity.y = 0
	move_and_slide()
	_play("walk")

# =========================
#   SHOOT
# =========================
func _on_lance_timer_timeout():
	if in_melee or in_cac or is_attacking or anim_busy or logic_locked:
		return
	_shoot_lance()

func _shoot_lance():
	if not is_instance_valid(player):
		return

	anim_busy = true
	var prev_can_flip = can_flip
	can_flip = false
	_play("attack")

	await get_tree().create_timer(0.40).timeout

	var lance = lance_scene.instantiate()
	var parent = get_tree().current_scene
	if not parent:
		parent = self
	parent.add_child(lance)
	lance.global_position = lance_spawn.global_position
	lance.direction = Vector2(facing, 0)

	var attack_len = 0.35
	if anim and anim.has_animation("attack"):
		var a = anim.get_animation("attack")
		if a:
			attack_len = a.length
	var remaining = attack_len - 0.20
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout

	anim_busy = false
	can_flip = not (in_melee or in_cac)
	_play("idle")

# =========================
#   CAC (melee hit)
# =========================
func _start_cac_attack():
	if is_attacking:
		return
	is_attacking = true
	velocity = Vector2.ZERO
	move_and_slide()
	_play("cac")

	if is_instance_valid(player) and player.has_method("on_hit"):
		player.on_hit(melee_damage)

	var wait_s = cac_anim_duration
	if anim and anim.has_animation("cac"):
		var a = anim.get_animation("cac")
		if a:
			wait_s = a.length
	await get_tree().create_timer(wait_s).timeout

	_play("idle")
	is_attacking = false

# =========================
#   ZONES
# =========================
func _on_melee_zone_body_entered(body):
	if body.is_in_group("Player"):
		in_melee = true
		can_flip = false

func _on_melee_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false
		if not in_cac:
			can_flip = true

func _on_cac_zone_body_entered(body):
	if body.is_in_group("Player"):
		in_cac = true
		can_flip = false
		if not is_attacking:
			_start_cac_attack()

func _on_cac_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_cac = false
		if not in_melee:
			can_flip = true

# =========================
#   VIE / DÉGÂTS
# =========================
func on_hit(amount):
	if pv <= 0:
		return

	pv -= amount

	if pv <= 0:
		logic_locked = true
		await _play_locked("die")
		_die()
	else:
		logic_locked = true
		await _play_locked("onhit")
		logic_locked = false

func _die():
	queue_free()

# =========================
#   ANIMS
# =========================
func _play(name):
	if anim and anim.current_animation != name:
		anim.play(name)

func _play_locked(name):
	if not anim or not anim.has_animation(name):
		return
	anim.play(name)
	await anim.animation_finished
