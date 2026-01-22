extends CharacterBody2D

# ============================================================================
#                  VARIABLES, CONSTANTES, EXPORTS, NODES
# ============================================================================
const INPUT = {
	"jump": "jump",
	"left": "ui_left",
	"right": "ui_right",
	"down": "ui_down",
	"fire": "shoot",
	"fire_lance": "shoot_spear",
	"heal": "heal",
	"ramp": "ramping",
	"clac": "clacing",
	"sprint": "sprint",
	"camouflage": "camouflage"
}

@export var speed = 400
@export var jump_force = -800
@export var gravity = 1200
@export var climb_speed = 100
@export var clac_damage = 100
@export var max_pv = 2000
@export var pv = max_pv
@export var cooldown_potion = 10
@export var heal_amount = 50  # défini dans GameState
@export var total_seeds_in_level = 10

# --- Dégâts de chute ---
@export var fall_damage_enabled = true
@export var fall_safe_limit = 1200        # en dessous => 0 dégât
@export var fall_speed_max = 1800             # à partir de là => dégâts max
@export var fall_damage_max = 600             # dégâts max appliqués
@export var fall_damage_min = 50              # si on dépasse le seuil, au moins ça

# --- Suivie vitesse de chute ---
var fall_speed_track = 0.0

var spell_coco = preload("res://Shoot/Player/Coconut/coconut.tscn")
var spell_bone = preload("res://Shoot/Player/Bone/bone.tscn")
var spell_lance = preload("res://Shoot/Player/Spear/spear.tscn")

var game_state
var collect_items
var collect_skills
var can_move = true
var can_be_damaged = true
var is_dead = false
var animation_locked = false

var climbing_anim = ""
var can_climb = false
var is_hanging = false
var hang_timer = 0.0
var can_ramp = false
var is_ramping = false

# --- Nage sur et sous l'eau ---
var water_current = Vector2(-120, 0)
var can_swim = false
var is_swimming = false
var can_swim_under_water = false
var is_swimming_under_water = false
var swim_speed_x = 150
var swim_speed_y = 110
var swim_timer = 0.0

# --- Respiration sous l'eau ---
@export var max_breath = 30
@export var panic_start = 15
@export var drown_damage_per_second = 500

@export var bubble_interval_normal = 1
@export var bubble_interval_min = 0.06

@export var mouth_show_time = 0.2


var breath_left = 0
var is_underwater = false

var air_bubble_scene = preload("res://Effects/Aquatic_breathing/Air_bubble/air_bubble.tscn")

# --- Skills ---
var can_sprint = false
var is_sprinting = false
var ramp_locked = false
var is_gazed = false
var is_web = false
var can_fire_coco = false
var can_fire_bone = false
var can_fire_lance = false
var rate_of_fire = 0.4
var is_attacking = false

# --- Camouflage ---
var can_camouflage = false
@export var camouflage_duration = 5.0
var is_camouflaged = false

var turn_axis_parent = null
var turn_axis_index = 0

# --- Jump and double jump ---
var jump_buffer = 0.0
var did_double_jump = false
var jump_count = 0
var max_jump_count = 1
var gravity_factor = 1.0

# --- collecte ---
var coco_count = 0
var bone_count = 0
var banane_count = 0
var honey_count = 0
var seed_count = 0
var lance_count = 0

# Potions séparées
var heal_potions = []     # bananes
var honey_potions = []    # miel

var in_cooldown = false
var can_heal = true
var is_in_cooldown = false
var is_on_liana = false
var current_liana = null

# --- Caisse ---
var can_push_pull = false
var is_pushing_or_pulling = false

# --- Nodes ---
@onready var sprite = $Node2D/Sprite
@onready var anim = $Node2D/Anim
@onready var camera = $Camera2D
@onready var air_bubble_spawn = $AirBubbleSpawn
@onready var breath_tick_timer = $BreathTickTimer
@onready var bubble_timer = $BubbleTimer
@onready var turn_axis = $TurnAxis
@onready var drown_timer = $DrownTimer
@onready var open_mouth = $Node2D/OpenMouth
@onready var close_mouth = $Node2D/Sprite

# --- HUD Labels (non utilisés directement pour l'affichage, désormais géré par le HUD) ---
var label_banane
var label_coco
var label_bone
var label_seed


# =======================================================================
#                        ULTILITAIRES
# =======================================================================

func play_anim(_name):
	anim.play(_name)
	animation_locked = true
	await anim.animation_finished
	animation_locked = false

func show_info_popup(txt):
	var popup = get_tree().get_first_node_in_group("info_overlay_group")
	if popup == null:
		popup = preload("res://Interface/Popup/Info_popup/info_popup.tscn").instantiate()
		add_child(popup)
	popup.show_info(txt)

func show_damage_popup(amount):
	var popup = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)
	popup.show_damage(amount)


# =======================================================================
#                       INITIALISATION
# =======================================================================

func _ready():
	setup_game_state()

	setup_collect_items()

	setup_collect_skills()

	camera.make_current()

	await get_tree().process_frame
	setup_hud()
	await get_tree().process_frame

	if game_state and game_state.hud and game_state.hud.has_method("update_seed_display"):
		game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)

	if anim.current_animation == "hang":
		anim.play("idle")
	is_hanging = false
	climbing_anim = ""
	
	# --- Restaure la dernière positon connue de Moko aprés un chargement de partie sauvegardée ---
	_restore_loaded_position_post_setup()


func _restore_loaded_position_post_setup():
	var gs = get_node("/root/GameState")
	if gs.has_pending_load:
		await get_tree().process_frame
		global_position = gs.pending_player_pos
		gs.has_pending_load = false


func setup_game_state():
	game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return

	game_state.set_player(self)

	banane_count = game_state.banane_count
	honey_count = game_state.honey_count

	coco_count = game_state.coco_count
	bone_count = game_state.bone_count
	lance_count = game_state.lance_count

	# Aligné sur la logique GameState
	seed_count = game_state.collected_seeds

	can_fire_coco = game_state.can_fire_coco
	can_fire_lance = game_state.can_fire_lance
	can_fire_bone = game_state.can_fire_bone
	can_camouflage = game_state.can_camouflage

	can_ramp = game_state.ramp_unlocked
	can_sprint = game_state.sprint_unlocked

	# Recrée les listes (important après respawn / reload)
	heal_potions.clear()
	for i in range(banane_count):
		heal_potions.append(game_state.heal_amount)

	honey_potions.clear()
	for j in range(honey_count):
		honey_potions.append(game_state.heal_amount)

	max_jump_count = 1
	if game_state.double_jump_unlocked:
		max_jump_count = 2

func setup_collect_items():
	collect_items = preload("res://Player/Modules/PlayerCollectItems/PlayerCollectItems.gd").new()
	add_child(collect_items)
	collect_items.setup(self)

func setup_collect_skills():
	collect_skills = preload("res://Player/Modules/PlayerCollectSkills/PlayerCollectSkills.gd").new()
	add_child(collect_skills)
	collect_skills.setup(self)
	
func setup_hud():
	if not game_state:
		return
	if not game_state.hud:
		return


	# Le HUD gère l'affichage via ses méthodes update
	if game_state.hud.has_method("update_lives_display"):
		game_state.hud.update_lives_display(game_state.lives)

	update_all_displays()
	refresh_hud_buttons()


func _physics_process(delta):
	if not can_move:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")
		return

	if animation_locked:
		return
	
	var was_on_floor = is_on_floor() # Suivre si on est au sol à chaque frame 

	is_pushing_or_pulling = can_push_pull and Input.is_action_pressed("push_pull")

	process_climb()
	process_liana(delta)
	update_jump(delta)
	process_sprint()
	move_horizontal()
	process_ramp()
	process_swim(delta)
	process_swim_under_water(delta)
	process_shoot()
	process_clac()
	process_heal()
	process_camouflage()
	process_hang_swing(delta)

	track_fall_speed(was_on_floor)

	move_and_slide()

	apply_fall_damage(was_on_floor)

	process_wall_jump_input()
	update_animation()


# ============================================================================
#                           MOUVEMENTS
# ============================================================================
func move_horizontal():
	if is_on_liana:
		velocity.x = 0
		return

	var dir = Input.get_action_strength(INPUT["right"]) - Input.get_action_strength(INPUT["left"])
	var current_speed = speed
	if is_sprinting:
		current_speed = speed * 1.5

	velocity.x = dir * current_speed

	if dir != 0 and not is_pushing_or_pulling:
		if dir > 0:
			sprite.scale.x = abs(sprite.scale.x)
		else:
			sprite.scale.x = -abs(sprite.scale.x)

# --- Dégats de chute ---
func track_fall_speed(was_on_floor):
	if not fall_damage_enabled:
		return

	if is_swimming or is_swimming_under_water or is_on_liana or climbing_anim != "" or is_hanging or is_camouflaged:
		fall_speed_track = 0
		return

	if not was_on_floor:
		if velocity.y > fall_speed_track:
			fall_speed_track = velocity.y
	else:
		fall_speed_track = 0

func apply_fall_damage(was_on_floor):
	if not fall_damage_enabled:
		return
	if is_dead:
		return

	if not was_on_floor and is_on_floor():
		var impact_speed = fall_speed_track
		fall_speed_track = 0

		if impact_speed <= fall_safe_limit:
			return

		var dmg = fall_damage_min

		if impact_speed >= fall_speed_max:
			dmg = fall_damage_max
		else:
			var range_speed = fall_speed_max - fall_safe_limit
			var over_speed = impact_speed - fall_safe_limit
			dmg += (fall_damage_max - fall_damage_min) * over_speed / range_speed

		dmg = int(dmg)
		if dmg <= 0:
			return

		# Applique les dégâts + anim onhit 
		on_hit(dmg)

func update_jump(delta):
	# Bloque toute logique de saut sous l'eau (surface + underwater)
	if is_swimming or is_swimming_under_water:
		return

	if climbing_anim != "":
		return

	if is_on_floor():
		jump_count = 0

	max_jump_count = 1
	if game_state and game_state.double_jump_unlocked:
		max_jump_count = 2

	if Input.is_action_just_pressed(INPUT["jump"]) and jump_count < max_jump_count:
		velocity.y = jump_force
		is_ramping = false
		jump_count += 1

	if not is_on_floor():
		if not is_ramping:
			velocity.y += gravity * gravity_factor * delta


func process_wall_jump_input():
	if is_on_floor():
		return
	if is_on_liana:
		return
	if is_swimming or is_swimming_under_water:
		return

	if is_on_wall() and Input.is_action_just_pressed("jump"):
		wall_jump()


func wall_jump():
	var normal = get_wall_normal()
	var dir = -normal.x

	if dir == 0:
		if sprite.scale.x >= 0:
			dir = -1
		else:
			dir = 1

	velocity.y = jump_force
	velocity.x = dir * speed


func set_can_climb(state, anim_name = ""):
	if state:
		climbing_anim = anim_name
		anim.play("hang")
	else:
		climbing_anim = ""
		is_hanging = false
		velocity.y = 0
		anim.play("idle")


func start_climb(anim_name):
	climbing_anim = anim_name


func stop_climb():
	climbing_anim = ""
	is_hanging = false


func process_climb():
	if climbing_anim == "":
		if is_hanging:
			is_hanging = false
		return

	if Input.is_action_pressed("climb"):
		if not anim.is_playing() or anim.current_animation != climbing_anim:
			anim.play(climbing_anim)
		velocity.y = -climb_speed
		is_hanging = false

	elif Input.is_action_just_released("ui_up"):
		anim.play("hang")
		velocity.y = 0
		is_hanging = true

	elif not Input.is_action_pressed("ui_up"):
		velocity.y = 0


func process_hang_swing(delta):
	if is_hanging:
		hang_timer += delta
		var swing = sin(hang_timer * 2.0) * 5
		sprite.rotation_degrees = swing
	else:
		sprite.rotation_degrees = 0
		hang_timer = 0.0


func process_ramp():
	if can_ramp and Input.is_action_just_pressed(INPUT["ramp"]) and is_on_floor() and not ramp_locked:
		ramp_locked = true
		is_ramping = not is_ramping

		if is_ramping:
			show_info_popup("🧎 Rampe activée !")
			$ColStand.disabled = true
			$ColRamp.disabled = false
		else:
			show_info_popup("🚶 Rampe désactivée !")
			$ColStand.disabled = false
			$ColRamp.disabled = true

		await get_tree().create_timer(0.2).timeout
		ramp_locked = false

	if is_ramping:
		var rdir = Input.get_action_strength(INPUT["right"]) - Input.get_action_strength(INPUT["left"])
		velocity.x = rdir * speed * 0.4
		velocity.y += gravity * gravity_factor * get_physics_process_delta_time()


#func collect_sprint():
	#can_sprint = true
	#game_state.sprint_unlocked = true
	#game_state.sprint_stamina = game_state.sprint_stamina_max
#
	#if game_state.speed_bar:
		#game_state.speed_bar.visible = true
		#game_state.speed_bar.update_speed_bar_current(game_state.sprint_stamina)
#
	#if game_state.hud:
		#var hud = game_state.hud
		#if hud.has_node("Gamepad/Sprint"):
			#var btn = hud.get_node("Gamepad/Sprint")
			#btn.visible = true
			#hud.set_button_enabled(btn, true)
#
		#if hud.anim.has_animation("appear_sprint"):
			#hud.anim.play("appear_sprint")
#
	#show_info_popup("⚡ Tu peux maintenant sprinter avec Shift !")
	#refresh_hud_buttons()


func process_sprint():
	var delta = get_physics_process_delta_time()

	if not game_state:
		return

	if not game_state.sprint_unlocked:
		is_sprinting = false
		return

	if is_swimming or is_swimming_under_water or is_ramping or is_on_liana:
		is_sprinting = false
		if game_state.sprint_stamina < game_state.sprint_stamina_max:
			game_state.sprint_stamina += game_state.sprint_stamina_regen * delta
			if game_state.sprint_stamina > game_state.sprint_stamina_max:
				game_state.sprint_stamina = game_state.sprint_stamina_max
		game_state.speed_bar.update_speed_bar_current(game_state.sprint_stamina)
		return

	if Input.is_action_pressed(INPUT["sprint"]) and game_state.sprint_stamina > 0:
		is_sprinting = true
		game_state.sprint_stamina -= game_state.sprint_stamina_cost * delta
		if game_state.sprint_stamina <= 0:
			game_state.sprint_stamina = 0
			is_sprinting = false
	else:
		is_sprinting = false
		if game_state.sprint_stamina < game_state.sprint_stamina_max:
			game_state.sprint_stamina += game_state.sprint_stamina_regen * delta
			if game_state.sprint_stamina > game_state.sprint_stamina_max:
				game_state.sprint_stamina = game_state.sprint_stamina_max

	game_state.speed_bar.update_speed_bar_current(game_state.sprint_stamina)

# --- Nage ---
func process_swim(delta):
	if is_swimming:
		swim_timer += delta
		var h = Input.get_action_strength(INPUT["right"]) - Input.get_action_strength(INPUT["left"])
		velocity.x = h * speed * 0.5 + water_current.x
		velocity.y = 0

		if h != 0:
			if h > 0:
				sprite.scale.x = abs(sprite.scale.x)
			else:
				sprite.scale.x = -abs(sprite.scale.x)


func process_swim_under_water(delta):
	if is_swimming_under_water:
		swim_timer += delta
		var h = Input.get_action_strength(INPUT["right"]) - Input.get_action_strength(INPUT["left"])
		var v = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

		velocity.x = h * speed * 0.5 + water_current.x
		velocity.y = v * speed * 0.35

		if h != 0:
			if h > 0:
				sprite.scale.x = abs(sprite.scale.x)
			else:
				sprite.scale.x = -abs(sprite.scale.x)


# --- Réspiratioon sous l'eau ---
func start_underwater_breath():
	is_underwater = true
	breath_left = max_breath

	drown_timer.stop()
	update_bubble_rate()

	# Timer respiration (1 tick / seconde)
	if breath_tick_timer.is_stopped():
		breath_tick_timer.start()

	# Les bulles ne démarrent PAS au début
	bubble_timer.stop()

	# HUD
	game_state.hud.start_breath(max_breath)
	game_state.hud.update_breath(breath_left, max_breath)

func stop_underwater_breath(refill):
	is_underwater = false

	breath_tick_timer.stop()
	bubble_timer.stop()
	drown_timer.stop()

	if refill:
		breath_left = max_breath

	# HUD
	game_state.hud.stop_breath()
	game_state.hud.update_breath(breath_left, max_breath)


func _on_breath_tick_timer_timeout():
	if not is_underwater:
		return

	breath_left -= 1
	if breath_left < 0:
		breath_left = 0

	# HUD
	game_state.hud.update_breath(breath_left, max_breath)
	
	# Démarrage des bulles uniquement à partir de 15s restantes
	if breath_left == panic_start:
		update_bubble_rate()
		if bubble_timer.is_stopped():
			bubble_timer.start()

	if breath_left == 0:
		bubble_timer.stop()
		if drown_timer.is_stopped():
			drown_timer.start()
		return

	update_bubble_rate()

func _on_bubble_timer_timeout():
	if not is_underwater:
		return

	# Dès la noyade plus de bulles
	if not drown_timer.is_stopped():
		bubble_timer.stop()
		return
		
	if breath_left <= 0:
		bubble_timer.stop()
		return

	spawn_air_bubble()

func _on_drown_timer_timeout():
	if not is_underwater:
		return
	if breath_left > 0:
		drown_timer.stop()
		return

	bubble_timer.stop()
	on_hit(drown_damage_per_second)

func update_bubble_rate():
	if breath_left > panic_start:
		bubble_timer.wait_time = bubble_interval_normal
		return

	var t = float(panic_start - breath_left) / float(panic_start)
	if t < 0.0:
		t = 0.0
	if t > 1.0:
		t = 1.0

	var w = bubble_interval_normal - ((bubble_interval_normal - bubble_interval_min) * t)
	if w < bubble_interval_min:
		w = bubble_interval_min

	bubble_timer.wait_time = w

func spawn_air_bubble():
	# Stop net dès que l'air est à 0 
	if breath_left <= 0:
		return
	if not drown_timer.is_stopped():
		return

	var b = air_bubble_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = air_bubble_spawn.global_position

	# bouche ouverte pendant la noyade à chaque spawn de bulle
	if open_mouth:
		open_mouth.visible = true
		close_mouth.visible = false
		await get_tree().create_timer(mouth_show_time).timeout
		if open_mouth:
			open_mouth.visible = false
			close_mouth.visible = true

# --- Liane ---
func attach_to_liana(liana):
	is_on_liana = true
	current_liana = liana
	if current_liana.has_method("on_player_attach"):
		current_liana.on_player_attach()

	velocity = Vector2.ZERO
	hand_to_grip()
	anim.play("climb")


func detach_to_liana():
	is_on_liana = false
	current_liana = null


func process_liana(_delta):
	if not is_on_liana or current_liana == null or did_double_jump:
		return

	velocity = Vector2.ZERO
	hand_to_grip()

	var left = Input.is_action_pressed("ui_left")
	var right = Input.is_action_pressed("ui_right")
	if current_liana.has_node("Pivot"):
		if left:
			current_liana.angle_direction = 1
		elif right:
			current_liana.angle_direction = -1
		else:
			current_liana.angle_direction = 0

	if Input.is_action_just_pressed("jump"):
		var power = 900
		var angle_deg = current_liana.get_node("Pivot").rotation_degrees
		velocity = Vector2(0, -power).rotated(deg_to_rad(angle_deg))
		current_liana.expect_exit = true
		current_liana.on_player_detach()
		current_liana.disable_collision_temporarily(0.3)
		detach_to_liana()


func hand_to_grip():
	var grip = current_liana.get_node("Pivot/Grip")
	var hand = $Node2D/AttachMarker
	var delta = grip.global_position - hand.global_position
	global_position += delta

# --- Camouflage ---
func process_camouflage():
	if not can_camouflage:
		return
	if Input.is_action_just_pressed(INPUT["camouflage"]):
		use_camouflage()


# =================================================================================================
#                                     COLLECTES
# =================================================================================================
func use_honey():
	if not is_on_floor():
		return

	var msg = ""
	if pv >= max_pv:
		msg = "PV au max !"
	elif in_cooldown:
		msg = "⏳ Potion en recharge..."
	elif honey_potions.is_empty():
		msg = "Aucun miel !"

	if msg != "":
		show_info_popup(msg)
		await play_anim("empty")
		return

	await play_anim("heal")

	heal(game_state.heal_amount)

	if not honey_potions.is_empty():
		honey_potions.pop_front()

	honey_count = honey_potions.size()

	if game_state:
		game_state.honey_count = honey_count

	if game_state and game_state.hud and game_state.hud.has_method("update_honey_display"):
		game_state.hud.update_honey_display()

	in_cooldown = true
	update_can_heal()
	refresh_hud_buttons()
	start_potion_cooldown("honey")

func use_camouflage():
	if is_camouflaged:
		return
	if not game_state.camouflage_unlocked:
		return
	if game_state.camouflage_count <= 0:
		return

	# Consomme 1 charge
	game_state.camouflage_count -= 1
	if game_state.camouflage_count < 0:
		game_state.camouflage_count = 0

	# Etat global 
	game_state.can_camouflage = game_state.camouflage_unlocked and game_state.camouflage_count > 0
	can_camouflage = game_state.can_camouflage

	# HUD : update compteur
	if game_state.hud:
		game_state.hud.update_camouflage_display()

		# Déswitch auto si plus de charges
		if game_state.camouflage_count == 0:
			game_state.hud.switch_back_to_spear()

	refresh_hud_buttons()

	start_camouflage()

# =============================================================================
#                               ACTIONS
# =============================================================================

func shoot_coco():
	if is_swimming or is_swimming_under_water or is_ramping or is_hanging or is_on_liana or is_camouflaged:
		return

	coco_count = game_state.coco_count
	can_fire_coco = game_state.can_fire_coco

	if not can_fire_coco:
		return
	if coco_count <= 0:
		return

	coco_count -= 1
	can_fire_coco = coco_count > 0

	game_state.coco_count = coco_count
	game_state.can_fire_coco = can_fire_coco

	update_coco_display()

	animation_locked = true
	anim.play("shoot")
	await anim.animation_finished

	var spell = spell_coco.instantiate()
	var dir = 1
	if sprite.scale.x < 0:
		dir = -1
	spell.start($TurnAxis/CastPoint.global_position, dir)
	get_tree().current_scene.add_child(spell)

	animation_locked = false
	refresh_hud_buttons()
	await get_tree().create_timer(rate_of_fire).timeout


func shoot_bone():
	if is_swimming or is_swimming_under_water or is_ramping or is_hanging or is_on_liana or is_camouflaged:
		return

	bone_count = game_state.bone_count
	can_fire_bone = game_state.can_fire_bone

	if not can_fire_bone:
		return
	if bone_count <= 0:
		return

	bone_count -= 1
	can_fire_bone = bone_count > 0

	game_state.bone_count = bone_count
	game_state.can_fire_bone = can_fire_bone

	update_bone_display()

	animation_locked = true
	anim.play("shoot")
	await anim.animation_finished

	var spell = spell_bone.instantiate()
	var dir = 1
	if sprite.scale.x < 0:
		dir = -1
	spell.start($TurnAxis/CastPoint.global_position, dir)
	get_tree().current_scene.add_child(spell)

	animation_locked = false
	refresh_hud_buttons()
	await get_tree().create_timer(rate_of_fire).timeout


func shoot_lance():
	if can_camouflage:
		return
		
	if is_swimming or is_swimming_under_water or is_ramping or is_hanging or is_on_liana or is_camouflaged:
		return
		
	lance_count = game_state.lance_count
	can_fire_lance = game_state.can_fire_lance
		
	if not can_fire_lance:
		return
	if lance_count <= 0:
		return
		
	lance_count -= 1
	can_fire_lance = lance_count > 0
		
	game_state.lance_count = lance_count
	game_state.can_fire_lance = can_fire_lance

	update_lance_display()

	animation_locked = true
	anim.play("shoot_lance")
	await anim.animation_finished

	var spell = spell_lance.instantiate()
	var dir = 1
	if sprite.scale.x < 0:
		dir = -1
	spell.start($TurnAxis/CastPoint.global_position, dir)
	get_tree().current_scene.add_child(spell)

	animation_locked = false
	refresh_hud_buttons()
	await get_tree().create_timer(rate_of_fire).timeout


func process_shoot():
	if Input.is_action_pressed(INPUT["fire"]) and can_fire_coco:
		shoot_coco()
	if Input.is_action_pressed(INPUT["fire"]) and can_fire_bone:
		shoot_bone()
	if not can_camouflage and Input.is_action_pressed(INPUT["fire_lance"]) and can_fire_lance:
		shoot_lance()


func clac_attack():
	if not is_on_floor():
		return
	if is_attacking or is_dead:
		return

	is_attacking = true
	animation_locked = true
	anim.play("clac")

	$ClacArea.monitoring = true

	await anim.animation_finished

	$ClacArea.monitoring = false
	is_attacking = false
	animation_locked = false


func process_clac():
	if Input.is_action_just_pressed(INPUT["clac"]):
		clac_attack()


# --- Heal (banane clavier) ---
func heal(amount):
	pv = clamp(pv + amount, 0, max_pv)

	if game_state:
		game_state.health_bar.set_value(pv)
		game_state.banane_count = heal_potions.size()

	banane_count = heal_potions.size()
	update_banane_display()


func update_can_heal():
	can_heal = heal_potions.size() > 0 and pv < max_pv and not in_cooldown


func process_heal():
	if Input.is_action_just_pressed(INPUT["heal"]):
		use_heal_item()

# --- Choix entre le jus de banane et le miel ---
func use_heal_item():
	if game_state and game_state.hud:
		# Si le bouton Honey est visible, on est en mode miel
		if game_state.hud.has_node("Gamepad/Honey"):
			var honey_btn = game_state.hud.get_node("Gamepad/Honey")
			if honey_btn.visible:
				use_honey()
				return
	
	# Sinon on utilise le jus de banane
	use_banane()

func use_banane():
	if not is_on_floor():
		return
	
	var msg = ""
	if pv >= max_pv:
		msg = "PV au max !"
	elif in_cooldown:
		msg = "⏳ Potion en recharge..."
	elif heal_potions.is_empty():
		msg = "Aucune potion !"
	
	if msg != "":
		show_info_popup(msg)
		await play_anim("empty")
		return
	
	await play_anim("heal")
	
	heal(game_state.heal_amount)
	
	if not heal_potions.is_empty():
		heal_potions.pop_front()
	
	banane_count = heal_potions.size()
	
	if game_state:
		game_state.banane_count = banane_count
	
	update_banane_display()
	
	in_cooldown = true
	update_can_heal()
	refresh_hud_buttons()
	start_potion_cooldown("banane")

func start_potion_cooldown(item):
	in_cooldown = true
	
	var hud = null
	if game_state and game_state.health_bar:
		hud = game_state.health_bar.get_parent()
	
	if hud:
		if item == "banane":
			if hud.has_method("start_banane_cooldown"):
				hud.start_banane_cooldown(cooldown_potion)
		elif item == "honey":
			if hud.has_method("start_honey_cooldown"):
				hud.start_honey_cooldown(cooldown_potion)
	
	await get_tree().create_timer(cooldown_potion).timeout
	in_cooldown = false
	refresh_hud_buttons()

func disable_controls():
	can_move = false
	velocity = Vector2.ZERO

func enable_controls():
	can_move = true

func apply_gaz():
	if is_gazed:
		return
	is_gazed = true
	speed *= 0.2
	await get_tree().create_timer(3).timeout
	speed /= 0.2
	is_gazed = false

func apply_web_effect():
	if is_web:
		return
	is_web = true
	speed *= 0.5
	await get_tree().create_timer(10).timeout
	speed /= 0.5
	is_web = false

func kill_by_plant():
	visible = false

# --- Camouflage ---
func start_camouflage():
	is_camouflaged = true
	game_state.is_camouflaged = true

	# supprime le noeud de visé des ennemies
	turn_axis_parent = turn_axis.get_parent()
	turn_axis_index = turn_axis.get_index()
	turn_axis_parent.remove_child(turn_axis)


	# HUD : cercle = durée du camouflage
	if game_state.hud and game_state.hud.has_method("start_camouflage_cooldown"):
		game_state.hud.start_camouflage_cooldown(camouflage_duration)

	refresh_hud_buttons()

	# Effet visuel 
	sprite.modulate = Color(1, 1, 1, 0.35)

	await get_tree().create_timer(camouflage_duration).timeout
	stop_camouflage()


func stop_camouflage():
	is_camouflaged = false
	game_state.is_camouflaged = false

	turn_axis_parent.add_child(turn_axis)
	turn_axis_parent.move_child(turn_axis, turn_axis_index)


	# Retour visuel
	sprite.modulate = Color(1, 1, 1, 1)

	refresh_hud_buttons()

# ============================================================================
#                       DOMMAGES ET MORT
# ============================================================================
func on_hit(damage):
	if not can_be_damaged or is_dead:
		return
	
	can_be_damaged = false
	
	pv -= damage
	pv = clamp(pv, 0, max_pv)
	if game_state and game_state.health_bar:
		game_state.health_bar.set_value(pv)
	
	show_damage_popup(damage)
	update_can_heal()
	refresh_hud_buttons()
	
	var hud = game_state.health_bar.get_parent()
	if hud and hud.has_method("set_button_enabled"):
		var can_heal_btn = pv < max_pv and heal_potions.size() > 0 and not in_cooldown
		if hud.has_node("Gamepad/Health"):
			hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal_btn)
		
		var can_honey_btn = pv < max_pv and honey_potions.size() > 0 and not in_cooldown
		if hud.has_node("Gamepad/Honey"):
			hud.set_button_enabled(hud.get_node("Gamepad/Honey"), can_honey_btn)
	
	if pv <= 0:
		die()
		return
	
	play_anim("onhit")
	
	can_be_damaged = true

func die():
	if is_dead:
		return
	
	is_dead = true
	animation_locked = true
	anim.play("die")
	game_state.lose_life()
	
	if game_state.hud.has_method("update_lives_display"):
		game_state.hud.update_lives_display(game_state.lives)
	
	await anim.animation_finished
	
	is_dead = false
	modulate = Color(1, 1, 1, 1)
	await get_tree().process_frame
	
	var next_level = ""
	if game_state.is_game_over():
		next_level = "res://Menu/Game_over/game_over.tscn"
	else:
		next_level = game_state.current_level_path
	
	stop_underwater_breath(true)
	
	game_state.load_level(next_level)

func is_quake_safe():
	if not is_on_floor():
		return true
	return false

# ============================================================================
#                              ANIMATIONS
# ============================================================================
func update_animation():
	if animation_locked or is_dead:
		return

	if is_swimming_under_water:
		if anim.current_animation != "swim_under_water":
			anim.play("swim_under_water")
		return

	if is_swimming:
		if anim.current_animation != "swim":
			anim.play("swim")
		return

	if is_on_liana:
		return

	if is_hanging:
		return

	if climbing_anim != "" and velocity.y != 0:
		anim.play(climbing_anim)
		return

	if anim.current_animation == "hang":
		return

	if is_gazed:
		if anim.current_animation != "walk_gaz":
			anim.play("walk_gaz")
		return

	if is_on_floor() and is_sprinting and abs(velocity.x) > 0.1:
		if anim.current_animation != "sprint":
			anim.play("sprint")
		return

	if is_on_floor():
		if is_pushing_or_pulling and not is_ramping:
			anim.play("push")
			return

		if is_ramping:
			if abs(velocity.x) > 0.1:
				anim.play("ramp")
			else:
				anim.play("idle")
		else:
			if abs(velocity.x) > 0.1:
				if is_gazed:
					anim.play("walk_gaz")
				if is_web:
					anim.play("web_effect")
				else:
					anim.play("walk")
			else:
				anim.play("idle")
		return

	if velocity.y < 0:
		if jump_count > 1:
			anim.play("jump2_up")
		else:
			anim.play("jump_up")
	elif velocity.y > 0:
		if jump_count > 1:
			anim.play("jump2_down")
		else:
			anim.play("jump_down")

# =============================================================================
#                               HUD & Popups
# =============================================================================
func update_banane_display():
	if game_state.hud.has_method("update_banane_display"):
		game_state.hud.update_banane_display()

func update_honey_display():
	if game_state.hud.has_method("update_honey_display"):
		game_state.hud.update_honey_display()

func update_coco_display():
	if game_state.hud.has_method("update_coco_display"):
		game_state.hud.update_coco_display()

func update_bone_display():
	if game_state.hud.has_method("update_bone_display"):
		game_state.hud.update_bone_display()

func update_lance_display():
	if game_state.hud.has_method("update_lance_display"):
		game_state.hud.update_lance_display()

func update_seed_display():
	if game_state.hud.has_method("update_seed_display"):
		game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)

func update_all_displays():
	update_banane_display()
	update_honey_display()
	update_coco_display()
	update_bone_display()
	update_lance_display()
	update_seed_display()

func refresh_hud_buttons():
	if not game_state or not game_state.health_bar:
		return

	var hud_parent = game_state.health_bar.get_parent()
	if not hud_parent:
		return

	# Coco / Bone
	if hud_parent.has_node("Gamepad/Coco"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Coco"), can_fire_coco)

	if hud_parent.has_node("Gamepad/Bone"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Bone"), can_fire_bone)



	# Heal
	var can_heal_banana_btn = pv < max_pv and heal_potions.size() > 0 and not in_cooldown
	if hud_parent.has_node("Gamepad/Health"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Health"), can_heal_banana_btn)

	var can_heal_honey_btn = pv < max_pv and honey_potions.size() > 0 and not in_cooldown
	if hud_parent.has_node("Gamepad/Honey"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Honey"), can_heal_honey_btn)

	# Spear -> Camouflage (switch)
	if hud_parent.has_node("Gamepad/Spear"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Spear"), can_fire_lance and not can_camouflage)
	
	# Skills
	if hud_parent.has_node("Gamepad/Camouflage"):
		var can_btn = can_camouflage
		if game_state.is_camouflaged:
			can_btn = false
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Camouflage"), can_btn)


	if hud_parent.has_node("Gamepad/Ramp"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Ramp"), can_ramp)

	if hud_parent.has_node("Gamepad/Sprint"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Sprint"), can_sprint)


func reset_state():
	stop_underwater_breath(true)
	is_dead = false
	animation_locked = false
	visible = true

	pv = max_pv

	heal_potions.clear()
	honey_potions.clear()

	banane_count = 0
	honey_count = 0
	coco_count = 0
	bone_count = 0
	seed_count = 0
	lance_count = 0

	can_fire_coco = false
	can_fire_lance = false
	can_fire_bone = false

	if game_state:
		game_state.banane_count = 0
		game_state.honey_count = 0
		game_state.coco_count = 0
		game_state.bone_count = 0
		game_state.seed_count = 0
		game_state.lance_count = 0

		game_state.can_fire_coco = false
		game_state.can_fire_lance = false
		game_state.can_fire_bone = false
		can_camouflage = game_state.can_camouflage

		if game_state.hud and game_state.hud.has_method("update_health_bar"):
			game_state.hud.update_health_bar(pv, max_pv)

		if game_state.hud and game_state.hud.has_method("update_lives_display"):
			game_state.hud.update_lives_display(game_state.lives)
		if game_state.hud and game_state.hud.has_method("update_lance_display"):
			game_state.hud.update_lance_display()

	await get_tree().create_timer(1.0).timeout
	can_be_damaged = true

func _on_clac_area_body_entered(body):
	if body and body.has_method("on_hit"):
		body.on_hit(clac_damage)
