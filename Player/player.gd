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
	"sprint": "sprint"
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

var spell_coco = preload("res://Shoot/Player/Coconut/coconut.tscn")
var spell_bone = preload("res://Shoot/Player/Bone/bone.tscn")
var spell_lance = preload("res://Shoot/Player/Spear/spear.tscn")
var game_state
var can_move = true
var can_be_damaged = true
var is_dead = false
var animation_locked = false
var jump_buffer = 0.0
var climbing_anim = ""
var can_climb = false
var is_hanging = false
var hang_timer = 0.0
var can_ramp = false
var is_ramping = false
var can_swim = false
var is_swimming = false
var swim_speed_x = 150
var swim_speed_y = 110
var swim_timer = 0.0
var water_current = Vector2(-120, 0)  # force du courant
var can_sprint = false
var is_sprinting = false
var ramp_locked = false
var is_gazed = false
var is_web = false
var can_fire_coco = false
var can_fire_bone = false
var can_fire_lance = false
var rate_of_fire = 0.4
var is_attacking = false # Attaque corps à corps 
var coco_count = 0
var bone_count = 0
var banane_count = 0
var seed_count = 0
var lance_count = 0
var gravity_factor = 1.0
var heal_potions = []
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
	camera.make_current()
	await get_tree().process_frame
	setup_game_state()
	setup_hud()
	await get_tree().process_frame
	if game_state and game_state.hud.has_method("update_seed_display"):
		game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)
	
	if anim.current_animation == "hang":
		anim.play("idle")
	is_hanging = false
	climbing_anim = ""

func setup_game_state():
	game_state = get_node_or_null("/root/GameState")
	if not game_state:
		return
	game_state.set_player(self)
	banane_count = game_state.banane_count
	coco_count = game_state.coco_count
	bone_count = game_state.bone_count
	seed_count = game_state.seed_count
	lance_count = game_state.lance_count
	can_fire_coco = game_state.can_fire_coco
	can_fire_lance = game_state.can_fire_lance
	can_fire_bone = game_state.can_fire_bone
	can_ramp = game_state.ramp_unlocked
	can_sprint = game_state.sprint_unlocked
	
func setup_hud():
	if not game_state or not game_state.hud:
		return
	var hud = game_state.hud
	label_banane = hud.get_node("HBoxContainerBanane/Label/BananeCountLabel")
	label_coco = hud.get_node("HbcCoco/HBoxContainerCoco/CocoCountLabel")
	label_bone = hud.get_node("HbcBone/HBoxContainerBone/BoneCountLabel")
	label_seed = hud.get_node("HBoxContainerSeed/SeedCountLabel")
	if game_state and game_state.hud and game_state.hud.has_method("update_lives_display"):
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
	
	is_pushing_or_pulling = can_push_pull and Input.is_action_pressed("push_pull")
	
	process_climb()
	process_liana(delta)
	update_jump(delta)
	process_sprint()
	move_horizontal()
	process_ramp()
	process_swim(delta)
	process_shoot()
	process_clac()
	process_heal()
	process_hang_swing(delta)
	
	move_and_slide()
	
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

func update_jump(delta):
	if is_swimming:
		return
	
	if climbing_anim != "":
		return
	
	if is_on_floor():
		if Input.is_action_just_pressed(INPUT["jump"]):
			velocity.y = jump_force
			is_ramping = false
	else:
		if not is_ramping:
			velocity.y += gravity * gravity_factor * delta

# --- WALL JUMP SIMPLE ---
func process_wall_jump_input():
	# Pas de wall jump dans ces cas-là
	if is_on_floor():
		return
	if is_on_liana:
		return
	if is_swimming:
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

# --- Escalade ---
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

# --- Ramp ---
func unlock_ramp():
	can_ramp = true
	game_state.ramp_unlocked = true   

	show_info_popup("🤸 Tu peux maintenant ramper !")
	
	if not game_state or not game_state.health_bar:
		return
	
	var hud = game_state.hud
	if hud.has_node("Gamepad/Ramp"):
		hud.set_button_enabled(hud.get_node("Gamepad/Ramp"), true)


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

# --- Sprint ---
func unlock_sprint():
	can_sprint = true
	game_state.sprint_unlocked = true
	game_state.sprint_stamina = game_state.sprint_stamina_max
	
	if game_state.speed_bar:
		game_state.speed_bar.visible = true
		game_state.speed_bar.update_speed_bar_current(game_state.sprint_stamina)
	
	if game_state.hud:
		var hud = game_state.hud
		if hud.has_node("Gamepad/Sprint"):
			hud.set_button_enabled(hud.get_node("Gamepad/Sprint"), true)
	
	show_info_popup("⚡ Tu peux maintenant sprinter avec Shift !")

func process_sprint():
	var delta = get_physics_process_delta_time()
	
	if not game_state:
		return
	
	if not game_state.sprint_unlocked:
		is_sprinting = false
		return
	
	# Pas de sprint dans ces états
	if is_swimming or is_ramping or is_on_liana:
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

# --- Liane & Balancement ---
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
	if not is_on_liana or current_liana == null:
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

# =================================================================================================
#                                     COLLECTES                                                   
# =================================================================================================

func collect_banane(amount = 1):
	if game_state:
		for i in range(amount):
			heal_potions.append(game_state.heal_amount)
	banane_count = heal_potions.size()
	if game_state:
		game_state.banane_count = banane_count
		
	update_can_heal()
	var hud = game_state.hud
	if hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal)
	
	update_banane_display()
	show_info_popup("5 jus de bananes récupérés !")
	refresh_hud_buttons()

func collect_coco(amount = 1, enable_shooting = false):
	coco_count += amount
	
	if enable_shooting:
		can_fire_coco = true
		var hud = game_state.hud
		if hud.has_method("set_button_enabled"):
			hud.set_button_enabled(hud.get_node("Gamepad/Coco"), true)
	
	if game_state:
		game_state.can_fire_coco = can_fire_coco
		game_state.coco_count = coco_count
	
	update_coco_display()
	show_info_popup("Tu peux lancer 3 noix de coco")
	refresh_hud_buttons()

func collect_bone(amount = 1, enable_shooting = false):
	bone_count += amount
	
	if enable_shooting:
		can_fire_bone = true
		var hud = game_state.hud
		if hud.has_method("set_button_enabled"):
			hud.set_button_enabled(hud.get_node("Gamepad/Bone"), true)
	
	if game_state:
		game_state.can_fire_bone = can_fire_bone
		game_state.bone_count = bone_count
		
		# Bascule le HUD en mode BONE en passant par l'animation du HUD (remplace Coco par Bone)
		if game_state.hud and game_state.hud.has_method("anim_to_bone_mode"):
			game_state.hud.anim_to_bone_mode()
	
	update_bone_display()
	show_info_popup("Tu peux lancer 3 os")
	refresh_hud_buttons()

func collect_lance(amount = 1, enable_shooting = false):
	lance_count += amount
	
	if enable_shooting:
		can_fire_lance = true
		var hud = game_state.hud
		if hud.has_node("Gamepad/Spear"):
			hud.set_button_enabled(hud.get_node("Gamepad/Spear"), true)
	
	if game_state:
		game_state.lance_count = lance_count
		game_state.can_fire_lance = can_fire_lance
		if game_state.hud and game_state.hud.has_method("update_lance_display"):
			game_state.hud.update_lance_display()
	
	show_info_popup("Tu peux shooter des lances")
	refresh_hud_buttons()

func collect_seed(amount = 1):
	seed_count += amount
	
	if game_state:
		game_state.seed_count = seed_count
		game_state.collected_seeds += amount
		
		if game_state.hud and game_state.hud.has_method("update_seed_display"):
			game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)
		
		if game_state.collected_seeds >= game_state.total_seeds_in_level:
			game_state.emit_signal("all_seeds_collected")
	
	var parent = get_parent()
	if parent and parent.has_method("focus_camera_on_totem_with_anim"):
		await parent.focus_camera_on_totem_with_anim(game_state.collected_seeds)

# =============================================================================
#                               ACTIONS                                     
# =============================================================================

func shoot_coco():
	if is_swimming or is_ramping or is_hanging or is_on_liana:
		return
	
	# Resync depuis GameState 
	coco_count = game_state.coco_count
	can_fire_coco = game_state.can_fire_coco
	
	if not can_fire_coco:
		return
	if coco_count <= 0:
		return
	
	# Consomme une coco
	coco_count -= 1
	can_fire_coco = coco_count > 0
	
	# Sync GameState

	game_state.coco_count = coco_count
	game_state.can_fire_coco = can_fire_coco
	
	update_coco_display()
	
	# Anim + projectile
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
	if is_swimming or is_ramping or is_hanging or is_on_liana:
		return
	
	# Resync depuis GameState
	bone_count = game_state.bone_count
	can_fire_bone = game_state.can_fire_bone
	
	if not can_fire_bone:
		return
	if bone_count <= 0:
		return
	
	# Consomme un os
	bone_count -= 1
	can_fire_bone = bone_count > 0
	
	# Sync GameState
	game_state.bone_count = bone_count
	game_state.can_fire_bone = can_fire_bone
	
	update_bone_display()
	
	# Anim + projectile
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
	if is_swimming or is_ramping or is_hanging or is_on_liana:
		return
	
	# Resync depuis GameState
	lance_count = game_state.lance_count
	can_fire_lance = game_state.can_fire_lance
	
	if not can_fire_lance:
		return
	if lance_count <= 0:
		return
	
	# Consomme une lance
	lance_count -= 1
	can_fire_lance = lance_count > 0
	
	# Sync GameState
	game_state.lance_count = lance_count
	game_state.can_fire_lance = can_fire_lance
	
	update_lance_display()
	
	# Anim + projectile
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
	if Input.is_action_pressed(INPUT["fire_lance"]) and can_fire_lance:
		shoot_lance()

# --- Corps à corps ---
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

# --- Heal ---
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
	start_potion_cooldown()

func start_potion_cooldown():
	in_cooldown = true
	if game_state.health_bar.get_parent().has_method("start_banane_cooldown"):
		game_state.health_bar.get_parent().start_banane_cooldown(cooldown_potion)
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
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal)
	
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
	await  get_tree().process_frame
	
	var next_level = ""
	if game_state.is_game_over():
		next_level = "res://Menu/Game_over/game_over.tscn"
	else:
		next_level = game_state.current_level_path
	
	game_state.load_level(next_level)

# ======================================================================
#          IMMUNITÉ AUX SECOUSSES (tremblement grenouille)             
# ======================================================================
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
		anim.play("jump_up")
		$Sound/Jump.play()
	elif velocity.y > 0:
		anim.play("jump_down")

# =============================================================================
#                               HUD & Popups                                  
# =============================================================================

func update_banane_display():
	if game_state and game_state.hud and game_state.hud.has_method("update_banane_display"):
		game_state.hud.update_banane_display()

func update_coco_display():
	if game_state and game_state.hud and game_state.hud.has_method("update_coco_display"):
		game_state.hud.update_coco_display()

func update_bone_display():
	if game_state and game_state.hud and game_state.hud.has_method("update_bone_display"):
		game_state.hud.update_bone_display()

func update_lance_display():
	if game_state and game_state.hud and game_state.hud.has_method("update_lance_display"):
		game_state.hud.update_lance_display()

func update_seed_display():
	if game_state and game_state.hud.has_method("update_seed_display"):
		game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)

func update_all_displays():
	update_banane_display()
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
	
	if hud_parent.has_node("Gamepad/Coco"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Coco"), can_fire_coco)
	
	if hud_parent.has_node("Gamepad/Bone"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Bone"), can_fire_bone)
	
	if hud_parent.has_node("Gamepad/Spear"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Spear"), can_fire_lance)
	
	var can_heal_btn = pv < max_pv and heal_potions.size() > 0 and not in_cooldown
	if hud_parent.has_node("Gamepad/Health"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Health"), can_heal_btn)
	
	if hud_parent.has_node("Gamepad/Ramp"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Ramp"), can_ramp)
	
	if hud_parent.has_node("Gamepad/Sprint"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Sprint"), can_sprint)

func reset_state():
	is_dead = false
	animation_locked = false
	visible = true
	
	pv = max_pv
	
	heal_potions.clear()
	banane_count = 0
	coco_count = 0
	bone_count = 0
	seed_count = 0
	lance_count = 0
	can_fire_coco = false
	can_fire_lance = false
	can_fire_bone = false
	
	if game_state:
		game_state.banane_count = 0
		game_state.coco_count = 0
		game_state.bone_count = 0
		game_state.seed_count = 0
		game_state.lance_count = 0
		game_state.can_fire_coco = false
		game_state.can_fire_lance = false
		game_state.can_fire_bone = false
		
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
