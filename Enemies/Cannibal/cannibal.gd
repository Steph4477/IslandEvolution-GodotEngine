extends CharacterBody2D

# ========================== RÉGLAGES ==========================
@export var lance_scene = preload("res://Shoot/Enemies/Bone/bone.tscn")

# ============================ LOOT ============================
var loot_lance_scene = preload("res://Loot/Spear/spear.tscn")

@export var max_hp = 600
@export var speed = 200
@export var attack_range = 300      # distance pour considérer le cac
@export var lance_range = 800       # portée de la lance
@export var stop_distance = 40      # plus trop utile mais on garde si besoin)
@export var damage = 50
@export var lance_cooldown = 1.6
@export var attack_cooldown = 1.0

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator
@onready var attack_timer = $CacTimer
@onready var lance_timer = $LanceTimer

var pv = 0
var player = null
var cam = null

var in_melee = false
var is_attacking = false
var is_dead = false

var base_scale_x = 0.0
var dx = 0.0
var distance = 0.0

# =============================================================
#                         READY
# =============================================================
func _ready():
	pv = max_hp
	health_bar.max_value = max_hp
	health_bar.value = pv
	
	find_player()
	base_scale_x = rotator.scale.x
	
	attack_timer.one_shot = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.stop()
	
	lance_timer.one_shot = true
	lance_timer.stop()

# =============================================================
#                      PHYSICS PROCESS
# =============================================================
func _physics_process(delta):
	apply_gravity(delta)
	
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Pendant une attaque (cac ou lance), il ne se déplace pas
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_instance_valid(player):
		target()
		flip(dx)
		move_and_anim()
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")
	
	# Lancer de lance à distance, hors mêlée
	if not is_dead and not is_attacking:
		if not in_melee and distance > attack_range and distance <= lance_range:
			if lance_timer.is_stopped():
				lance_attack()
	
	move_and_slide()

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
		rotator.scale.x = base_scale_x
	elif dx < -1:
		rotator.scale.x = -base_scale_x

# =============================================================
#               MOUVEMENT + ANIMATION
# =============================================================
func move_and_anim():
	# 1) En mêlée on ne bouge plus, on laisse le cac se faire avec les timers
	if in_melee:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")
		return
	
	# 2) Sinon on marche vers Moko
	if dx > 0:
		velocity.x = speed
		if anim.current_animation != "walk":
			anim.play("walk")
	elif dx < 0:
		velocity.x = -speed
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")

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
func find_player():
	var gs = get_node("/root/GameState")
	player = gs.player
	if player:
		cam = player.get_node("Camera2D")
	gs.connect("player_updated", Callable(self, "on_player_changed"))

func on_player_changed(new_player):
	player = new_player
	if player:
		cam = player.get_node("Camera2D")

# =============================================================
#                         ATTAQUES
# =============================================================
func attack_melee():
	# cac avec cooldown
	if is_dead or is_attacking:
		return
	
	is_attacking = true
	velocity.x = 0
	anim.play("cac")
	
	# Dégâts sur Moko
	if not is_dead and is_instance_valid(player):
		player.on_hit(damage)
	
	# On attend le cooldown
	var t = get_tree().create_timer(attack_cooldown)
	await t.timeout
	
	if is_dead:
		return
	
	is_attacking = false

func lance_attack():
	if is_dead or is_attacking:
		return
	
	is_attacking = true
	velocity.x = 0
	anim.play("attack")
	await anim.animation_finished
	if is_dead:
		return
	
	# Si il au cac, on annule le tir
	if in_melee or distance <= attack_range:
		is_attacking = false
		return
	
	var lance = lance_scene.instantiate()
	get_parent().add_child(lance)
	
	var dir_x = 1
	if rotator.scale.x < 0:
		dir_x = -1
	
	var muzzle = rotator.get_node("Muzzle")
	if muzzle:
		lance.global_position = muzzle.global_position
	else:
		lance.global_position = global_position
	
	lance.direction = Vector2(dir_x, 0)
	lance.max_distance = lance_range
	
	is_attacking = false
	lance_timer.start(lance_cooldown)

# =============================================================
#                 DOMMAGES / MORT
# =============================================================
func on_hit(damage_taken):
	if is_dead:
		return
	if not anim.is_playing() or anim.current_animation != "on_hit":
		anim.play("on_hit")
	
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
	popup.position = Vector2(0, -30)
	popup.scale.x = 1
	popup.show_damage(amount)

func die():
	if is_dead:
		return
	is_dead = true
	in_melee = false
	attack_timer.stop()
	lance_timer.stop()
	is_attacking = false
	velocity = Vector2.ZERO
	if cam:
		cam.offset = Vector2.ZERO
	anim.play("die")
	await anim.animation_finished
	queue_free()

# =============================================================
#                    ZONES DE MÊLÉE
# =============================================================
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		in_melee = true
		velocity = Vector2.ZERO
		if attack_timer.is_stopped():
			attack_timer.start()
		if not is_dead and not is_attacking:
			attack_melee()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false
		attack_timer.stop()

# =============================================================
#                     TIMERS / CADENCEMENT
# =============================================================
func _on_cac_timer_timeout():
	if in_melee and not is_dead and not is_attacking:
		attack_melee()

func _on_lance_timer_timeout():
	if is_dead:
		return
	if in_melee:
		return
	if not is_attacking and distance > attack_range and distance <= lance_range:
		lance_attack()
	else:
		lance_timer.stop()
