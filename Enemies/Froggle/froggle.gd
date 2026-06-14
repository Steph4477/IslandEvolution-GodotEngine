extends CharacterBody2D

@export var max_hp = 600
@export var speed = 200
@export var attack_range = 300
@export var drool_range = 800
@export var stop_distance = 40
@export var damage = 50
@export var drool_scene = preload("res://Enemies/Froggle/Drool/drool_bolt.tscn")
@export var double_jump_loot_scene = preload("res://Player/Skills/DoubleJump/double_jump.tscn")

@export var drool_cooldown = 1.6
@export var attack_cooldown = 1.0
@export var jump_attack_interval = 5.0

# --- Réglages du tremblement caméra et dégâts ---
@export var quake_intensity = 70.0   # Intensité du shake de caméra
@export var quake_duration = 3.0     # Durée du tremblement
@export var quake_damage = 50       # Dégâts par seconde pendant la secousse

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator
@onready var attack_timer = $CacTimer
@onready var drool_timer = $DroolTimer
@onready var jump_timer = $JumpTimer
@onready var spawn_point = $Rotator/LootSpawn

var pv = 0
var player = null
var cam = null
var in_melee = false
var is_drooling = false
var is_dead = false
var is_attacking = false
var is_jumping = false
var is_quaking = false
var base_scale_x = 0.0
var dx = 0.0
var distance = 0.0

func _ready():
	pv = max_hp
	health_bar.max_value = max_hp
	health_bar.value = pv
	find_player()
	base_scale_x = rotator.scale.x
	
	attack_timer.one_shot = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.stop()
	
	drool_timer.one_shot = true
	drool_timer.stop()
	
	jump_timer.one_shot = false
	jump_timer.wait_time = jump_attack_interval
	jump_timer.start()

func _physics_process(delta):
	apply_gravity(delta)
	
	if is_dead or is_jumping or is_quaking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if is_attacking or is_drooling:
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
		
	if not is_dead and not is_attacking and not is_drooling and not is_jumping and not is_quaking:
		if not in_melee and distance > attack_range and distance <= drool_range:
			if drool_timer.is_stopped():
				drool_attack()
		
	move_and_slide()

# --- Cible / Flip ---
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

# --- Mouvement / animation ---
func move_and_anim():
	if in_melee or is_drooling:
		velocity.x = 0
		if not is_attacking and anim.current_animation != "idle":
			anim.play("idle")
		return

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
	if player:
		cam = player.get_node("Camera2D")
	gs.connect("player_updated", Callable(self, "on_player_changed"))

func on_player_changed(new_player):
	player = new_player
	if player:
		cam = player.get_node("Camera2D")

# --- Attaques ---
func attack_melee():
	if is_dead or is_attacking or is_jumping or is_drooling or is_quaking:
		return
	is_attacking = true
	velocity.x = 0
	anim.play("attack")
	if not is_dead and is_instance_valid(player):
		player.damage_mod.on_hit(damage)
	await anim.animation_finished
	if is_dead:
		return
	is_attacking = false

func drool_attack():
	if is_dead or is_attacking or is_jumping or is_quaking:
		return
	is_attacking = true
	is_drooling = true
	velocity.x = 0
	$DroolSound.play()
	anim.play("drool")
	await anim.animation_finished
	if is_dead:
		return
	if in_melee or distance <= attack_range or is_jumping or is_quaking:
		is_attacking = false
		is_drooling = false
		return
		
	var bolt = drool_scene.instantiate()
	get_parent().add_child(bolt)
	var dir_x = 1
	if rotator.scale.x < 0:
		dir_x = -1
		
	var muzzle = rotator.get_node("Muzzle")
	if muzzle:
		bolt.global_position = muzzle.global_position
	else:
		bolt.global_position = global_position
		
	bolt.direction = Vector2(dir_x, 0)
	bolt.max_distance = drool_range
		
	is_attacking = false
	is_drooling = false
	drool_timer.start(drool_cooldown)

# --- Jump Attack ---
func jump_attack():
	if is_dead or is_jumping or is_quaking or distance > drool_range:
		return
		
	is_attacking = false
	is_drooling = false
	if not drool_timer.is_stopped():
		drool_timer.stop()
	attack_timer.stop()
		
	# 1) Pause 2s rouge
	is_jumping = true
	velocity = Vector2.ZERO
	sprite.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(2.0).timeout
	if is_dead or distance > drool_range:
		sprite.modulate = Color(1, 1, 1)
		is_jumping = false
		return
		
	# 2) Jump anim
	anim.play("jump_attack")
	await anim.animation_finished
	if is_dead or distance > drool_range:
		sprite.modulate = Color(1, 1, 1)
		is_jumping = false
		return
		
	sprite.modulate = Color(1, 1, 1)
	is_jumping = false
		
	# 3) Tremblement uniquement si Moko dans la drool_range
	if distance <= drool_range and not is_dead:
		is_quaking = true
		await shake_and_damage_player(quake_intensity, quake_duration)
		is_quaking = false
		
	if is_dead:
		return
		
	# Reprise normale
	if drool_timer.is_stopped():
		drool_timer.start(drool_cooldown)
	if in_melee and attack_timer.is_stopped():
		attack_timer.start()

# --- Camera shake + dégâts ---
func shake_and_damage_player(intensity, duration):
	if is_dead:
		return
	if distance <= drool_range:
		camera_shake(intensity, duration)
	await damage_player_over_time(duration, quake_damage, 1.0)

func camera_shake(intensity, duration):
	if cam == null or is_dead:
		return
	var t = create_tween()
	var steps = int(duration / 0.1)
	for i in range(steps):
		if is_dead:
			break
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		t.tween_property(cam, "offset", offset, 0.05)
	t.tween_property(cam, "offset", Vector2.ZERO, 0.1)

func damage_player_over_time(total_duration, dmg_per_sec, interval):
	if player == null:
		return

	var counter_sec = int(total_duration / interval)

	for i in range(counter_sec):
		if is_dead:
			return

		if is_instance_valid(player):
			# Pas de dégâts si Moko est en saut
			if player.is_jumping:
				var t0 = get_tree().create_timer(interval)
				await t0.timeout
				continue

			if distance <= drool_range:
				player.damage_mod.on_hit(dmg_per_sec)

		var timer = get_tree().create_timer(interval)
		await timer.timeout


# --- Dommage et mort ---
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
	drool_timer.stop()
	jump_timer.stop()
	is_attacking = false
	is_drooling = false
	is_jumping = false
	is_quaking = false
	velocity = Vector2.ZERO

	if cam:
		cam.offset = Vector2.ZERO

	call_deferred("drop_double_jump_loot")
	
	var gs = get_node("/root/GameState")
	gs.toucan_froggle_spawned = false
	gs.toucan_challenge_done = true
	gs.respawn_point_name = "SpawnPoint2"

	anim.play("die")
	await anim.animation_finished

	queue_free()

func drop_double_jump_loot():
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.double_jump_unlocked:
		return
	
	var loot = double_jump_loot_scene.instantiate()
	get_parent().add_child(loot)
	loot.global_position = spawn_point.global_position

# --- ZONES ---
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		in_melee = true
		velocity = Vector2.ZERO
		if attack_timer.is_stopped():
			attack_timer.start()
		if not is_dead and not is_attacking and not is_jumping and not is_quaking:
			attack_melee()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false
		attack_timer.stop()

# --- Cadencement ---
func _on_cac_timer_timeout():
	if in_melee and not is_dead and not is_attacking and not is_drooling and not is_jumping and not is_quaking:
		attack_melee()

func _on_drool_timer_timeout():
	if is_dead or is_jumping or is_quaking:
		return
	if in_melee:
		return
	if not is_attacking and distance > attack_range and distance <= drool_range:
		drool_attack()
	else:
		drool_timer.stop()

func _on_jump_timer_timeout():
	if not is_dead and not is_jumping and not is_quaking:
		jump_attack()
