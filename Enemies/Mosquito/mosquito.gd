extends CharacterBody2D

@export var max_hp = 20
@export var speed = 200
@export var attack_range = 2000
@export var attack_contact_radius = 24.0
@export var cooldown = 0.8
@export var damage = 200
@export var patrol_speed = 80
@export var patrol_change_interval = 2.0

# --- ORBITE AVANT PIQÛRE ---
@export var orbit_radius_x = 90.0
@export var orbit_radius_y = 55.0
@export var orbit_angular_speed = 6.0
@export var orbit_duration = 1.2

# --- MICRO-OSCILLATIONS (STYLE MOUSTIQUE) ---
@export var osc_radial_amplitude = 6.0
@export var osc_radial_frequency = 10.0
@export var osc_angle_amplitude = 0.12
@export var osc_angle_frequency = 7.0

@onready var health_bar = $HealthBar/ProgressBar
@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

const PHASE_PATROL = 0
const PHASE_ORBIT = 1
const PHASE_DIVE = 2

var phase = PHASE_PATROL

var patrol_direction = Vector2.ZERO
var pv = 0
var is_dead = false
var player
var is_attacking = false

var orbit_angle = 0.0
var orbit_time_left = 0.0
var osc_time = 0.0

func _ready():
	pv = max_hp
	find_and_bind_player()
	start_patrol()

func _physics_process(delta):
	if is_dead:
		return

	if not is_instance_valid(player):
		return

	# cible : TurnAxis (comme ton code)
	var target = player.get_node("TurnAxis").global_position
	var distance = global_position.distance_to(target)

	# -------------------------------------------------
	# SORTIE COMBAT -> RETOUR PATROUILLE
	# -------------------------------------------------
	if distance > attack_range:
		phase = PHASE_PATROL
		orbit_time_left = 0.0

		velocity = patrol_direction * patrol_speed

		if not is_attacking:
			if anim.current_animation != "patrol":
				anim.play("patrol")

		_flip_from_velocity()
		move_and_slide()
		return

	# -------------------------------------------------
	# ENTREE COMBAT : PATROL -> ORBIT
	# -------------------------------------------------
	if phase == PHASE_PATROL:
		phase = PHASE_ORBIT
		orbit_time_left = orbit_duration
		osc_time = 0.0
		orbit_angle = (global_position - target).angle()

	# -------------------------------------------------
	# ORBIT
	# -------------------------------------------------
	if phase == PHASE_ORBIT and not is_attacking:
		orbit_time_left -= delta
		orbit_angle += orbit_angular_speed * delta
		osc_time += delta

		var wobble_angle = sin(osc_time * TAU * osc_angle_frequency) * osc_angle_amplitude
		var a = orbit_angle + wobble_angle

		# micro “respiration” radiale (gonfle/rétrécit l’ellipse)
		var radial_boost = 1.0 + sin(osc_time * TAU * osc_radial_frequency) * (osc_radial_amplitude / orbit_radius_x)

		var rx = orbit_radius_x * radial_boost
		var ry = orbit_radius_y * radial_boost

		var orbit_pos = target + Vector2(cos(a) * rx, sin(a) * ry)
		var dir_orbit = (orbit_pos - global_position).normalized()
		velocity = dir_orbit * speed

		if anim.current_animation != "flight":
			anim.play("flight")

		if orbit_time_left <= 0.0:
			phase = PHASE_DIVE

	# -------------------------------------------------
	# DIVE (fonce pour piquer)
	# -------------------------------------------------
	if phase == PHASE_DIVE and not is_attacking:
		var direction = (target - global_position).normalized()
		velocity = direction * speed

		if anim.current_animation != "flight":
			anim.play("flight")

	# Déplacement
	_flip_from_velocity()
	move_and_slide()

	# Recalcule distance APRÈS move (plus fiable pour déclencher la piqûre)
	distance = global_position.distance_to(target)

	# Déclenchement piqûre uniquement en phase DIVE
	if phase == PHASE_DIVE and distance <= attack_contact_radius and not is_attacking:
		await _perform_attack(player)
		phase = PHASE_ORBIT
		orbit_time_left = orbit_duration
		osc_time = 0.0
		orbit_angle = (global_position - target).angle()

func _perform_attack(target):
	is_attacking = true
	anim.play("attack")

	if target.damage_mod.has_method("on_hit"):
		target.damage_mod.on_hit(damage)

	await get_tree().create_timer(cooldown).timeout
	is_attacking = false

	if not is_dead:
		anim.play("flight")

func _flip_from_velocity():
	if velocity.x == 0:
		return

	if velocity.x < 0:
		sprite.scale.x = abs(sprite.scale.x)
	else:
		sprite.scale.x = -abs(sprite.scale.x)

func change_patrol_direction():
	var angle = randf() * TAU
	patrol_direction = Vector2(cos(angle), sin(angle)).normalized()

func start_patrol():
	change_patrol_direction()
	timer.wait_time = patrol_change_interval
	timer.start()

func _on_timer_timeout():
	if phase == PHASE_PATROL:
		change_patrol_direction()

func on_hit(damage_taken):
	pv -= damage_taken
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv
	show_damage_popup(damage_taken)

func show_damage_popup(amount):
	var popup = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)
	popup.show_damage(amount)
	if pv <= 0:
		die()

func die():
	if is_dead:
		return
	is_dead = true

	await get_tree().process_frame

	anim.play("die")
	var anim_duration = anim.get_animation("die").length
	await get_tree().create_timer(anim_duration).timeout
	queue_free()

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player
