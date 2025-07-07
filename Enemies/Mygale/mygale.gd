extends CharacterBody2D

@export var max_hp: int = 400
@export var speed: int = 200
@export var attack_range: int = 1000
@export var cooldown: float = 1.5
@export var damage: int = 200

@onready var health_bar = $HealthBar/ProgressBar
@onready var anim_sprite = $AnimatedSprite
@onready var muzzle = $FlipNode/Muzzle
@onready var timer = $Timer
@onready var scene_camera 

const GRAVITY: int = 2000

var can_shoot := true
var is_attacking := false
var has_shot := false
var frozen := false
var stone_coco := false
var pv := max_hp
var player: Node2D

var DeathEffect = preload("res://Effects/enemy_death_particles.tscn") 
var BaveFlac = preload("res://Loot/bave_flaque_static.tscn")
var projectile = preload("res://Tir/toile.tscn")
var ToilePlafond = preload("res://Effects/plafonds.tscn")


func _ready() -> void:
	while scene_camera == null:
		await get_tree().process_frame
		scene_camera = get_viewport().get_camera_2d()
	
	print("📷 Caméra détectée :", scene_camera.name)
	
	pv = max_hp
	
	find_and_bind_player()
	
	anim_sprite.frame_changed.connect(shoot_projectile)

	# Phase d'apparition suspendue
	await play_plafond_intro()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or is_attacking:
		return

	apply_gravity(delta)

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

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0

func play_plafond_intro() -> void:
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
	var player_camera := player.get_node_or_null("Camera2D")
	if player_camera:
		print("✔ Camera2D trouvé !!! ")
		player_camera.make_current()
	# 🧭 Recentrer la caméra manuellement sur le joueur
		await get_tree().process_frame  # attendre que make_current prenne effet
		player_camera.global_position = player.global_position
	else:
		print("❌ Camera2D du joueur introuvable !")

func attack_and_shoot() -> void:
	can_shoot = false
	is_attacking = true
	has_shot = false
	anim_sprite.play("attaque")

	var frames = anim_sprite.sprite_frames.get_frame_count("attaque")
	var speed = anim_sprite.sprite_frames.get_animation_speed("attaque")
	var anim_duration = frames / speed

	await get_tree().create_timer(anim_duration).timeout
	is_attacking = false

func shoot_projectile() -> void:
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

func on_hit(damage_taken: int) -> void:
	pv -= damage_taken
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv
	show_damage_popup(damage_taken)

func show_damage_popup(amount: int) -> void:
	var popup = preload("res://ItemsDecors/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)
	popup.show_damage(amount)
	if pv <= 0:
		die()

func die() -> void:
	print("🕷️ L'araignée est morte.")
	visible = false
	set_physics_process(false)

	var particles = DeathEffect.instantiate()
	particles.global_position = global_position
	get_parent().add_child(particles)

	var cpu_particles = particles.get_node("CPUParticles2D")
	cpu_particles.emitting = true

	await wait_for_particles_to_finish(cpu_particles)

	var bave = BaveFlac.instantiate()
	bave.global_position = global_position + Vector2(0, 10)
	get_tree().current_scene.add_child(bave)

	queue_free()

func wait_for_particles_to_finish(p: CPUParticles2D) -> void:
	while p.emitting:
		await get_tree().process_frame

func stone() -> void:
	if stone_coco:
		return
	stone_coco = true
	set_physics_process(false)
	timer.stop()
	anim_sprite.play("stone")

	var frames = anim_sprite.sprite_frames.get_frame_count("stone")
	var speed = anim_sprite.sprite_frames.get_animation_speed("stone")
	var anim_duration = frames / speed

	await get_tree().create_timer(anim_duration).timeout
	set_physics_process(true)
	timer.start()
	stone_coco = false

func freeze() -> void:
	if frozen:
		return
	frozen = true
	set_physics_process(false)
	timer.stop()
	anim_sprite.play("slide")

	var frames = anim_sprite.sprite_frames.get_frame_count("slide")
	var speed = anim_sprite.sprite_frames.get_animation_speed("slide")
	var anim_duration = frames / speed

	var direction = -sign(velocity.x)
	if direction == 0:
		direction = -1
	var slide_distance = 100.0
	var slide_speed = slide_distance / anim_duration
	var elapsed := 0.0
	while elapsed < anim_duration:
		var delta := get_process_delta_time()
		position.x += direction * slide_speed * delta
		await get_tree().process_frame
		elapsed += delta

	set_physics_process(true)
	timer.start()
	frozen = false

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player: Node) -> void:
	player = new_player

func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and not is_attacking:
		velocity.x = 0
		await attack_and_shoot()
		if body.has_method("on_hit"):
			body.on_hit(damage)
