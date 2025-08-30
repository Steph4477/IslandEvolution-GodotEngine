extends CharacterBody2D

# =========================================================
# =                    RÉGLAGES                           =
# =========================================================
@export var lance_scene: PackedScene = preload("res://Tir/lance_trap.tscn")
@export var fire_interval: float = 3.0
@export var move_speed: float = 100.0
@export var melee_damage: int = 100
@export var cac_anim_duration: float = 0.6

# =========================================================
# =                         NODES                         =
# =========================================================
@onready var rig: Node2D = $Rig
@onready var anim: AnimationPlayer = $Rig/AnimationPlayer
@onready var lance_spawn: Node2D = $Rig/Lance
@onready var melee_zone: Area2D = $Rig/MeleeZone
@onready var cac_zone: Area2D = $Rig/CacZone
@onready var lance_timer: Timer = $LanceTimer

# =========================================================
# =                        ÉTAT                           =
# =========================================================
var player: Node = null

var in_melee: bool = false      # Moko dans la zone de poursuite
var in_cac: bool = false        # Moko dans la zone d’attaque cac
var is_attacking: bool = false  # une attaque cac est en cours
var anim_busy: bool = false     # on joue une anim bloquante (tir / onhit / die)
var can_flip: bool = true       # peut se retourner

var facing: int = 1             # 1 = droite, -1 = gauche
var base_scale_x: float = 1.0

# Vie
var max_pv: int = 200
var pv: int = 200

# Invincibilité courte après coup
var hit_locked: bool = false
var hit_lock_time: float = 0.20

# Mort
var is_dead: bool = false

# Sauvegarde du point de spawn (pour reset)
var spawn_pos: Vector2 = Vector2.ZERO
var spawn_scale_x: float = 1.0
var spawn_facing: int = 1

# =========================================================
# =                        READY                          =
# =========================================================
func _ready():
	# groupe Enemy (sécurité)
	if not is_in_group("Enemy"):
		add_to_group("Enemy")

	# mémorise l’échelle positive (evite miroir bizarre)
	base_scale_x = abs(rig.scale.x)

	# snapshot de spawn
	spawn_pos = global_position
	spawn_scale_x = rig.scale.x
	spawn_facing = facing

	# active les zones après la frame
	if melee_zone:
		melee_zone.set_deferred("monitoring", true)
	if cac_zone:
		cac_zone.set_deferred("monitoring", true)

	_play("idle")

	# branchement au GameState pour avoir le player et réagir au respawn
	var gs = get_node_or_null("/root/GameState")
	if gs:
		if gs.player:
			player = gs.player
		if not gs.is_connected("player_updated", Callable(self, "_on_player_changed")):
			gs.connect("player_updated", Callable(self, "_on_player_changed"))

	# démarre le timer de tir
	if lance_timer:
		lance_timer.wait_time = fire_interval
		if lance_timer.is_stopped():
			lance_timer.start()

# appelé quand Moko réapparaît
func _on_player_changed(p):
	player = p
	call_deferred("_reset_after_player_respawn")

func _reset_after_player_respawn():
	await get_tree().process_frame
	_reset_enemy()
	_force_face_player()

# =========================================================
# =                  BOUCLE PHYSIQUE                      =
# =========================================================
func _physics_process(_dt):
	if is_dead:
		return
	if not is_instance_valid(player):
		return

	# tourne vers Moko pendant l'idle/walk
	_face_player()

	# si Moko est mort, on sort du CàC
	if in_cac and _player_is_dead():
		in_cac = false
		is_attacking = false
		can_flip = true
		# on ne tire pas tout de suite, on attend le timer
		return

	# etat cac : on lance l’attaque une seule fois
	if in_cac:
		if not is_attacking:
			_start_cac_attack()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# etat melee : on marche vers Moko
	if in_melee:
		_walk_towards_player()
		return

	# si une anim bloquante joue (tir / onhit / die), ne bouge pas
	if anim_busy:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# sinon idle propre
	if velocity != Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
	_play("idle")

# =========================================================
# =                    ORIENTATION                        =
# =========================================================
func _face_player():
	if not is_instance_valid(player):
		return
	if is_attacking or anim_busy or not can_flip or is_dead:
		return

	var dx = player.global_position.x - global_position.x
	if dx < 0 and facing != -1:
		facing = -1
		rig.scale.x = -base_scale_x
	elif dx > 0 and facing != 1:
		facing = 1
		rig.scale.x = base_scale_x

# orientation “forcée” (utile au reset)
func _force_face_player():
	if not is_instance_valid(player):
		return
	var dx = player.global_position.x - global_position.x
	if dx > 0:
		facing = 1
	else:
		facing = -1
	rig.scale.x = base_scale_x * facing

# =========================================================
# =                   DÉPLACEMENT                         =
# =========================================================
func _walk_towards_player():
	if not is_instance_valid(player):
		return
	if is_attacking or anim_busy or is_dead:
		return

	var dir_x = sign(player.global_position.x - global_position.x)
	velocity.x = dir_x * move_speed
	velocity.y = 0
	move_and_slide()
	_play("walk")

# =========================================================
# =                       TIR                              =
# =========================================================
func _on_lance_timer_timeout():
	# ne tire pas si on est en mêlée, en CàC, en anim, mort
	if is_dead:
		return
	if in_melee or in_cac or is_attacking or anim_busy:
		return
	_shoot_lance()

func _shoot_lance():
	if not is_instance_valid(player):
		return
	if is_dead:
		return

	anim_busy = true
	can_flip = false
	_play("attack")

	# petit délai avant de créer le projectile
	await get_tree().create_timer(0.40).timeout

	var lance = lance_scene.instantiate()
	var parent = get_tree().current_scene
	if not parent:
		parent = self
	parent.add_child(lance)

	# place et oriente le projectile
	lance.global_position = lance_spawn.global_position
	lance.direction = Vector2(facing, 0)

	# attendre la fin de l’anim d’attaque (ou sa durée)
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

# =========================================================
# =                 CORPS À CORPS                         =
# =========================================================
func _start_cac_attack():
	if is_attacking or is_dead:
		return
	if _player_is_dead():
		return

	is_attacking = true
	anim_busy = true
	can_flip = false

	velocity = Vector2.ZERO
	move_and_slide()
	_play("cac")

	# applique les dégâts si Moko est encore vivant
	if is_instance_valid(player):
		if not _player_is_dead():
			if player.has_method("on_hit"):
				player.on_hit(melee_damage)

	# attendre la fin de l’anim cac
	var wait_s = cac_anim_duration
	if anim and anim.has_animation("cac"):
		var a = anim.get_animation("cac")
		if a:
			wait_s = a.length
	await get_tree().create_timer(wait_s).timeout

	is_attacking = false
	anim_busy = false
	can_flip = not (in_melee or in_cac)
	_play("idle")

# =========================================================
# =                     ZONES                             =
# =========================================================
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
		if _player_is_dead():
			return
		in_cac = true
		can_flip = false
		if not is_attacking:
			_start_cac_attack()

func _on_cac_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_cac = false
		if not in_melee:
			can_flip = true

# =========================================================
# =                 VIE / DÉGÂTS                          =
# =========================================================
func on_hit(amount):
	if is_dead:
		return
	print("[pyg] on_hit reçu :", amount, " | pv avant:", pv)

	# i-frames: éviter le spam multi-collisions la même frame
	if hit_locked:
		return

	if pv <= 0:
		return

	pv -= amount
	print("[pyg] pv après:", pv)

	if pv <= 0:
		_die()
		return

	# Réaction à un coup reçu (animation onhit)
	_hit_react()

func _hit_react():
	if is_dead:
		return
	if anim_busy: # si déjà en anim bloquante, ne pas empiler
		return

	hit_locked = true
	anim_busy = true
	can_flip = false

	velocity = Vector2.ZERO
	move_and_slide()

	if anim and anim.has_animation("onhit"):
		anim.play("onhit")
		await anim.animation_finished
	else:
		# fallback: léger délai si l'anim manque
		await get_tree().create_timer(0.15).timeout

	anim_busy = false
	can_flip = not (in_melee or in_cac)

	# fin des i-frames après un petit délai
	await get_tree().create_timer(hit_lock_time).timeout
	hit_locked = false

# Mort propre avec anim
func _die():
	if is_dead:
		return
	is_dead = true

	# Couper toute logique
	in_melee = false
	in_cac = false
	is_attacking = false
	anim_busy = true
	can_flip = false

	# Stop tir + zones + collisions pour stopper tout nouveau hit
	if lance_timer:
		lance_timer.stop()
	if melee_zone:
		melee_zone.monitoring = false
	if cac_zone:
		cac_zone.monitoring = false

	collision_layer = 0
	collision_mask = 0

	velocity = Vector2.ZERO
	move_and_slide()

	if anim and anim.has_animation("die"):
		anim.play("die")
		await anim.animation_finished
	else:
		# sécurité si l'anim n'existe pas
		await get_tree().create_timer(0.3).timeout

	queue_free()

# =========================================================
# =                     ANIM UTILS                        =
# =========================================================
func _play(name):
	# Ne pas interrompre une anim bloquante (onhit/cac/attack/die)
	if is_dead:
		return
	if anim_busy and name != "die":
		return
	if anim and anim.current_animation != name:
		anim.play(name)

func _play_and_wait(name):
	if not anim:
		return
	if not anim.has_animation(name):
		print("[pyg][warn] animation manquante:", name)
		return
	anim.play(name)
	await anim.animation_finished

# =========================================================
# =                      RESET PYG                        =
# =========================================================
func _reset_enemy():
	in_melee = false
	in_cac = false
	is_attacking = false
	anim_busy = false
	can_flip = true
	is_dead = false
	hit_locked = false

	velocity = Vector2.ZERO
	move_and_slide()

	global_position = spawn_pos
	rig.scale.x = spawn_scale_x
	facing = spawn_facing

	pv = max_pv

	# réactive collisions/zones
	collision_layer = 1
	collision_mask = 1
	if lance_timer:
		lance_timer.stop()
		lance_timer.wait_time = fire_interval
		lance_timer.start()

	if melee_zone:
		melee_zone.set_deferred("monitoring", true)
	if cac_zone:
		cac_zone.set_deferred("monitoring", true)

	_play("idle")

# =========================================================
# =                   HELPERS SIMPLES                     =
# =========================================================
func _player_is_dead():
	if not is_instance_valid(player):
		return true
	if player.is_dead:
		return true
	if player.pv <= 0:
		return true
	return false
