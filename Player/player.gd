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
	"ramping": "ramping",
	"clac": "clacing",
	"sprint": "sprint",
	"camouflage": "camouflage",
	"fire_buff": "fire_buff",        # F (InputMap)
	"air_buff": "air_buff",          # A (InputMap)

	# --- Gameplay jet ---
	"throw_mode": "throw_mode",      # L (InputMap)
	"throw_switch": "switch",        # switch
	"throw_fire": "throw_fire",      # shoot (space)

	# --- Gameplay skill ---
	"skill_mode": "skill_mode",      # K (InputMap)
	"skill_switch": "switch",        # switch (même action que throw)

	# --- Gameplay heal ---
	"heal_mode": "heal_mode",        # H (InputMap)
	"heal_switch": "switch",         # switch (même action que throw)
	"heal_use": "throw_fire"         # shoot (space) -> même action que le tir
}

@export var speed = 400
@export var jump_force = -800
@export var gravity = 1200
@export var climb_speed = 100
@export var clac_damage = 100
@export var max_pv = 2000
@export var pv = max_pv
@export var cooldown_potion = 10
@export var heal_amount = 50
@export var total_seeds_in_level = 10

# --- Dégâts de chute ---
@export var fall_damage_enabled = true
@export var fall_safe_limit = 1200
@export var fall_speed_max = 1800
@export var fall_damage_max = 600
@export var fall_damage_min = 50

# --- Suivie vitesse de chute ---
var fall_speed_track = 0.0

var spell_coco = preload("res://Shoot/Player/Coconut/coconut.tscn")
var spell_bone = preload("res://Shoot/Player/Bone/bone.tscn")
var spell_lance = preload("res://Shoot/Player/Spear/spear.tscn")

var spell_coco_fire = preload("res://Shoot/Player/Coconut/Fire/coconut_fire.tscn")
var spell_bone_fire = preload("res://Shoot/Player/Bone/Fire/bone_fire.tscn")
var spell_lance_fire = preload("res://Shoot/Player/Spear/Fire/spear_fire.tscn")

var game_state
var skill_select_mod = null
var skill_switch_mod = null
var throw_mod = null
var switch_heal_mod = null

# --- modules ---
var state_sync_mod
var hud_mod
var breath_mod
var collect_items
var collect_skills
var combat_mod
var damage_mod
var effects_mod
var heal_mod
var movement_mod
var skills_mod
var animation_mod
var popups_mod
var fire_buff_mod
var air_buff_mod

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

# --- Coup de boule sous l'eau ---
@export var headbutt_damage = 200
@export var headbutt_speed = 300
@export var headbutt_duration = 0.4
@export var headbutt_cooldown = 1.5
var is_headbutting = false
var can_headbutt = true

# --- Skills ---
var can_sprint = false
var is_sprinting = false
var ramp_locked = false
var is_gazed = false
var is_web = false

# --- fire ---
var can_fire_coco = false
var can_fire_bone = false
var can_fire_lance = false
var rate_of_fire = 0.4
var is_attacking = false

# --- fire buff ---
var fire_buff_active = false
@export var fire_buff_duration = 8.0

# --- air buff ---
var air_buff_active = false
@export var air_buff_duration = 8.0

# --- Camouflage ---
var can_camouflage = false
@export var camouflage_duration = 5.0
var is_camouflaged = false

var turn_axis_parent = null
var turn_axis_index = 0

# --- Jump / double jump ---
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

var heal_potions = []
var honey_potions = []

var in_cooldown = false
var can_heal = true
var is_in_cooldown = false
var is_on_liana = false
var current_liana = null

# --- Caisse ---
var can_push_pull = false
var is_pushing_or_pulling = false

# --- Gameplay jet ---
var throw_mode = false
var selected_throw_weapon = "coco"
var dbg_throw = true

# --- Gameplay skill ---
var skill_mode = false
var selected_skill = "ramp"
var dbg_skill = true

# --- Gameplay heal ---
var heal_mode = false
var selected_heal = "banane"   # IMPORTANT : banane / honey (pas "health")
var dbg_heal = true

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

# =======================================================================
#                       INITIALISATION
# =======================================================================
func _ready():
	game_state = get_node("/root/GameState")

	setup_state_sync_module()
	if state_sync_mod:
		state_sync_mod.apply_from_gamestate()

	setup_hud_module()
	if hud_mod:
		await hud_mod.wait_until_ready()
	
	setup_popups_module()
	

	# --- THROW (L / switch / space) ---
	throw_mod = preload("res://Hud/switch_jet.gd").new()
	add_child(throw_mod)
	throw_mod.setup(self)

	# --- SKILL (K / switch) ---
	skill_switch_mod = preload("res://Hud/switch_skill.gd").new()
	add_child(skill_switch_mod)
	skill_switch_mod.setup(self)

	# --- HEAL (H / switch) ---
	switch_heal_mod = preload("res://Hud/switch_heal.gd").new()
	add_child(switch_heal_mod)
	switch_heal_mod.setup(self)

	setup_breath_module()
	setup_collect_items()
	setup_collect_skills()
	setup_combat_module()
	setup_damage_module()
	setup_effects_module()
	setup_fire_buff_module()
	setup_air_buff_module()
	setup_heal_module()
	setup_animation_module()
	setup_movement_module()
	setup_skills_module()

	camera.make_current()

	await get_tree().process_frame

	if hud_mod and game_state:
		hud_mod.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)

	if anim.current_animation == "hang":
		anim.play("idle")
	is_hanging = false
	climbing_anim = ""

	_restore_loaded_position_post_setup()

func _restore_loaded_position_post_setup():
	var gs = get_node("/root/GameState")
	if gs.has_pending_load:
		await get_tree().process_frame
		global_position = gs.pending_player_pos
		gs.has_pending_load = false

# --- Modules ---
func setup_state_sync_module():
	state_sync_mod = preload("res://Player/Modules/Player_State_Sync/player_state_sync.gd").new()
	add_child(state_sync_mod)
	state_sync_mod.setup(self)

func setup_hud_module():
	hud_mod = preload("res://Player/Modules/Player_HUD/player_hud.gd").new()
	add_child(hud_mod)
	hud_mod.setup(self)

func setup_popups_module():
	popups_mod = preload("res://Player/Modules/Player_Popups/player_popups.gd").new()
	add_child(popups_mod)
	popups_mod.setup(self)

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
	if dbg_throw:
		print("[THROW][READY] combat_mod=", combat_mod)

func setup_damage_module():
	damage_mod = preload("res://Player/Modules/Player_Damage/player_damage.gd").new()
	add_child(damage_mod)
	damage_mod.setup(self)

func setup_effects_module():
	effects_mod = preload("res://Player/Modules/Player_Effects/player_effects.gd").new()
	add_child(effects_mod)
	effects_mod.setup(self)

func setup_fire_buff_module():
	fire_buff_mod = preload("res://Player/Modules/Player_Fire_Buff/player_fire_buff.gd").new()
	add_child(fire_buff_mod)
	fire_buff_mod.setup(self)

func setup_air_buff_module():
	air_buff_mod = preload("res://Player/Modules/Player_Air_Buff/player_air_buff.gd").new()
	add_child(air_buff_mod)
	air_buff_mod.setup(self)

func setup_heal_module():
	heal_mod = preload("res://Player/Modules/Player_Heal/player_heal.gd").new()
	add_child(heal_mod)
	heal_mod.setup(self)

func setup_movement_module():
	movement_mod = preload("res://Player/Modules/Player_Movement/player_movement.gd").new()
	add_child(movement_mod)
	movement_mod.setup(self)

func setup_skills_module():
	skills_mod = preload("res://Player/Modules/Player_Skills/player_skills.gd").new()
	add_child(skills_mod)
	skills_mod.setup(self)

func setup_animation_module():
	animation_mod = preload("res://Player/Modules/Player_Animation/player_animation.gd").new()
	add_child(animation_mod)
	animation_mod.setup(self)

func _physics_process(delta):
	if throw_mod:
		throw_mod.update_input()

	if skill_switch_mod:
		skill_switch_mod.update_input()

	if switch_heal_mod:
		switch_heal_mod.update_input()

	if is_headbutting:
		velocity.y = 0
		move_and_slide()
		return

	if animation_locked:
		velocity.x = 0

		if is_jumping and not is_swimming and not is_swimming_under_water and climbing_anim == "":
			velocity.y += gravity * gravity_factor * delta

		move_and_slide()
		return

	if not can_move:
		velocity.x = 0
		if anim.current_animation != "idle":
			anim.play("idle")
		return

	if animation_locked:
		return

	var was_on_floor = is_on_floor()

	if skills_mod:
		skills_mod.process(delta)

	if movement_mod:
		movement_mod.process(delta, was_on_floor)

	if combat_mod:
		combat_mod.process()

	if heal_mod:
		heal_mod.process()

	move_and_slide()

	if movement_mod:
		movement_mod.post_physics(was_on_floor)

	if animation_mod:
		animation_mod.process()

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
#                               HELPERS
# =======================================================================
func heal(amount):
	pv = clamp(pv + amount, 0, max_pv)

	if game_state:
		game_state.health_bar.set_value(pv)
		game_state.banane_count = heal_potions.size()

	banane_count = heal_potions.size()

	if hud_mod:
		hud_mod.update_banane_display()
		hud_mod.refresh_hud_buttons()

	if game_state:
		game_state.update_boss_fight_hud()

func update_can_heal():
	can_heal = heal_potions.size() > 0 and pv < max_pv and not in_cooldown

func disable_controls():
	can_move = false
	velocity = Vector2.ZERO

func enable_controls():
	can_move = true

func _on_clac_area_body_entered(body):
	if body and body.has_method("on_hit"):
		body.on_hit(clac_damage)


func _on_headbutt_area_body_entered(body):
	if body and body.has_method("on_hit"):
		body.on_hit(headbutt_damage)
