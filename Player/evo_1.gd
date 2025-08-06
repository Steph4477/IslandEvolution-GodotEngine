extends CharacterBody2D

# ============================================================================
# =                    VARIABLES, CONSTANTES, EXPORTS...                     =
# ============================================================================

const INPUT = {
	"jump": "ui_up",
	"left": "ui_left",
	"right": "ui_right",
	"down": "ui_down",
	"fire": "ui_cancel",
	"heal": "ui_accept",
	"ramp": "ramping",
	"clac": "clacing"
}
const JUMP_BUFFER_TIME := 0.1

@export var speed: float = 400
@export var jump_force: float = -400
@export var gravity: float = 1200
@export var climb_speed: float = 100
@export var clac_damage: int = 10
@export var max_pv: int = 2000
@export var pv: int = max_pv
@export var cooldown_potion: float = 10
@export var heal_amount: int = 50  # défini dans GameState
@export var total_seeds_in_level: int = 10  

var SpellCoco = preload("res://Tir/coco.tscn")
var game_state
var can_move = true
var can_be_damaged = true
var is_dead = false
var animation_locked = false
var jump_buffer = 0.0
var climbing_anim = ""
var can_climb := false
var is_hanging = false
var hang_timer := 0.0
var can_ramp = false
var is_ramping = false
var ramp_locked = false
var is_gazed = false
var can_fire_coco = false
var rate_of_fire = 0.4
var is_attacking = false # Attaque corps à corps 
var coco_count = 0
var banane_count = 0
var seed_count = 0
var heal_potions = []
var in_cooldown = false
var can_heal = true
var is_in_cooldown: bool = false

# --- Nodes ---
@onready var sprite = $Sprite
@onready var anim = $Anim
@onready var camera = $Camera2D

# --- HUD Labels ---
var label_banane: Label
var label_coco: Label
var label_seed: Label

# =======================================================================
# =                      INITIALISATION                                 =
# =======================================================================

func _ready():
	camera.make_current()
	await get_tree().process_frame
	setup_game_state()
	setup_hud()
	await get_tree().process_frame
	if game_state and game_state.hud.has_method("update_seed_display"):
		game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)
	
	# ✅ forcer l’anim au neutre -> fix bug : "hang"
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
	seed_count = game_state.seed_count
	can_fire_coco = game_state.can_fire_coco

func setup_hud():
	if not game_state or not game_state.hud:
		return
	var hud = game_state.hud
	label_banane = hud.get_node("HBoxContainerBanane/Label/BananeCountLabel")
	label_coco = hud.get_node("HBoxContainerCoco/CocoCountLabel")
	label_seed = hud.get_node("HBoxContainerSeed/SeedCountLabel")
	if game_state and game_state.hud and game_state.hud.has_method("update_lives_display"):
		game_state.hud.update_lives_display(game_state.lives)

	update_all_displays()
	refresh_hud_buttons()

# --- Physics Process ---
func _physics_process(delta):
	if not can_move or animation_locked:
		return
	_process_climb()
	_update_jump(delta)
	_move_horizontal()
	_process_ramp()
	_process_shoot()
	_process_clac()
	_process_heal()
	_process_hang_swing(delta)
	move_and_slide()
	update_animation()

# ============================================================================
# =                         MOUVEMENTS                                       =
# ============================================================================

func _move_horizontal():
	var dir = Input.get_action_strength(INPUT["right"]) - Input.get_action_strength(INPUT["left"])
	velocity.x = dir * speed
	if dir != 0:
		if dir > 0:
			sprite.scale.x = abs(sprite.scale.x)
		else:
			sprite.scale.x = -abs(sprite.scale.x)

func _update_jump(delta):
	if climbing_anim != "":
		return

	if is_on_floor() and Input.is_action_just_pressed(INPUT["jump"]):
		velocity.y = jump_force
		is_ramping = false
	elif not is_ramping:
		velocity.y += gravity * delta

# --- Escalade ---
func set_can_climb(state: bool, anim_name := ""):
	if state:
		climbing_anim = anim_name
		anim.play("hang")  # ✅ Joue directement l'animation d'accroche
	else:
		climbing_anim = ""
		is_hanging = false
		velocity.y = 0
		anim.play("idle")

func start_climb(anim_name: String):
	climbing_anim = anim_name  # On se souvient juste de l’anim

func stop_climb():
	climbing_anim = ""
	is_hanging = false

func _process_climb():
	if climbing_anim == "":
		if is_hanging:
			is_hanging = false
		return

	# --- Appui maintenu : monter ---
	if Input.is_action_pressed("ui_up"):
		if not anim.is_playing() or anim.current_animation != climbing_anim:
			anim.play(climbing_anim)
		velocity.y = -climb_speed
		is_hanging = false

	# --- Touche relâchée : rester accroché ---
	elif Input.is_action_just_released("ui_up"):
		anim.play("hang")
		velocity.y = 0
		is_hanging = true

	# --- Aucun input, pas de changement ---
	elif not Input.is_action_pressed("ui_up"):
		velocity.y = 0

# --- Effet de balançoire 🍃 de "hang" ---
func _process_hang_swing(delta: float) -> void:
	if is_hanging:
		hang_timer += delta
		var swing = sin(hang_timer * 2.0) * 5  # vitesse * amplitude
		sprite.rotation_degrees = swing
	else:
		sprite.rotation_degrees = 0
		hang_timer = 0.0

# --- Ramp ---
func unlock_ramp():
	can_ramp = true
	show_info_popup("🤸 Tu peux maintenant ramper !")

	if not game_state or not game_state.health_bar:
		return

	var hud = game_state.health_bar.get_parent()
	if hud and hud.has_node("Gamepad/Ramp"):
		hud.set_button_enabled(hud.get_node("Gamepad/Ramp"), true)

func _process_ramp():
	if can_ramp and Input.is_action_just_pressed(INPUT["ramp"]) and is_on_floor() and not ramp_locked:
		ramp_locked = true
		is_ramping = not is_ramping

		if is_ramping:
			show_info_popup("🧎 Rampe activée !")
		else:
			show_info_popup("🚶 Rampe désactivée !")

		await get_tree().create_timer(0.2).timeout
		ramp_locked = false

	if is_ramping:
		velocity.y = 0
		var rdir = Input.get_action_strength(INPUT["right"]) - Input.get_action_strength(INPUT["left"])
		velocity.x = rdir * speed * 0.4


# =================================================================================================
# =                                   COLLECTES                                                   =
# =================================================================================================

func collect_banane(amount: int = 1) -> void:
	if game_state:
		for i in range(amount):
			heal_potions.append(game_state.heal_amount)
	banane_count = heal_potions.size()
	if game_state:
		game_state.banane_count = banane_count

	# ✅ Mise à jour heal et bouton
	update_can_heal()
	var hud = game_state.health_bar.get_parent()
	if hud and hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal)

	update_banane_display()
	show_info_popup("5 jus de bananes récupérés !")
	refresh_hud_buttons()

func collect_coco(amount: int = 1, enable_shooting: bool = false) -> void:
	coco_count += amount

	if enable_shooting:
		can_fire_coco = true
		var hud = game_state.health_bar.get_parent()
		if hud.has_method("set_button_enabled"):
			hud.set_button_enabled(hud.get_node("Gamepad/Coco"), true)

	if game_state:
		game_state.can_fire_coco = can_fire_coco
		game_state.coco_count = coco_count

	update_coco_display()
	show_info_popup("Tu peux lancer 3 noix de coco")

func collect_seed(amount: int = 1) -> void:
	seed_count += amount

	if game_state:
		game_state.seed_count = seed_count
		game_state.collected_seeds += amount

		if game_state.hud and game_state.hud.has_method("update_seed_display"):
			game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)

		if game_state.collected_seeds >= game_state.total_seeds_in_level:
			game_state.emit_signal("all_seeds_collected")

	# 🎥 Focus caméra + anim totem + retour
	var parent = get_parent()
	if parent and parent.has_method("focus_camera_on_totem_with_anim"):
		await parent.focus_camera_on_totem_with_anim(game_state.collected_seeds)


# =============================================================================
# =                              ACTIONS                                      =
# =============================================================================

# --- Tir ---
func shoot_coco():
	if Input.is_action_just_pressed(INPUT["fire"]) and coco_count > 0:
		coco_count -= 1
		can_fire_coco = coco_count > 0
		update_coco_display()
		game_state.coco_count = coco_count

		# 🔒 On bloque les autres animations pendant le tir
		animation_locked = true
		anim.play("shoot")

		# ⏳ Attente de fin d'animation
		await anim.animation_finished

		# 🥥 Maintenant on lance la noix de coco
		var spell = SpellCoco.instantiate()
		var dir = 1
		if sprite.scale.x < 0:
			dir = -1
		spell.start($TurnAxis/CastPoint.global_position, dir)
		get_tree().current_scene.add_child(spell)

		animation_locked = false
		refresh_hud_buttons()

		# (optionnel) attends un petit cooldown de cadence de tir
		await get_tree().create_timer(rate_of_fire).timeout

func _process_shoot():
	if Input.is_action_pressed(INPUT["fire"]) and can_fire_coco:
		shoot_coco()

# --- Corps à corps ---
func clac_attack():
	if is_attacking or is_dead:
		return
	var dir = 1
	if sprite.scale.x < 0:
		dir = -1

	$ClacArea.position.x = abs($ClacArea.position.x) * dir

	is_attacking = true
	animation_locked = true
	anim.play("clac")

	# Active la zone d'attaque temporairement
	$ClacArea.monitoring = true

	await anim.animation_finished

	$ClacArea.monitoring = false
	is_attacking = false
	animation_locked = false

func _process_clac():
	if Input.is_action_just_pressed(INPUT["clac"]):
		clac_attack()

# --- Heal ---
func heal(amount: int) -> void:
	pv = clamp(pv + amount, 0, max_pv)

	if game_state:
		game_state.health_bar.set_value(pv)
		game_state.banane_count = heal_potions.size()

	banane_count = heal_potions.size()
	update_banane_display()


func update_can_heal() -> void:
	can_heal = heal_potions.size() > 0 and pv < max_pv and not in_cooldown


func _process_heal() -> void:
	if Input.is_action_just_pressed(INPUT["heal"]):
		use_banane()


func use_banane() -> void:
	var msg := ""
	if pv >= max_pv:
		msg = "PV au max !"
	elif in_cooldown:
		msg = "⏳ Potion en recharge..."
	elif heal_potions.is_empty():
		msg = "Aucune potion !"

	if msg != "":
		show_info_popup(msg)
		await _play_anim("empty")
		return

	await _play_anim("heal")

	heal(game_state.heal_amount)
	heal_potions.pop_front()

	in_cooldown = true
	update_can_heal()
	update_banane_display()
	game_state.banane_count = banane_count
	refresh_hud_buttons()
	start_potion_cooldown()


func _play_anim(name: String) -> void:
	anim.play(name)
	animation_locked = true
	await anim.animation_finished
	animation_locked = false


func start_potion_cooldown():
	in_cooldown = true
	if game_state.health_bar.get_parent().has_method("start_banane_cooldown"):
		game_state.health_bar.get_parent().start_banane_cooldown(cooldown_potion)
	await get_tree().create_timer(cooldown_potion).timeout
	in_cooldown = false
	refresh_hud_buttons()
	
# --- Control ---
func disable_controls():
	can_move = false
	velocity = Vector2.ZERO

func enable_controls():
	can_move = true

# --- Effects ---
func apply_gaz():
	if is_gazed:
		return
	is_gazed = true
	speed *= 0.2
	await get_tree().create_timer(3).timeout
	speed /= 0.2
	is_gazed = false

func apply_web():
	speed *= 0.5
	await get_tree().create_timer(10).timeout
	speed /= 0.5

func kill_by_plant() -> void:
	visible = false

# =============================================================================
# =                     DOMMAGES ET MORT                                      =
# =============================================================================
func on_hit(damage: int) -> void:
	if not can_be_damaged:
		return

	pv -= damage
	pv = clamp(pv, 0, max_pv)

	game_state.health_bar.set_value(pv)
	show_damage_popup(damage)
	update_can_heal()
	refresh_hud_buttons()

	var hud = game_state.health_bar.get_parent()
	if hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal)

	if pv <= 0:
		die()


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
	# ✅ Remet l'opacité à fond
	modulate = Color(1, 1, 1, 1)
	await  get_tree().process_frame

	var next_level = ""
	if game_state.is_game_over():
		next_level = "res://Menu/Game_over/game_over.tscn"
	else:
		next_level = game_state.current_level_path

	game_state.load_level(next_level)

# ============================================================================
# =                            ANIMATIONS                                    =
# ============================================================================
func update_animation():
	if animation_locked or is_dead:
		return

	# 🔒 Ne rien toucher si accroché ou en train de grimper
	if is_hanging:
		return
	if climbing_anim != "" and velocity.y != 0:
		anim.play(climbing_anim)
		return
	if anim.current_animation == "hang":
		return

	# ✅ SOL — forcer idle, walk ou ramp
	if is_on_floor():
		if is_ramping:
			if abs(velocity.x) > 0.1:
				anim.play("ramp")
			else:
				anim.play("idle")
		else:
			if abs(velocity.x) > 0.1:
				if is_gazed:
					anim.play("walk_gaz")
				else:
					anim.play("walk")
			else:
				anim.play("idle")
		return  # 🛑 Ne va pas dans la logique en l'air

	# 🪂 EN L’AIR
	if velocity.y < 0:
		anim.play("jump_up")
		$Sound/Jump.play()
	elif velocity.y > 0:
		anim.play("jump_down")  # proche du sol : joue idle (pose atterrissage)

# =============================================================================
# =                             HUD & Popups                                  =
# =============================================================================

func update_banane_display():
	if label_banane:
		label_banane.text = "x %d" % banane_count

func update_coco_display():
	if label_coco:
		label_coco.text = "x %d" % coco_count

func update_seed_display():
	if game_state and game_state.hud.has_method("update_seed_display"):
		game_state.hud.update_seed_display(game_state.collected_seeds, game_state.total_seeds_in_level)

func update_all_displays():
	update_banane_display()
	update_coco_display()
	update_seed_display()

func refresh_hud_buttons():
	if not game_state or not game_state.health_bar:
		return
	
	var hud_parent = game_state.health_bar.get_parent()
	if not hud_parent:
		return

	# 🌴 Bouton coco
	if hud_parent.has_node("Gamepad/Coco"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Coco"), can_fire_coco)

	# 🍌 Bouton soin
	var can_heal_btn = pv < max_pv and heal_potions.size() > 0 and not in_cooldown
	if hud_parent.has_node("Gamepad/Health"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Health"), can_heal_btn)

	# 🤸‍♂️ Bouton ramp
	if hud_parent.has_node("Gamepad/Ramp"):
		hud_parent.set_button_enabled(hud_parent.get_node("Gamepad/Ramp"), can_ramp)

func show_info_popup(txt: String) -> void:
	var popup = preload("res://ItemsDecors/info_popup.tscn").instantiate()
	add_child(popup)
	popup.show_info(txt)

func show_damage_popup(amount: int) -> void:
	var popup = preload("res://ItemsDecors/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)  # position flottante au-dessus du joueur
	popup.show_damage(amount)

func reset_state() -> void:
	is_dead = false
	animation_locked = false
	visible = true

	# ❤️ PV à fond
	pv = max_pv

	# 🍌 Réinitialise les loots
	heal_potions.clear()
	banane_count = 0
	coco_count = 0
	seed_count = 0
	can_fire_coco = false

	if game_state:
		game_state.banane_count = 0
		game_state.coco_count = 0
		game_state.seed_count = 0
		game_state.can_fire_coco = false

		# ✅ MAJ immédiate avant la frame 
		if game_state.hud and game_state.hud.has_method("update_health_bar"):
			game_state.hud.update_health_bar(pv, max_pv)

		if game_state.hud and game_state.hud.has_method("update_lives_display"):
			game_state.hud.update_lives_display(game_state.lives)

	# ⏳ Protection temporaire (1s) pour éviter les pièges instantanés
	await get_tree().create_timer(1.0).timeout
	can_be_damaged = true


func _on_clac_area_body_entered(body: Node2D) -> void:
	if body and body.has_method("on_hit"):
		body.on_hit(clac_damage)
