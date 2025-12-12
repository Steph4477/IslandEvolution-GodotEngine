extends CharacterBody2D

@export var max_hp = 20
@export var speed = 400
@export var orbit_speed_factor = 0.6

@export var attack_contact_radius = 24.0
@export var damage = 200
@export var cooldown = 2

@onready var health_bar = $HealthBar/ProgressBar
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite

var pv = max_hp
var is_dead = false
var player
var is_attacking = false    # gère le cooldown

func _ready():
	pv = max_hp
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
	
	# --- Déplacement ---
	if distance > attack_contact_radius:
		# Poursuite directe tant qu'on est loin
		velocity = direction * speed
	else:
		# Au contact : Orbite autour de Moko 
		var tangent = Vector2(-direction.y, direction.x)  # vecteur perpendiculaire
		velocity = tangent * speed * orbit_speed_factor
	
		# On pique dès qu'on est dans la zone, avec cooldown
		if not is_attacking:
			_perform_attack(player)
	
	move_and_slide()
	
	# Flip du sprite 
	if velocity.x != 0:
		if velocity.x < 0:
			sprite.scale.x = abs(sprite.scale.x)
		else:
			sprite.scale.x = -abs(sprite.scale.x)

func _perform_attack(target):
	is_attacking = true
	anim.play("attack")
	
	if target.has_method("on_hit"):
		target.on_hit(damage)
	
	# Cooldown entre deux piqûres
	await get_tree().create_timer(cooldown).timeout
	
	is_attacking = false
	
	if not is_dead:
		anim.play("flight")

func on_hit(damage_taken):
	pv -= damage_taken
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv
	
	show_damage_popup(damage_taken)
	
	if pv <= 0:
		die()

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
