extends CharacterBody2D

# ========================== RÉGLAGES ==========================
@export var bone_scene = preload("res://Shoot/Enemies/Bone/bone.tscn")
@export var bone_loot_scene = preload("res://Loot/Bone/bone_loot.tscn")

@export var max_hp = 600
@export var speed = 200
@export var attack_range = 300      # distance pour le cac (horizontale)
@export var bone_range = 600        # distance pour le jet d'os (horizontale)
@export var damage = 50
@export var bone_cooldown = 1.0
@export var attack_cooldown = 0.6
@export var jump_velocity = -600.0

# --- Charge sauvage ---
@export var charge_speed = 600.0           # vitesse pendant la charge
@export var charge_min_range = 250.0       # distance mini pour déclencher (horizontale)
@export var charge_max_range = 600.0       # distance maxi pour déclencher (horizontale)
@export var charge_duration = 0.6          # durée de la charge (en secondes)
@export var charge_cooldown = 2.5          # temps avant de pouvoir recharger

# --- Poussière de charge ---
var dust_scene = preload("res://Enemies/Cannibal/Effects/dust_charge.tscn")
var dust_instance = null

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var rotator = $Rotator
@onready var attack_timer = $CacTimer
@onready var bone_timer = $BoneTimer
@onready var dust_origin = $Rotator/DustOrigin

var pv = 0
var player = null
var cam = null

var in_melee = false
var is_attacking = false
var is_dead = false
var is_jumping = false

# --- Charge state ---
var is_charging = false
var charge_dir = 0
var charge_time = 0.0
var charge_cooldown_left = 0.0

var base_scale_x = 0.0
var dx = 0.0
var distance = 0.0          # distance totale (si besoin un jour)
var horiz_distance = 0.0    # distance horizontale comme pour le croco

# --- Apparition depuis la hutte ---
var has_appeared = false        # tant que false, l'IA est bloquée

# suivi pour détecter le début de saut de Moko
var player_prev_on_floor = true

# =============================================================
#                         READY
# =============================================================
func _ready():
	pv = max_hp
	health_bar.max_value = max_hp
	health_bar.value = pv
	
	find_player()
	base_scale_x = rotator.scale.x
	
	attack_timer.one_shot = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.stop()
	
	bone_timer.one_shot = true
	bone_timer.stop()

# =============================================================
#                      PHYSICS PROCESS
# =============================================================
func _physics_process(delta):
	apply_gravity(delta)
	
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Tant que le chef n'a pas "apparu", IA(physique) bloqué
	if not has_appeared:
		move_and_slide()
		return
	
	# cooldown de la charge
	if charge_cooldown_left > 0.0:
		charge_cooldown_left -= delta
	
	# Saut synchronisé avec Moko
	sync_jump_with_player()
	
	# Si on est en pleine attaque (CàC ou tir), il ne bouge pas
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if is_instance_valid(player):
		target()

		# Camouflage : pas de target => idle + stop
		if horiz_distance >= 999999:
			velocity.x = 0
			if anim.current_animation != "idle":
				anim.play("idle")
			move_and_slide()
			return

		flip(dx)

		
		# Essaye de lancer une charge si possible
		maybe_start_charge()
		
		if is_charging:
			# Mouvement de charge : tout droit vers Moko
			velocity.x = charge_dir * charge_speed
			charge_time -= delta
			
			# Poussière suit toujours DustOrigin (qui flip avec Rotator)
			if dust_instance and is_instance_valid(dust_origin):
				dust_instance.global_position = dust_origin.global_position
				dust_instance.scale.x = rotator.scale.x
			
			if charge_time <= 0.0:
				is_charging = false
				charge_cooldown_left = charge_cooldown
				velocity.x = 0
				clear_dust()
		else:
			move_and_anim()
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")
	
	# Lancer d'os à distance, hors mêlée et hors charge
	if not is_dead and not is_attacking and not is_charging:
		# même logique que le croco : on se base sur la distance horizontale
		if not in_melee and horiz_distance > attack_range and horiz_distance <= bone_range:
			if bone_timer.is_stopped():
				bone_attack()
	
	move_and_slide()

# =============================================================
#                  CIBLE / ORIENTATION
# =============================================================
func target():
	if player == null:
		return

	# Camouflage : TurnAxis supprimé => plus de cible
	if not player.has_node("TurnAxis"):
		dx = 0
		distance = 999999
		horiz_distance = 999999
		return

	var target_pos = player.get_node("TurnAxis").global_position
	var to_target = target_pos - global_position
	dx = to_target.x
	distance = to_target.length()
	horiz_distance = abs(dx)


func flip(_dx):
	if dx > 1:
		rotator.scale.x = base_scale_x
	elif dx < -1:
		rotator.scale.x = -base_scale_x

# =============================================================
#               MOUVEMENT + ANIMATION
# =============================================================
func move_and_anim():
	# 🔒 Si saut en cours, on ne touche pas à l'anim
	if is_jumping:
		return
	
	# 🔒 Si charge en cours, on ne touche pas à l'anim ici
	if is_charging:
		return
	
	# 1) En mêlée : on laisse attack_melee gérer l'anim
	if in_melee:
		velocity.x = 0
		return
	
	# 2) Trop loin horizontalement -> il ne détecte pas Moko, reste idle
	if horiz_distance > bone_range:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")
		return
	
	# 3) Sinon on marche vers Moko (comme le croco)
	if dx > 0:
		velocity.x = speed
		if anim.current_animation != "walk":
			anim.play("walk")
	elif dx < 0:
		velocity.x = -speed
		if anim.current_animation != "walk":
			anim.play("walk")
	else:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")

# =============================================================
#                         GRAVITÉ
# =============================================================
func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += GRAVITY * delta

# =============================================================
#                     GAME STATE / PLAYER
# =============================================================
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

# ====================== SAUT SYNCHRONISÉ ======================
func sync_jump_with_player():
	if player == null:
		return
	
	var p_on_floor = player.is_on_floor()
	var player_started_jump = player_prev_on_floor and not p_on_floor and player.velocity.y < 0
	player_prev_on_floor = p_on_floor

	# 🔽 Si le cannibale retouche le sol, il n'est plus en saut
	if is_on_floor() and is_jumping:
		is_jumping = false

	# 🔼 Si le joueur commence un saut, on saute aussi
	if player_started_jump and is_on_floor() and not is_dead and not is_attacking:
		is_jumping = true
		velocity.y = jump_velocity
		anim.play("jump")

# ====================== CHARGE SAUVAGE ========================
func maybe_start_charge():
	# conditions générales
	if is_dead:
		return
	if is_attacking:
		return
	if is_jumping:
		return
	if in_melee:
		return
	if is_charging:
		return
	if charge_cooldown_left > 0.0:
		return
	
	# distance horizontale pour déclencher la charge (comme le croco)
	if horiz_distance < charge_min_range:
		return
	if horiz_distance > charge_max_range:
		return
	
	# On lance la charge
	is_charging = true
	charge_time = charge_duration
	
	charge_dir = 1
	if rotator.scale.x < 0:
		charge_dir = -1
	
	velocity.y = 0
	anim.play("run")
	spawn_dust()

# ======================== POUSSIÈRE ===========================
func spawn_dust():
	if dust_instance != null:
		dust_instance.queue_free()
		dust_instance = null
	
	dust_instance = dust_scene.instantiate()
	get_parent().add_child(dust_instance)
	
	if is_instance_valid(dust_origin):
		dust_instance.global_position = dust_origin.global_position
	
	dust_instance.scale.x = rotator.scale.x
	
	if dust_instance.has_node("AnimationPlayer"):
		dust_instance.get_node("AnimationPlayer").play("fade")

func clear_dust():
	if dust_instance:
		dust_instance.queue_free()
		dust_instance = null

# =============================================================
#                         ATTAQUES
# =============================================================
func attack_melee():
	# CàC en boucle tant qu'on reste en melee
	if is_dead or is_attacking:
		return
	
	is_attacking = true
	velocity.x = 0
	
	while in_melee and not is_dead:
		# Lancer anim CàC
		anim.play("cac")
		
		# Attendre la fin de l'animation
		await anim.animation_finished
		
		# Si on est mort ou plus en mêlée, on sort
		if is_dead or not in_melee:
			break
		
		# Appliquer les dégâts à Moko
		if is_instance_valid(player):
			player.damage_mod.on_hit(damage)
		
		# Petit cooldown entre deux frappes
		var t = get_tree().create_timer(attack_cooldown)
		await t.timeout
	
	is_attacking = false

func bone_attack():
	if is_dead or is_attacking:
		return
	
	is_attacking = true
	velocity.x = 0
	anim.play("attack")
	await anim.animation_finished
	if is_dead:
		return
	
	# Si il est au cac, on annule le tir (on se base sur la distance horizontale)
	if in_melee or horiz_distance <= attack_range:
		is_attacking = false
		return
	
	var bone = bone_scene.instantiate()
	get_parent().add_child(bone)
	
	var dir_x = 1
	if rotator.scale.x < 0:
		dir_x = -1
	
	var muzzle = rotator.get_node("Muzzle")
	if muzzle:
		bone.global_position = muzzle.global_position
	else:
		bone.global_position = global_position
	
	bone.direction = Vector2(dir_x, 0)
	bone.max_distance = bone_range
	
	is_attacking = false
	bone_timer.start(bone_cooldown)

# =============================================================
#                 DOMMAGES / MORT
# =============================================================
func on_hit(damage_taken):
	if is_dead:
		return
	if not anim.is_playing() or anim.current_animation != "onhit":
		anim.play("onhit")
	
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
	bone_timer.stop()
	is_attacking = false
	is_charging = false
	clear_dust()
	velocity = Vector2.ZERO
	if cam:
		cam.offset = Vector2.ZERO
	anim.play("die")
	await anim.animation_finished
	
	# lache loot os 
	var loot = bone_loot_scene.instantiate()
	get_parent().add_child(loot)
	loot.global_position = global_position 
	
	queue_free()

# =============================================================
#                    ZONES DE MÊLÉE
# =============================================================
func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		in_melee = true
		# si on était en charge, on la stoppe
		is_charging = false
		charge_time = 0.0
		clear_dust()
		velocity = Vector2.ZERO
		
		# On démarre la boucle d'attaques CàC si pas déjà en cours
		if not is_attacking and not is_dead:
			attack_melee()

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		in_melee = false
		attack_timer.stop()

# =============================================================
#                     TIMERS / CADENCEMENT
# =============================================================
func _on_bone_timer_timeout():
	if is_dead:
		return
	if in_melee:
		return
	# Basé sur la distance horizontale pour le tir
	if not is_attacking and horiz_distance > attack_range and horiz_distance <= bone_range:
		bone_attack()
	else:
		bone_timer.stop()

# =============================================================
#                   DÉTECTION APPARITION
# =============================================================
func _on_detect_area_body_entered(body):
	if body.is_in_group("Player") and not has_appeared:
		anim.play("appear")
		await anim.animation_finished
		has_appeared = true
