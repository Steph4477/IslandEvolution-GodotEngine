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
var in_melee = false      # player dans MeleeZone
var in_cac = false        # player dans CacZone
var is_attacking = false  # anim CàC en cours
var anim_busy = false     # anim tir en cours
var facing = 1
var base_scale_x = 1.0
var can_flip = true       # autorise le flip

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
	if not is_instance_valid(player):
		return

	_face_player()

	# 🔑 En CàC : relance l'attaque tant que le joueur reste dans la zone
	if in_cac:
		if not is_attacking:
			_start_cac_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Mêlée = on marche vers le joueur
	if in_melee:
		_walk_towards_player()
		return

	# Anim de tir : ne rien faire d'autre
	if anim_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Idle par défaut
	if velocity != Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
	_play("idle")

# =========================
#   FLIP (simple)
# =========================
func _face_player():
	if not is_instance_valid(player):
		return
	if is_attacking:
		return
	if anim_busy:
		return
	if not can_flip:
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
	if not is_instance_valid(player):
		return
	if is_attacking:
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
	# pas de tir si combat rapproché ou anim prioritaire
	if in_melee or in_cac or is_attacking or anim_busy:
		return
	_shoot_lance()

func _shoot_lance():
	if not is_instance_valid(player):
		return

	# verrou d'anim de tir
	anim_busy = true
	var prev_can_flip = can_flip
	can_flip = false
	_play("attack")

	# léger délai avant spawn (wind-up)
	await get_tree().create_timer(0.20).timeout

	# projectile
	var lance = lance_scene.instantiate()
	var parent = get_tree().current_scene
	if not parent:
		parent = self
	parent.add_child(lance)
	lance.global_position = lance_spawn.global_position
	lance.direction = Vector2(facing, 0)

	# attendre fin réelle de l'anim "attack"
	var attack_len = 0.35
	if anim and anim.has_animation("attack"):
		var a = anim.get_animation("attack")
		if a:
			attack_len = a.length
	var remaining = attack_len - 0.20
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout

	anim_busy = false
	if not in_melee and not in_cac:
		can_flip = prev_can_flip
	else:
		can_flip = false
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
	# Pas besoin d'autre chose : _physics_process relancera si in_cac est toujours vrai

# =========================
#   ZONES (connectées dans l’inspector)
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
		# Démarre immédiatement la 1ère attaque si dispo
		if not is_attacking:
			_start_cac_attack()

func _on_cac_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_cac = false
		if not in_melee:
			can_flip = true

# =========================
#   ANIMS
# =========================
func _play(name):
	if anim and anim.current_animation != name:
		anim.play(name)
