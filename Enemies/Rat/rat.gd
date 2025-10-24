extends CharacterBody2D

@export var max_hp = 300
@export var speed = 800
@export var attack_range = 1000
@export var stop_distance = 60
@export var cooldown = 1.0
@export var damage = 100

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator

var pv = 0
var player = null
var is_attacking = false
var in_melee = false
var attack_timer = null

func _ready():
	pv = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv
	find_and_bind_player()
	
	attack_timer = Timer.new()
	attack_timer.one_shot = false
	attack_timer.wait_time = cooldown
	add_child(attack_timer)
	attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))

func _physics_process(delta):
	apply_gravity(delta)

	if is_instance_valid(player) and not is_attacking:
		var target_pos = player.global_position
		var turn_axis = player.get_node_or_null("TurnAxis")
		if turn_axis:
			target_pos = turn_axis.global_position

		var to_target = target_pos - global_position
		var distance = to_target.length()

		# Flip du Rotator entier
		if distance > 1:
			if to_target.x > 0:
				rotator.scale.x = abs(rotator.scale.x)
			else:
				rotator.scale.x = -abs(rotator.scale.x)

		# Avance jusqu'à proximité, sinon stop
		if distance < attack_range and abs(to_target.x) > stop_distance:
			var direction = to_target.normalized()
			velocity.x = direction.x * speed
		else:
			velocity.x = 0
	else:
		velocity.x = 0

	# Stop net si collision latérale
	if is_on_wall():
		velocity.x = 0

	move_and_slide()

func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += GRAVITY * delta

# ============================ COMBAT ============================
func _on_attack_timer_timeout():
	if not in_melee:
		return
	if not is_instance_valid(player):
		return
	if is_attacking:
		return
	_do_attack_tick()

func _do_attack_tick():
	is_attacking = true
	velocity.x = 0
		
	if anim.has_animation("attack"):
		anim.play("attack")
		
	# Applique les dégâts réguliers à Moko (comme le croco mais sans one-shot)
	_apply_attack_damage()
	
	is_attacking = false

func _apply_attack_damage():
	if not is_instance_valid(player):
		return
	if player.has_method("on_hit"):
		player.on_hit(damage)

# ============================ DÉGÂTS RAT =========================
func on_hit(damage_taken):
	pv -= damage_taken
	if health_bar:
		if pv < 0:
			health_bar.value = 0
		else:
			health_bar.value = pv
	show_damage_popup(damage_taken)
	if pv <= 0:
		die()

func show_damage_popup(amount):
	var scene = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn")
	var popup = scene.instantiate()
	add_child(popup)
	popup.position = Vector2(0, -500)
	popup.show_damage(amount)

func die():
	anim.play("die")
	await get_tree().create_timer(0.8).timeout
	queue_free()

# ========================= PLAYER BIND ===========================
func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player

# ============================ ZONES ==============================
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		in_melee = true
		if attack_timer.is_stopped():
			attack_timer.start()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player")or body.name == "Player":
		in_melee = false
		attack_timer.stop()
		is_attacking = false
