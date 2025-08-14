extends CharacterBody2D

# =========================
#        EXPORTS
# =========================
@export var lance_scene = preload("res://Tir/lance_trap.tscn")
@export var fire_interval = 3.0
@export var total_shots = 10
@export var move_speed = 100.0
@export var melee_damage = 100
@export var melee_damage_cooldown = 1
@export var resume_shot_delay_after_melee = 0.10
@export var sprite_looks_right = true   # regarde à droite
@export var cac_fallback_duration = 0.6

# =========================
#     RÉFÉRENCES ($)
# =========================
@onready var meleezone = $Rig/MeleeZone
@onready var caczone = $Rig/CacZone
@onready var timer = $LanceTimer
@onready var cac_timer = $CacTimer
@onready var anim = $Rig/AnimationPlayer
@onready var spawn_lance = $Rig/Lance
@onready var rig = $Rig

# =========================
#        ÉTAT
# =========================
var player = null
var shot_count = 0
var is_melee_mode = false
var moko_in_cac_zone = false
var is_attacking = false
var facing = 1
var state = "idle/shoot"

# flip
var base_scale_x = 1.0
var visual_sign = 1

# =========================
#          READY
# =========================
func _ready():
	print("[pyg] ready()")
	_bind_player()

	# timers (sécurisé si la scène ne les a pas)
	if timer:
		timer.wait_time = fire_interval
		timer.start()
		if not timer.is_connected("timeout", Callable(self, "_on_lance_timer_timeout")):
			timer.connect("timeout", Callable(self, "_on_lance_timer_timeout"))
		print("[pyg] timer lance start @", fire_interval, "s")
	else:
		print("[pyg][warn] LanceTimer manquant")

	if cac_timer:
		cac_timer.wait_time = melee_damage_cooldown
		cac_timer.one_shot = true
		cac_timer.stop()
		if not cac_timer.is_connected("timeout", Callable(self, "_on_cac_timer_timeout")):
			cac_timer.connect("timeout", Callable(self, "_on_cac_timer_timeout"))
		print("[pyg] timer cac one_shot @", melee_damage_cooldown, "s (stoppé)")
	else:
		print("[pyg][warn] CacTimer manquant")

	# zones (si non branchées dans l’éditeur)
	if meleezone:
		if not meleezone.is_connected("body_entered", Callable(self, "_on_melee_zone_body_entered")):
			meleezone.connect("body_entered", Callable(self, "_on_melee_zone_body_entered"))
		if not meleezone.is_connected("body_exited", Callable(self, "_on_melee_zone_body_exited")):
			meleezone.connect("body_exited", Callable(self, "_on_melee_zone_body_exited"))
	else:
		print("[pyg][warn] MeleeZone manquante")

	if caczone:
		if not caczone.is_connected("body_entered", Callable(self, "_on_cac_zone_body_entered")):
			caczone.connect("body_entered", Callable(self, "_on_cac_zone_body_entered"))
		if not caczone.is_connected("body_exited", Callable(self, "_on_cac_zone_body_exited")):
			caczone.connect("body_exited", Callable(self, "_on_cac_zone_body_exited"))
	else:
		print("[pyg][warn] CacZone manquante")

	# flip init (AUCUN recalcul d'offset, les Area2D suivent le Rig)
	base_scale_x = abs(rig.scale.x)
	visual_sign = 1
	if not sprite_looks_right:
		visual_sign = -1
	_apply_facing(facing)

	_play("idle")
	print("[pyg] state →", state)

# =========================
#      GAMESTATE / PLAYER
# =========================
func _bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		print("[pyg] player bind →", player)
		if not gs.is_connected("player_updated", Callable(self, "_on_player_changed")):
			gs.connect("player_updated", Callable(self, "_on_player_changed"))
	else:
		print("[pyg][warn] GameState introuvable")

func _on_player_changed(p):
	player = p
	print("[pyg] player updated →", player)

# =========================
#     BOUCLE PRINCIPALE
# =========================
func _physics_process(_dt):
	# 1) FLIP EN PREMIER (débloqué même en CàC)
	_face_player()

	# 2) RÈGLES
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(player):
		_stop_and_idle()
		return

	if not is_melee_mode:
		_stop_and_idle()             # hors melee → immobile (tirs via timer)
		return

	if is_melee_mode and not moko_in_cac_zone:
		_move_towards_player()       # marche vers Moko
		return

	if moko_in_cac_zone:
		_stop_and_idle()             # coups CàC via cac_timer
		return

# =========================
#            FLIP
# =========================
func _face_player():
	if not is_instance_valid(player):
		return

	var dx = player.global_position.x - global_position.x
	var want = 1
	if dx < 0.0:
		want = -1

	print("[pyg][face] dx:", dx, " want:", want, " facing:", facing, " atk:", is_attacking)

	if want != facing:
		print("[pyg][face] FLIP →", want)
		_apply_facing(want)
	else:
		print("[pyg][face] KEEP (same)")

func _apply_facing(new_facing):
	facing = new_facing
	rig.scale.x = base_scale_x * facing * visual_sign
	print("[pyg][flip] rig.scale.x →", rig.scale.x)

# =========================
#     MVT & ANIMATIONS
# =========================
func _move_towards_player():
	var dir_x = 1.0
	if player.global_position.x < global_position.x:
		dir_x = -1.0
	velocity.x = dir_x * move_speed
	velocity.y = 0.0
	move_and_slide()
	_play("walk")

	if state != "walk→moko":
		print("[pyg][state] ", state, "→ walk→moko")
		state = "walk→moko"
	print("[pyg][move] towards moko | vel:", velocity)

func _stop_and_idle():
	if velocity != Vector2.ZERO:
		print("[pyg][move] stop")
	velocity = Vector2.ZERO
	move_and_slide()
	_play("idle")
	if state != "idle/shoot":
		print("[pyg][state] ", state, "→ idle/shoot")
		state = "idle/shoot"

func _play(name):
	if anim and anim.current_animation != name:
		print("[pyg][anim] play →", name)
		anim.play(name)

# =========================
#             TIRS
# =========================
func _on_lance_timer_timeout():
	print("[pyg][shoot] timeout")
	if is_melee_mode:
		print("[pyg][shoot] annulé (en melee)")
		return
	if not is_instance_valid(player):
		print("[pyg][shoot] annulé (player invalide)")
		return
	if shot_count >= total_shots:
		if timer:
			timer.stop()
		print("[pyg][shoot] stop (quota atteint)")
		return

	shot_count += 1
	print("[pyg][shoot] tir #", shot_count)
	_play("attack")
	await get_tree().create_timer(0.20).timeout
	_spawn_lance()
	if anim:
		await anim.animation_finished
	await get_tree().create_timer(0.50).timeout
	_play("idle")

func _spawn_lance():
	if not spawn_lance or not lance_scene:
		print("[pyg][shoot] spawn annulé (réf manquante)")
		return

	var lance = lance_scene.instantiate()
	var parent = self
	if get_tree().current_scene:
		parent = get_tree().current_scene
	parent.add_child(lance)

	lance.global_position = spawn_lance.global_position
	var dir = Vector2(facing, 0.0)

	if lance.has_method("setup"):
		lance.setup(dir)
	elif "direction" in lance:
		lance.direction = dir
	elif "facing" in lance:
		lance.facing = facing
	elif "dir" in lance:
		lance.dir = dir
	elif "velocity" in lance:
		if "speed" in lance:
			lance.velocity = dir * lance.speed
		else:
			lance.velocity = dir * 600.0

	print("[pyg][shoot] spawn | pos:", lance.global_position, " dir:", dir)

# =========================
#              CÀC
# =========================
func _on_cac_timer_timeout():
	print("[pyg][cac] timeout")
	if not is_instance_valid(player): print("[pyg][cac] annulé (player invalide)"); return
	if not moko_in_cac_zone: print("[pyg][cac] annulé (hors CacZone)"); return
	if is_attacking: print("[pyg][cac] annulé (déjà en attaque)"); return

	_start_cac_attack(player)

func _start_cac_attack(target):
	if not is_instance_valid(target):
		print("[pyg][cac] START annulé (target invalide)")
		return
	if not target.has_method("on_hit"):
		print("[pyg][cac] START annulé (target sans on_hit)")
		return

	is_attacking = true
	_stop_and_idle()
	#_face_player()  # flip autorisé pendant le CàC

	var dx = target.global_position.x - global_position.x
	var dist = dx
	if dist < 0.0:
		dist = -dist
	print("[pyg][cac] START | dist:", dist, " (raw:", dx, ") | dmg:", melee_damage)

	target.on_hit(melee_damage)
	_play("cac")

	# Attente sûre basée sur la longueur de l'anim "cac" si dispo, sinon fallback
	var wait_s = cac_fallback_duration
	if anim and anim.has_animation("cac"):
		var a = anim.get_animation("cac")
		if a:
			wait_s = a.length
	await get_tree().create_timer(wait_s).timeout

	# petite marge après l'impact
	await get_tree().create_timer(0.30).timeout
	is_attacking = false
	print("[pyg][cac] END")

	# si Moko est toujours dans la CacZone, on relance le timer d'attaque
	if moko_in_cac_zone and cac_timer and cac_timer.is_stopped():
		cac_timer.start()
		print("[pyg][cac] relance timer (encore en zone)")


# =========================
#            ZONES
# =========================
func _on_melee_zone_body_entered(body):
	if not body.is_in_group("Player"): return
	is_melee_mode = true
	if timer: timer.stop()
	print("[pyg][zone] melee ENTER → stop tirs")

func _on_melee_zone_body_exited(body):
	if not body.is_in_group("Player"): return
	is_melee_mode = false
	moko_in_cac_zone = false
	shot_count = 0
	print("[pyg][zone] melee EXIT → reprise tirs après délai")
	await get_tree().create_timer(resume_shot_delay_after_melee).timeout

	# ✅ Ne relance PAS si on est revenu en melee/cac ou si on attaque
	if is_melee_mode or moko_in_cac_zone or is_attacking:
		print("[pyg][zone] reprise annulée (encore en melee/cac/atk)")
		return

	if timer and timer.is_stopped():
		timer.start()
		print("[pyg][zone] tirs repris")

func _on_cac_zone_body_entered(body):
	if not body.is_in_group("Player"): return
	moko_in_cac_zone = true
	_stop_and_idle()

	# ✅ Sécurité : aucune reprise de tir pendant le cac
	if timer and not timer.is_stopped():
		timer.stop()
		print("[pyg][zone] tirs stoppés (cac)")

	if cac_timer and cac_timer.is_stopped():
		cac_timer.start()
		print("[pyg][cac] timer démarré")
	print("[pyg][zone] cac ENTER")

func _on_cac_zone_body_exited(body):
	if not body.is_in_group("Player"): return
	moko_in_cac_zone = false
	print("[pyg][zone] cac EXIT")
	if is_melee_mode and not is_attacking:
		_move_towards_player()
