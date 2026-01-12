extends CharacterBody2D

@export var damage_taken = 1
@export var max_hp = 20
@export var speed = 400
@export var orbit_speed_factor = 0.6
@export var attack_contact_radius = 24.0
@export var damage = 20
@export var cooldown = 2

# ---- Séparation simple (anti-collage) ----
@export var separation_radius = 70.0     # distance mini entre abeilles
@export var separation_force = 260.0     # force de repousse

@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

var pv = 2
var is_dead = false
var player
var is_attacking = false

# ---- var mis en à jour une frame par une frame (verrou) ----
static var hit_locked = false

func _ready():
	add_to_group("Bee")
	find_and_bind_player()
	anim.play("flight")

func _physics_process(_delta):
	if is_dead:
		return

	if not is_instance_valid(player):
		return

	var target = player.get_node("TurnAxis").global_position
	var distance = global_position.distance_to(target)
	var direction = (target - global_position).normalized()

	# --- Déplacement principal ---
	if distance > attack_contact_radius:
		velocity = direction * speed
	else:
		var tangent = Vector2(-direction.y, direction.x)
		velocity = tangent * speed * orbit_speed_factor

		if not is_attacking:
			_perform_attack(player)

	# --- Séparation (anti-collage) ---
	var separation = separation_bee()
	if separation != Vector2.ZERO:
		velocity += separation

	move_and_slide()

	# Flip du sprite
	if velocity.x != 0:
		if velocity.x < 0:
			sprite.scale.x = abs(sprite.scale.x)
		else:
			sprite.scale.x = -abs(sprite.scale.x)

func separation_bee():
	var push = Vector2.ZERO
	var bees = get_tree().get_nodes_in_group("Bee")

	for b in bees:
		if b == self:
			continue

		var d = global_position.distance_to(b.global_position)
		if d > 0 and d < separation_radius:
			var away = (global_position - b.global_position).normalized()
			var strength = (separation_radius - d) / separation_radius
			push += away * (separation_force * strength)

	return push

func _perform_attack(target):
	is_attacking = true
	anim.play("attack")

	if target.has_method("on_hit"):
		target.on_hit(damage)

	await get_tree().create_timer(cooldown).timeout

	is_attacking = false

	if not is_dead:
		anim.play("flight")

func on_hit(_damage_taken):
	if is_dead:
		return

	# Un seul hit accepté pour tout l'essaim sur cette frame
	if hit_locked:
		return
	hit_locked = true
	call_deferred("unlock_new_hit")

	# 1 coup = 1 PV en moins
	pv -= 1

	show_damage_popup(1)

	if pv <= 0:
		die()

func unlock_new_hit():
	hit_locked = false

func show_damage_popup(amount):
	var popup = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)
	popup.show_damage(amount)

func die():
	if is_dead:
		return

	is_dead = true
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

func _on_area_2d_body_entered(body):
	if body.has_method("on_hit"):
		body.on_hit(damage)
