extends CharacterBody2D

# ========================== RÉGLAGES ==========================
@export var move_speed = 300.0
@export var melee_damage = 20
@export var gravity = 1000.0

# ============================ LOOT ============================
var loot_lance_scene = preload("res://Loot/lance/lance.tscn")

# ============================ NODES ===========================
@onready var rig = $Rig
@onready var anim = $Rig/AnimationPlayer
@onready var melee_zone = $Rig/MeleeZone
@onready var cac_zone = $Rig/CacZone
@onready var health_bar = $HealthBar/ProgressBar

# ============================= ÉTAT ===========================
var player = null
var in_melee_active = false
var in_cac_active = false
var is_attacking = false
var can_flip = true
var facing = 1
var base_scale_x = 1.0

var max_pv = 200
var pv = 200
var hit_locked = false
var hit_lock_time = 0.20
var is_dead = false

# ============================ READY ===========================
func _ready():
	base_scale_x = abs(rig.scale.x)
	var gs = get_node("/root/GameState")
	player = gs.player
	gs.connect("player_updated", Callable(self, "on_player_changed"))

func on_player_changed(p):
	player = p

# ======================= BOUCLE PHYSIQUE ======================
func _physics_process(delta):
	if is_dead:
		return

	face_player()
	
	# Gravité
	if not is_on_floor():
		velocity.y += gravity * delta

	# Pendant le onhit : fige et n'écrase pas l'anim
	if hit_locked:
		velocity.x = 0
		move_and_slide()
		return


	# Appels des états
	in_cac()
	in_melee()

	# Idle uniquement si aucun état
	if not in_cac_active and not in_melee_active and not is_attacking:
		velocity.x = 0
		move_and_slide()

# ======================== FONCTIONS D'ÉTAT ====================
func in_cac():
	if in_cac_active:
		# Ne pas écraser une anim en cours
		if is_attacking or hit_locked:
			return
		if not is_attacking:
			cac_attack()
		velocity.x = 0
		move_and_slide()

func in_melee():
	if in_melee_active:
		# Ne pas écraser une anim en cours
		if is_attacking or hit_locked:
			return
		var dir_x = sign(player.global_position.x - global_position.x)
		velocity.x = dir_x * move_speed
		move_and_slide()
		anim.play("walk")

# ========================= ORIENTATION ========================
func face_player():
	if not can_flip or is_attacking or is_dead:
		return
	var dx = player.global_position.x - global_position.x
	if dx < 0 and facing != -1:
		facing = -1
		rig.scale.x = -base_scale_x
	elif dx > 0 and facing != 1:
		facing = 1
		rig.scale.x = base_scale_x

# ========================= DÉPLACEMENT ========================
func walk_towards_player():
	if is_attacking or is_dead:
		return
	var dir_x = sign(player.global_position.x - global_position.x)
	velocity.x = dir_x * move_speed
	move_and_slide()
	anim.play("walk")


# ========================= CORPS À CORPS ======================
func cac_attack():
	# Si le coup tue Moko, on ferme la CacZone tout de suite (évite le "double décès")
	if player.is_dead:
		in_cac_active = false
		return
	if is_attacking:
		return

	is_attacking = true
	#anim.play("cac")

	velocity.x = 0
	move_and_slide()

	player.on_hit(melee_damage)
	await get_tree().create_timer(0.6).timeout

	is_attacking = false

# ============================ ZONES ===========================
func _on_melee_zone_body_entered(_body):
	in_melee_active = true
	can_flip = false

func _on_melee_zone_body_exited(_body):
	in_melee_active = false
	if not in_cac_active:
		can_flip = true

func _on_cac_zone_body_entered(_body):
	if in_cac_active:
		return
	in_cac_active = true
	can_flip = false

func _on_cac_zone_body_exited(_body):
	in_cac_active = false
	# pas de flip tant qu'on est dans la CacZone
	if in_cac_active:
		return

# ========================= VIE / DÉGÂTS =======================
func on_hit(amount):
	if is_dead or hit_locked:
		return

	pv -= amount
	if health_bar:
		health_bar.max_value = max_pv
		health_bar.value = pv
	show_damage_popup(amount)

	hit_locked = true
	#anim.play("onhit")
	await get_tree().create_timer(hit_lock_time).timeout
	hit_locked = false

func show_damage_popup(amount: int) -> void:
	var popup_scene := preload("res://ItemsDecors/damage_popup.tscn")
	var popup: Label = popup_scene.instantiate()
	health_bar.add_child(popup)
	popup.show_damage(amount)

	if pv <= 0:
		die()

# ============================= MORT ===========================
func die():
	if is_dead:
		return
	is_dead = true

	# Anim de mort (si présente)
	#if anim:
		##anim.play("die")
		#await anim.animation_finished

	# Spawn du loot lance
	spawn_loot_lance()

	# On supprime enfin le pyg
	queue_free()

func spawn_loot_lance():
	# Instantie le loot 
	var loot = loot_lance_scene.instantiate()

	get_tree().current_scene.add_child(loot)

	# Apparition à l’endroit où meurt le pyg 
	loot.global_position = global_position
