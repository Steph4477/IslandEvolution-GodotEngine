extends CharacterBody2D

@export var max_hp = 300
@export var speed = 400
@export var attack_range = 500
@export var stop_distance = 40
@export var damage = 100

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator
@onready var attack_timer = $Timer
@onready var spawnpoint = $SpawnPoint

@export var sprint_loot_scene = preload("res://Player/Skills/Sprint/Sprint.tscn")

var pv = 0
var player = null
var in_melee = false
var base_scale_x = 0.0
var is_dead = false
var is_attacking = false

# --- Variables pour la target ---
var dx = 0.0
var dy = 0.0
var distance = 0.0

func _ready():
	pv = max_hp
	health_bar.max_value = max_hp
	health_bar.value = pv
	find_player()
	attack_timer.stop()
	base_scale_x = rotator.scale.x

func _physics_process(delta):
	apply_gravity(delta)
	
	# Pendant la mort ou l'attaque fige le perso au sol
	if is_dead or is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_instance_valid(player):
		target()
		flip(dx)
		move_and_anim()
	else:
		velocity.x = 0
		anim.play("idle")
	
	move_and_slide()

# --- Cible le noeud TurnAxis (la tête de Moko) ---
func target():
	var target_pos = player.get_node("TurnAxis").global_position
	var to_target = target_pos - global_position
	dx = to_target.x
	distance = to_target.length()

# --- Flip visuel ---
func flip(_dx):
	if dx > 1:
		rotator.scale.x = base_scale_x
	elif dx < -1:
		rotator.scale.x = -base_scale_x

# --- Déplacement + anim ---
func move_and_anim():
	if distance < attack_range and dx > stop_distance:
		velocity.x = speed
		if anim.current_animation != "walk":
			anim.play("walk")
	elif distance < attack_range and dx < -stop_distance:
		velocity.x = -speed
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")

func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += GRAVITY * delta

# --- Trouve Moko ---
func find_player():
	var gs = get_node("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "on_player_changed"))

func on_player_changed(new_player):
	player = new_player

# --- Combat ---
func attack():
	if is_dead or is_attacking:
		return
	is_attacking = true
	velocity.x = 0
	anim.play("attack")
	player.damage_mode.on_hit(damage)
	await anim.animation_finished
	is_attacking = false

func _on_timer_timeout():
	if not is_dead:
		attack()

# --- Dégâts pris ---
func on_hit(damage_taken):
	if is_dead:
		return
	pv -= damage_taken
	health_bar.value = max(pv, 0)
	_show_damage_popup(damage_taken)
	if pv <= 0:
		die()

# --- Popup dégâts ---
func _show_damage_popup(amount: int):
	var scene = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn")
	var popup = scene.instantiate()
	$HealthBar.add_child(popup)
	popup.position = Vector2(0, -30)
	popup.scale.x = 1   # pas d'effet miroir au sprint
	popup.show_damage(amount)

# --- Mort ---
func die():
	is_dead = true
	in_melee = false
	attack_timer.stop()
	velocity = Vector2.ZERO
	anim.play("die")
	await anim.animation_finished
	
# lache loot sprint
	var loot = sprint_loot_scene.instantiate()
	get_parent().add_child(loot)
	loot.global_position = spawnpoint.global_position
	
	queue_free()

# --- Zones ---
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		in_melee = true
		if not is_dead:
			attack()
			attack_timer.start()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false
		attack_timer.stop()
