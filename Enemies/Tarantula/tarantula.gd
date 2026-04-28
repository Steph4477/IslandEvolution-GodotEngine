extends CharacterBody2D

@export var max_hp = 300
@export var speed = 70
@export var attack_range = 1000
@export var cooldown = 2
@export var damage = 50

@onready var health_bar = $HealthBar/ProgressBar
@onready var anim_sprite = $AnimatedSprite
@onready var muzzle = $FlipNode/Muzzle
@onready var timer = $Timer
@onready var scene_camera

const GRAVITY = 2000

var can_shoot = true
var is_attacking = false
var has_shot = false
var frozen = false
var stone_coco = false
var pv = 0
var player = null

var is_dead = false
var death_requested = false

var DeathEffect = preload("res://Enemies/Tarantula/effects/enemy_death_particles.tscn")
var projectile = preload("res://Shoot/Enemies/Web/web.tscn")
var ToilePlafond = preload("res://Enemies/Tarantula/effects/descent.tscn")
var ramp_loot = preload("res://Player/Skills/Ramp/ramp.tscn")

func _ready():
	while scene_camera == null:
		await get_tree().process_frame
		scene_camera = get_viewport().get_camera_2d()

	pv = max_hp
	find_and_bind_player()

	anim_sprite.frame_changed.connect(shoot_projectile)

	# Phase d'apparition suspendue
	await play_plafond_intro()

func _physics_process(delta):
	if is_dead:
		return

	if not is_instance_valid(player) or is_attacking:
		return

	apply_gravity(delta)

	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * speed

	# flip sans ternaire
	if direction.x > 0:
		anim_sprite.flip_h = true
		$FlipNode.scale.x = -1
	else:
		anim_sprite.flip_h = false
		$FlipNode.scale.x = 1

	# anim sans ternaire
	if velocity.x != 0:
		anim_sprite.play("walk")
	else:
		anim_sprite.play("idle")

	var target = null
	if player and player.has_node("TurnAxis"):
		target = player.get_node("TurnAxis")

	var distance = 999999
	if target:
		distance = global_position.distance_to(target.global_position)
	else:
		distance = global_position.distance_to(player.global_position)

	if distance < attack_range and can_shoot:
		velocity.x = 0
		await attack_and_shoot()

	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

func play_plafond_intro():
	visible = false
	set_physics_process(false)

	# 1. Centrer temporairement la caméra sur la mygale
	scene_camera.global_position = global_position

	# 2. Ajouter la toile qui descend
	var effet_toile = ToilePlafond.instantiate()
	effet_toile.global_position = global_position + Vector2(0, -354)
	get_parent().add_child(effet_toile)

	# 3. Attendre la fin de l'effet
	await effet_toile.finished_descente

	# 4. Réactiver la mygale
	global_position += Vector2(0, 250)
	visible = true
	set_physics_process(true)

	# 5. Restituer le contrôle de la caméra au joueur
	var player_camera = player.get_node_or_null("Camera2D")
	if player_camera:
		player_camera.make_current()
		await get_tree().process_frame
		player_camera.global_position = player.global_position

func attack_and_shoot():
	if is_dead:
		return

	can_shoot = false
	is_attacking = true
	has_shot = false
	anim_sprite.play("attaque")

	var frames = anim_sprite.sprite_frames.get_frame_count("attaque")
	var anim_speed = anim_sprite.sprite_frames.get_animation_speed("attaque")
	var anim_duration = frames / anim_speed

	await get_tree().create_timer(anim_duration).timeout
	is_attacking = false

func shoot_projectile():
	if is_dead:
		return

	if anim_sprite.animation != "attaque":
		return

	var current_frame = anim_sprite.frame
	var total_frames = anim_sprite.sprite_frames.get_frame_count("attaque")

	if current_frame == total_frames - 1 and not has_shot:
		has_shot = true

		var instance = projectile.instantiate()
		get_parent().add_child(instance)
		instance.global_position = muzzle.global_position

		# direction sans ternaire
		if anim_sprite.flip_h:
			instance.direction = Vector2.RIGHT
		else:
			instance.direction = Vector2.LEFT

		await get_tree().create_timer(cooldown).timeout
		can_shoot = true

func on_hit(damage_taken):
	if is_dead:
		return

	pv -= damage_taken

	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv

	show_damage_popup(damage_taken)

func show_damage_popup(amount):
	var popup = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -500)
	popup.show_damage(amount)

	if pv <= 0:
		request_die()

# ✅ IMPORTANT : on ne tue JAMAIS direct dans un flush de physique
func request_die():
	if death_requested:
		return
	death_requested = true
	call_deferred("_do_die")

func _do_die():
	if is_dead:
		return
	is_dead = true

	visible = false
	set_physics_process(false)
	set_process(false)

	var particles = DeathEffect.instantiate()
	particles.global_position = global_position
	get_parent().add_child(particles)

	var cpu_particles = particles.get_node("CPUParticles2D")
	cpu_particles.emitting = true

	# loot ramp
	var loot = ramp_loot.instantiate()
	loot.global_position = global_position
	get_parent().add_child(loot)

	queue_free()

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player

# ⚠️ Renomme aussi le signal dans l’inspecteur (ancien: _on_Area2D_body_entered)
func _on_area_2d_body_entered(body):
	if is_dead:
		return

	if body.is_in_group("Player") and not is_attacking:
		velocity.x = 0
		await attack_and_shoot()
		if body.damage_mod and body.damage_mod.has_method("on_hit"):
			body.damage_mod.on_hit(damage)
