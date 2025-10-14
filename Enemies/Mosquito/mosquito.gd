extends CharacterBody2D

@export var max_hp = 20
@export var speed = 200
@export var attack_range = 500
@export var attack_contact_radius = 24.0
@export var cooldown = 1.5
@export var damage = 200
@export var patrol_speed = 80
@export var patrol_change_interval = 2.0

@onready var health_bar = $HealthBar/ProgressBar
@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

var is_patrolling = true
var is_attacking = false
var patrol_direction = Vector2.ZERO
var pv = max_hp
var is_dead = false
var player

func _ready():
	pv = max_hp
	find_and_bind_player()
	start_patrol()

func _physics_process(_delta):
	if is_dead:
		return

	if not is_instance_valid(player):
		return

	var target = player.get_node("TurnAxis").global_position
	var distance = global_position.distance_to(target)

	# Chasse ou patrouille
	if distance <= attack_range:
		is_patrolling = false
		var direction = (target - global_position).normalized()
		velocity = direction * speed
	else:
		is_patrolling = true
		velocity = patrol_direction * patrol_speed

	# Flip du sprite
	if velocity.x != 0:
		sprite.scale.x = abs(sprite.scale.x) if velocity.x < 0 else -abs(sprite.scale.x)

	# Animations de déplacement (hors attaque)
	if not is_attacking:
		if is_patrolling:
			if anim.current_animation != "patrol":
				anim.play("patrol")
		else:
			if anim.current_animation != "flight":
				anim.play("flight")
	move_and_slide()

	# Détection d'attaque au contact
	if distance <= attack_contact_radius and not is_attacking:
		await _perform_attack(player)

func _perform_attack(target):
	is_attacking = true
	velocity = Vector2.ZERO
	anim.play("attaque")

	if target.has_method("on_hit"):
		target.on_hit(damage)

	await anim.animation_finished
	await get_tree().create_timer(cooldown).timeout
	is_attacking = false
	anim.play("flight")

func change_patrol_direction():
	var angle = randf() * TAU
	patrol_direction = Vector2(cos(angle), sin(angle)).normalized()

func start_patrol():
	change_patrol_direction()
	timer.wait_time = patrol_change_interval
	timer.start()

func _on_timer_timeout():
	if is_patrolling:
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

	await get_tree().process_frame  # Assure que tout est bien chargé

	# 🎬 Joue l'animation "die"
	anim.play("die")

	# ⏱️ Calcule la durée de l'animation "die"
	var anim_duration = anim.get_animation("die").length

	# 🔁 Attend la fin exacte de l'animation
	await get_tree().create_timer(anim_duration).timeout

	queue_free()

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player

func _on_area_2d_body_entered(body):
	if body.has_method("on_hit"):
		body.on_hit(damage)
