extends CharacterBody2D

@export var max_hp = 400
@export var speed = 200
@export var attack_range = 500
@export var cooldown = 1.5
@export var damage = 200
@export var patrol_speed = 80
@export var patrol_change_interval = 2.0

@onready var health_bar = $HealthBar/ProgressBar
@onready var muzzle = $FlipNode/Muzzle
@onready var timer = $Timer
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

const GRAVITY = 2000

var is_patrolling = true
var is_patrol_paused = false
var patrol_direction = Vector2.ZERO
var can_shoot = true
var is_attacking = false
var has_shot = false
var is_dead = false
var pv = max_hp
var player
var projectile = preload("res://Shoot/Enemies/Gaz/gaz.tscn")
var custom_velocity = Vector2.ZERO

func _ready():
	pv = max_hp
	find_and_bind_player()
	start_patrol()

func _physics_process(delta):
	if not is_instance_valid(player) or is_attacking or is_dead:
		return

	apply_gravity(delta)

	var target = player.get_node("TurnAxis").global_position
	var distance = global_position.distance_to(target)

	if distance <= attack_range:
		is_patrolling = false
		var direction = (target - global_position).normalized()
		custom_velocity.x = direction.x * speed
	else:
		is_patrolling = true
		if is_patrol_paused:
			custom_velocity.x = 0
		else:
			custom_velocity.x = patrol_direction.x * patrol_speed

	# Flip du sprite
	if custom_velocity.x < 0:
		sprite.scale.x = abs(sprite.scale.x)
		$FlipNode.position.x = -abs($FlipNode.position.x)
	elif custom_velocity.x > 0:
		sprite.scale.x = -abs(sprite.scale.x)
		$FlipNode.position.x = abs($FlipNode.position.x)

	# Attaque 
	if distance <= attack_range and can_shoot:
		custom_velocity.x = 0
		await attack_and_shoot()

	set_velocity(custom_velocity)

	# Animations
	if not is_attacking:
		if is_patrolling:
			if is_patrol_paused:
				if anim.current_animation != "idle":
					anim.play("idle")
			else:
				if anim.current_animation != "patrol":
					anim.play("patrol")
		else:
			if anim.current_animation != "walk":
				anim.play("walk")

	move_and_slide()
	custom_velocity = velocity

func change_patrol_direction():
	is_patrol_paused = true
	custom_velocity.x = 0
	anim.play("idle")

	await get_tree().create_timer(2.0).timeout  # Pause avant direction

	is_patrol_paused = false
	var direction = randf_range(-1.0, 1.0)
	patrol_direction = Vector2(direction, 0).normalized()

func start_patrol():
	change_patrol_direction()
	timer.wait_time = patrol_change_interval
	timer.start()

func _on_timer_timeout():
	if is_patrolling:
		change_patrol_direction()

func apply_gravity(delta):
	if not is_on_floor():
		custom_velocity.y += GRAVITY * delta
	else:
		custom_velocity.y = 0

func attack_and_shoot():
	can_shoot = false
	is_attacking = true
	has_shot = false

	anim.play("attaque")
	await anim.animation_finished

	shoot_projectile()
	is_attacking = false

func shoot_projectile():
	if has_shot:
		return
	has_shot = true

	var instance = projectile.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = muzzle.global_position
	instance.direction = Vector2.LEFT if sprite.scale.x > 0 else Vector2.RIGHT

	await get_tree().create_timer(cooldown).timeout
	can_shoot = true

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

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("on_hit"):
		body.on_hit(damage)
