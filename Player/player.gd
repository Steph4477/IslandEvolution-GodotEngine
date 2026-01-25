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

# --- modules ---
var breath_mod
var collect_items
var collect_skills
var combat_mod
var damage_mod
var effects_mod
var items_mod
var movement_mod
var skills_mod

var can_move = true
var can_be_damaged = true
var is_dead = false
var is_jumping = false
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
# --- fire 
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

	setup_breath_module()
	setup_collect_items()
	setup_collect_skills()
	setup_combat_module()
	setup_damage_module()
	setup_effects_module()
	setup_items_module()
	setup_movement_module()
	setup_skills_module()

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


# --- Modules ---

func setup_breath_module():
	breath_mod = preload("res://Player/Modules/Player_Breath/player_breath.gd").new()
	add_child(breath_mod)
	breath_mod.setup(self)

func setup_collect_items():
	collect_items = preload("res://Player/Modules/Player_Collect_Items/player_collect_items.gd").new()
	add_child(collect_items)
	collect_items.setup(self)

func setup_collect_skills():
	collect_skills = preload("res://Player/Modules/Player_Collect_Skills/player_collect_skills.gd").new()
	add_child(collect_skills)
	collect_skills.setup(self)

func setup_combat_module():
	combat_mod = preload("res://Player/Modules/Player_Combat/player_combat.gd").new()
	add_child(combat_mod)
	combat_mod.setup(self)

func setup_damage_module():
	damage_mod = preload("res://Player/Modules/Player_Damage/player_damage.gd").new()
	add_child(damage_mod)
	damage_mod.setup(self)

func setup_effects_module():
	effects_mod = preload("res://Player/Modules/Player_Effects/player_effects.gd").new()
	add_child(effects_mod)
	effects_mod.setup(self)

func setup_items_module():
	items_mod = preload("res://Player/Modules/Player_Items/player_items.gd").new()
	add_child(items_mod)
	items_mod.setup(self)

func setup_movement_module():
	movement_mod = preload("res://Player/Modules/Player_Movement/player_movement.gd").new()
	add_child(movement_mod)
	movement_mod.setup(self)

func setup_skills_module():
	skills_mod = preload("res://Player/Modules/Player_Skills/player_skills.gd").new()
	add_child(skills_mod)
	skills_mod.setup(self)


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

	# ordre volontaire : skills -> movement -> items -> combat
	if skills_mod:
		skills_mod.process(delta)

	if movement_mod:
		movement_mod.process(delta, was_on_floor)

	if items_mod:
		items_mod.process()

	if combat_mod:
		combat_mod.process()

	move_and_slide()

	if movement_mod:
		movement_mod.post_physics(was_on_floor)

	update_animation()



# =======================================================================
#                       TIMERS (connectés au Player)
# =======================================================================

func _on_breath_tick_timer_timeout():
	if breath_mod:
		breath_mod.on_breath_tick_timeout()

func _on_bubble_timer_timeout():
	if breath_mod:
		breath_mod.on_bubble_timer_timeout()

func _on_drown_timer_timeout():
	if breath_mod:
		breath_mod.on_drown_timer_timeout()


# =======================================================================
#                               HELPERS UTILISÉS PARTOUT
# =======================================================================
func heal(amount):
	pv = clamp(pv + amount, 0, max_pv)

	if game_state:
		game_state.health_bar.set_value(pv)
		game_state.banane_count = heal_potions.size()

	banane_count = heal_potions.size()
	update_banane_display()

func update_can_heal():
	can_heal = heal_potions.size() > 0 and pv < max_pv and not in_cooldown

func disable_controls():
	can_move = false
	velocity = Vector2.ZERO

func enable_controls():
	can_move = true



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


func _on_clac_area_body_entered(body):
	if body and body.has_method("on_hit"):
		body.on_hit(clac_damage)
