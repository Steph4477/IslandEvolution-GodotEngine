extends CharacterBody2D


@export var max_hp = 300
@export var speed = 200
@export var attack_range = 300          # portée CAC (zone de mêlée)
@export var drool_range = 800           # portée du crachat
@export var stop_distance = 40          # distance d’arrêt avant contact
@export var damage = 100
@export var drool_scene = preload("res://Enemies/Froggle/Drool/drool_bolt.tscn")
@export var drool_cooldown = 1.6        # délai entre deux crachats

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator
@onready var attack_timer = $Timer          # pour CAC 
@onready var drool_timer = $DroolTimer     

var pv = 0
var player = null
var in_melee = false
var is_drooling = false
var base_scale_x = 0.0
var is_dead = false
var is_attacking = false
var dx = 0.0
var distance = 0.0

func _ready():
	pv = max_hp
	health_bar.max_value = max_hp
	health_bar.value = pv
	find_player()
	base_scale_x = rotator.scale.x

	attack_timer.stop()
	drool_timer.stop()
	drool_timer.one_shot = true

func _physics_process(delta):
	apply_gravity(delta)

	# verrou pendant attaque / mort / bave
	if is_dead or is_attacking or is_drooling:
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

	# logique d'attaque simple par distance
	if not is_dead and not is_attacking:
		# mêlée : on frappe immédiatement quand la zone touche 
		# distance : crachat si dans la range 
		if not in_melee and distance > attack_range and distance <= drool_range:
			if drool_timer.is_stopped():
				drool_attack()
		

	move_and_slide()

# --- Cible / Flip ---
func target():
	var target_pos = player.get_node("TurnAxis").global_position
	var to_target = target_pos - global_position
	dx = to_target.x
	distance = to_target.length()

func flip(_dx):
	if dx > 1:
		rotator.scale.x = base_scale_x
	elif dx < -1:
		rotator.scale.x = -base_scale_x

# --- Mouvement et animation ---
func move_and_anim():
	# si en mêlée on entrain de baver : on reste collé, pas de déplacement
	if in_melee or is_drooling:
		velocity.x = 0
		if not is_attacking and anim.current_animation != "idle":
			anim.play("idle")
		return

	# Approche sur Moko 
	if distance <= drool_range:
		if dx > stop_distance:
			velocity.x = speed
			if anim.current_animation != "walk":
				anim.play("walk")
		elif dx < -stop_distance:
			velocity.x = -speed
			if anim.current_animation != "walk":
				anim.play("walk")
		else:
			velocity.x = 0
			if anim.current_animation != "idle":
				anim.play("idle")
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")

# --- Gravité ---
func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += GRAVITY * delta

# --- Game state ---
func find_player():
	var gs = get_node("/root/GameState")
	player = gs.player
	if not gs.is_connected("player_updated", Callable(self, "on_player_changed")):
		gs.connect("player_updated", Callable(self, "on_player_changed"))

func on_player_changed(new_player):
	player = new_player

# --- Attaque ---
func attack_melee():
	if is_dead or is_attacking:
		return
	is_attacking = true
	velocity.x = 0
	anim.play("attack")
	player.on_hit(damage)
	await anim.animation_finished
	is_attacking = false

func drool_attack():
	if is_dead or is_attacking:
		return
	is_attacking = true
	is_drooling = true
	velocity.x = 0
	anim.play("drool")   
	await anim.animation_finished
	
	# si Moko est passé en mêlée pendant l'anim, on annule le tir
	if in_melee or distance <= attack_range:
		is_attacking = false
		is_drooling = false
		if attack_timer.is_stopped():
			attack_timer.start()
		return

	var bolt = drool_scene.instantiate()
	get_parent().add_child(bolt)

	# direction selon le flip
	var dir_x = 1
	if rotator.scale.x < 0:
		dir_x = -1

	# récupération du muzzle
	var muzzle = rotator.get_node("Muzzle")
	if muzzle:
		bolt.global_position = muzzle.global_position
	else:
		bolt.global_position = global_position

	bolt.direction = Vector2(dir_x, 0)
	bolt.max_distance = drool_range

	if has_node("SpitSound"):
		$SpitSound.play_spit()

	is_attacking = false
	is_drooling = false
	drool_timer.start(drool_cooldown)


# --- Dommage et mort ---
func on_hit(damage_taken):
	if is_dead:
		return
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
	is_dead = true
	in_melee = false
	attack_timer.stop()
	drool_timer.stop()
	velocity = Vector2.ZERO
	anim.play("die")
	await anim.animation_finished
	queue_free()

# --- ZONES ---
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		in_melee = true
		velocity = Vector2.ZERO
		if not is_dead and not is_attacking:
			attack_melee()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false

# cadencement de la mêlée
func _on_timer_timeout():
	if in_melee and not is_dead and not is_attacking and not is_drooling:
		attack_melee()

func _on_drool_timer_timeout() -> void:
	if is_dead:
		return
	if in_melee:
		return
	if not is_attacking and distance > attack_range and distance <= drool_range:
		drool_attack()
	else:
		drool_timer.stop()
 
