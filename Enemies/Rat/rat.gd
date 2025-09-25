extends CharacterBody2D

# ========================== RÉGLAGES ==========================
@export var move_speed = 300.0
@export var melee_damage = 20
@export var gravity = 2000.0
@export var attack_range = 1000.0   # distance max pour poursuite
@export var attack_cooldown = 0.6

# ============================ NODES ===========================
@onready var rig = $Rig
@onready var anim = $Rig/AnimationPlayer
@onready var cac_zone = $Rig/CacZone
@onready var health_bar = $HealthBar/ProgressBar

# ============================= ÉTAT ===========================
var player = null
var in_cac_active = false
var is_attacking = false
var base_scale_x = 1.0
var is_dead = false
var pv = 200
var max_pv = 200

# ============================ READY ===========================
func _ready():
	base_scale_x = abs(rig.scale.x)
	var gs = get_node("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(p):
	player = p

# ======================= BOUCLE PHYSIQUE ======================
func _physics_process(delta):
	if is_dead or not is_instance_valid(player):
		return

	apply_gravity(delta)

	var distance = global_position.distance_to(player.global_position)

	if in_cac_active:
		cac_attack()
	elif distance <= attack_range:
		chase_player()
	else:
		velocity.x = 0
		if not is_attacking:
			anim.play("idle")

	move_and_slide()

# ========================= DÉPLACEMENT ========================
func chase_player():
	if is_attacking:
		return

	var dx = player.global_position.x - global_position.x
	var direction_x = 0

	# ✅ Deadzone pour éviter le spam de flip quand Moko est trop proche
	if dx < -32:
		direction_x = -1
	elif dx > 32:
		direction_x = 1
	else:
		direction_x = 0  # trop près → on garde la direction actuelle

	velocity.x = direction_x * move_speed

	# ✅ Flip seulement si on est en dehors de la deadzone
	if not is_attacking:
		if direction_x == -1 and rig.scale.x != -base_scale_x:
			rig.scale.x = -base_scale_x
		elif direction_x == 1 and rig.scale.x != base_scale_x:
			rig.scale.x = base_scale_x

	if not is_attacking and direction_x != 0:
		anim.play("walk")
	elif not is_attacking:
		anim.play("idle")


# ========================= ATTAQUE ============================
func cac_attack():
	if is_attacking or is_dead:
		return
	
	is_attacking = true
	velocity.x = 0
	anim.play("cac")

	# Délai avant d’infliger les dégâts
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(player):
		player.on_hit(melee_damage)

	# Cooldown avant de réattaquer
	await get_tree().create_timer(attack_cooldown).timeout
	is_attacking = false

# ============================ ZONES ===========================
func _on_cac_zone_body_entered(body):
	if body.is_in_group("Player"):
		in_cac_active = true

func _on_cac_zone_body_exited(body):
	if body.is_in_group("Player"):
		in_cac_active = false

# ========================= GRAVITÉ ============================
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

# ========================= VIE / DÉGÂTS =======================
func on_hit(amount):
	if is_dead:
		return
	pv -= amount
	if health_bar:
		health_bar.max_value = max_pv
		health_bar.value = pv
	if pv <= 0:
		die()

# ============================= MORT ===========================
func die():
	if is_dead:
		return
	is_dead = true
	anim.play("die")
	await get_tree().create_timer(0.5).timeout
	queue_free()
