extends CharacterBody2D

@export var max_hp = 500
@export var speed = 200
@export var attack_range = 600
@export var stop_distance = 150
@export var cooldown = 1
@export var damage = 100

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator

var pv = 0
var player = null
var is_attacking = false
var is_swim_croco = false
var is_dead = false

var base_scale_x = 0.0
var dx = 0.0
var distance = 0.0

# Reçu depuis la WaterZone
var water_current = Vector2.ZERO

# Zones d'attaque 
var in_swim_zone = false
var in_floor_zone = false

func _ready():
	pv = max_hp
	health_bar.value = pv
	base_scale_x = rotator.scale.x
	find_and_bind_player()

# =============================================================
#                      PHYSICS PROCESS
# =============================================================
func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Eau = pas de gravité, sinon gravité normale
	if is_swim_croco:
		velocity.y = water_current.y
	else:
		apply_gravity(delta)

	if not is_instance_valid(player):
		move_and_slide()
		return

	# Ciblage / orientation
	target()
	flip(dx)

	# Logique: move / stop / attack
	update_logic()

	# Animations
	process_swim()
	process_walk()
	process_idle()

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
#                     GAME STATE / PLAYER
# =============================================================
func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player

# =============================================================
#                  CIBLE / ORIENTATION
# =============================================================
func target():
	if player == null:
		return
	var target_pos = player.get_node("TurnAxis").global_position
	var to_target = target_pos - global_position
	dx = to_target.x
	distance = to_target.length()

func flip(_dx):
	if dx > 1:
		rotator.scale.x = -base_scale_x
	elif dx < -1:
		rotator.scale.x = base_scale_x

# =============================================================
#             LOGIQUE PRINCIPALE 
# =============================================================
func update_logic():
	if is_dead:
		velocity.x = 0
		return

	# Si une attaque est en cours : ne bouge pas
	if is_attacking:
		velocity.x = 0
		return

	# Distance horizontale uniquement pour le déplacement
	var horiz_distance = abs(dx)

	# Pas à portée -> on s'arrête (idle sera géré dans process_idle)
	if horiz_distance > attack_range:
		velocity.x = 0
		return

	# Dans la portée mais pas encore au contact -> on avance vers Moko
	if horiz_distance > stop_distance:
		var dir = 0
		if dx > 0:
			dir = 1
		elif dx < 0:
			dir = -1

		if is_swim_croco:
			# Nage vers Moko + courant
			velocity.x = dir * speed + water_current.x
		else:
			# Marche au sol
			velocity.x = dir * speed
		return

	# Assez proche : s'arrête et attaque si la zone correspond
	velocity.x = 0

	if is_swim_croco and in_swim_zone:
		if not is_attacking:
			attack_swim()
	elif not is_swim_croco and in_floor_zone:
		if not is_attacking:
			attack_on_floor()

# =============================================================
#                         ATTAQUES
# =============================================================
func attack_on_floor():
	if is_dead:
		return
	if is_attacking:
		return
	if not is_on_floor():
		return
	if is_swim_croco:
		return

	is_attacking = true
	velocity.x = 0

	if anim.has_animation("floor_attack"):
		anim.play("floor_attack")

		# Impact à 0.1s après le début
		var impact_timer = get_tree().create_timer(0.2)
		await impact_timer.timeout

		if is_instance_valid(player) and not is_dead:
			player.on_hit(damage)

		# Attend la fin de l'animation d'attaque
		await anim.animation_finished

	if is_dead:
		is_attacking = false
		return

	# Petit cooldown avant de pouvoir réattaquer
	if cooldown > 0:
		var t = get_tree().create_timer(cooldown)
		await t.timeout

	is_attacking = false

func attack_swim():
	if is_dead:
		return
	if is_attacking:
		return
	if not is_swim_croco:
		return

	is_attacking = true
	velocity = water_current

	if anim.has_animation("swim_attack"):
		anim.play("swim_attack")

		# Impact immédiat
		if is_instance_valid(player) and not is_dead:
			player.on_hit(damage)

		# Attend la fin de l'animation de nage attaque
		await anim.animation_finished

	if is_dead:
		is_attacking = false
		return

	if cooldown > 0:
		var t2 = get_tree().create_timer(cooldown)
		await t2.timeout

	is_attacking = false

# =============================================================
#                 DOMMAGES / MORT
# =============================================================
func on_hit(damage_taken):
	if is_dead:
		return

	if not anim.is_playing() or anim.current_animation != "onhit":
		anim.play("onhit")

	pv -= damage_taken
	if pv < 0:
		pv = 0
	health_bar.value = pv
	_show_damage_popup(damage_taken)

	if pv <= 0:
		die()

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
	velocity = Vector2.ZERO
	if anim.has_animation("die"):
		anim.play("die")
		await anim.animation_finished
	queue_free()

# ============================ ZONES ===========================
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

# ============================ ANIMS ===========================
func process_swim():
	if is_swim_croco and not is_attacking and not is_dead:
		if anim.has_animation("swim"):
			if anim.current_animation != "swim":
				anim.play("swim")

func process_walk():
	if not is_swim_croco and not is_attacking and not is_dead and is_on_floor():
		if abs(velocity.x) > 0.1:
			if anim.has_animation("walk"):
				if anim.current_animation != "walk":
					anim.play("walk")

func process_idle():
	if is_attacking or is_dead:
		return

	if is_swim_croco:
		return

	# Idle UNIQUEMENT si Moko est hors portée
	var horiz_distance = abs(dx)
	if horiz_distance > attack_range and is_on_floor():
		if anim.has_animation("idle"):
			if anim.current_animation != "idle":
				anim.play("idle")
