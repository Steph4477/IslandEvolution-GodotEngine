extends CharacterBody2D

@export var max_hp = 400
@export var speed = 200
@export var attack_range = 1000
@export var cooldown = 1.5
@export var damage = 200

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
var pv = max_hp
var player
var DeathEffect = preload("res://Effects/enemy_death_particles.tscn") 
var projectile = preload("res://Tir/toile.tscn")
var ToilePlafond = preload("res://Effects/plafonds.tscn")
var ramp_loot_scene = preload("res://Loot/ramp.tscn")

func _ready():
	while scene_camera == null:
		await get_tree().process_frame
		scene_camera = get_viewport().get_camera_2d()
		
	pv = max_hp
	find_and_bind_player()
	anim_sprite.frame_changed.connect(shoot_projectile)
	
	# Phase d'apparition suspendue
	await play_plafond_intro()

func _physics_process(_delta):
	if not is_instance_valid(player) or is_attacking:
		return
	
	apply_gravity(_delta)
	
	var direction = (player.global_position - global_position).normalized()
	velocity.x = direction.x * speed
	
	anim_sprite.flip_h = direction.x > 0
	$FlipNode.scale.x = -1 if anim_sprite.flip_h else 1
	
	anim_sprite.play("walk" if velocity.x != 0 else "idle")
	
	var target = player.get_node("TurnAxis").global_position
	var distance = global_position.distance_to(target)
	
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
	# 🧭 Recentrer la caméra manuellement sur le joueur
	await get_tree().process_frame
	player_camera.global_position = player.global_position

func attack_and_shoot():
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
	if anim_sprite.animation == "attaque":
		var current_frame = anim_sprite.frame
		var total_frames = anim_sprite.sprite_frames.get_frame_count("attaque")
		
		if current_frame == total_frames - 1 and not has_shot:
			has_shot = true
			var instance = projectile.instantiate()
			get_parent().add_child(instance)
			instance.global_position = muzzle.global_position
			instance.direction = Vector2.RIGHT if anim_sprite.flip_h else Vector2.LEFT
			await get_tree().create_timer(cooldown).timeout
			can_shoot = true

func on_hit(damage_taken):
	pv -= damage_taken
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv
	show_damage_popup(damage_taken)

func show_damage_popup(amount):
	var popup = preload("res://ItemsDecors/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -500)
	popup.show_damage(amount)
	if pv <= 0:
		die()

func die():
	visible = false
	set_physics_process(false)
	
	var particles = DeathEffect.instantiate()
	particles.global_position = global_position
	get_parent().add_child(particles)

	var cpu_particles = particles.get_node("CPUParticles2D")
	cpu_particles.emitting = true
	
	# lache loot pour ramper 
	var loot = ramp_loot_scene.instantiate()
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

func _on_Area2D_body_entered(body):
	if body.is_in_group("Player") and not is_attacking:
		velocity.x = 0
		await attack_and_shoot()
		if body.has_method("on_hit"):
			body.on_hit(damage)
