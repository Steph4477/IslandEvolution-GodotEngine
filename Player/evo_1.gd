extends CharacterBody2D

@export var speed = 500
@export var max_pv = 2000
@export var jump_force = -1200
@export var gravity = 1200
@export var pv = max_pv 
@export var cooldown_popo = 10
@onready var banane_label = get_node("../Hud/HBoxContainerBanane/Label/BananeCountLabel")
@onready var coco_label = get_node("../Hud/HBoxContainerCoco/CocoCountLabel")
@onready var seed_label = get_node("../Hud/HBoxContainerSeed/SeedCountLabel")


# Initialisation des variables du GameState
var game_state
# Tir désactivé au début
var can_fire_coco 
# Potion banane
var heal_potions: Array[int] = []
var can_heal = true
var is_in_cooldown: bool = false
# Initialise le compteur
var coco_count
var banane_count = 0
var seed_count = 0
# Double Saut
var jump_count = 0
# tir
var spellCoco = preload ("res://Tir/coco.tscn")
var rate_of_fire = 0.4
# escalade
var is_climbing = false
var is_climbingCoco = false
var climb_speed = 100.0
var can_climb = false
var can_climbCoco = false
# mouvement
var moving_left = false
var moving_right = false
var jumping = false
var moving_down = false
# passage de porte
var animation_locked = false
# Effet gaz
var is_gazed = false
var initial_speed = speed
# Ramper
var can_ramp: bool = false
var is_ramping: bool = false
var ramp_toggle_locked := false  #verouillage du bouton
# Flag pour joystick
var want_to_jump := false
var jump_buffer_timer := 0.0
const JUMP_BUFFER_TIME := 0.1  # 100ms de buffer



func _ready():
	$Camera2D.make_current()
	await get_tree().process_frame  # attendre que tout soit bien en place
	game_state = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	set_game_state(game_state)
	game_state.health_bar.set_max_value(max_pv)
	game_state.health_bar.set_value(pv)


func set_game_state(gs):
	game_state = gs
	banane_count = game_state.banane_count
	coco_count = game_state.coco_count
	seed_count = game_state.seed_count
	can_fire_coco = game_state.can_fire_coco
	
	# Update du Hud
	update_banane_display()
	update_coco_display()
	update_seed_display()
	# Update du game State
	game_state.set_player(self)


func set_can_climb(value: bool) -> void:
	can_climb = value
	if !value:
		is_climbing = false


func set_can_climbCoco(value: bool) -> void:
	can_climbCoco = value
	if !value:
		is_climbingCoco = false


func _physics_process(delta: float) -> void:
	if animation_locked:
		return

	# --- MAJ buffer saut
	if jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
		print("⏳ Buffer actif :", jump_buffer_timer)

	var on_floor := is_on_floor()

	# --- Gestion du saut (clavier ou joystick avec buffer)
	if on_floor:
		var jump_requested := false

		if Input.is_action_just_pressed("ui_up"):
			print("⌨️ Touche saut détectée (ui_up)")
			jump_requested = true
		elif jump_buffer_timer > 0.0:
			print("🕹️ Saut via BUFFER (joystick)")
			jump_requested = true

		if jump_requested:
			velocity.y = jump_force
			is_ramping = false
			jump_buffer_timer = 0.0
			print("🚀 SAUT déclenché : velocity.y =", velocity.y)
	elif not is_climbing and not is_climbingCoco and not is_ramping:
		velocity.y += gravity * delta

	# --- Mouvement horizontal
	var direction := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if moving_left:
		direction = -1
	elif moving_right:
		direction = 1
	velocity.x = direction * speed

	# --- Flip sprite
	if direction > 0:
		$Sprite.scale.x = abs($Sprite.scale.x)
	elif direction < 0:
		$Sprite.scale.x = -abs($Sprite.scale.x)

	# --- Grimpe bananier
	if can_climb:
		if Input.is_action_pressed("ui_up"):
			is_climbing = true
	else:
		is_climbing = false


	# --- Grimpe cocotier
	if can_climbCoco:
		if Input.is_action_pressed("ui_up"):
			is_climbingCoco = true
	else:
		is_climbingCoco = false



	# --- Mouvement vertical grimpe
	if is_climbing or is_climbingCoco:
		velocity.y = 0
		if Input.is_action_pressed("ui_up"):
			velocity.y = -climb_speed
		#elif Input.is_action_pressed("ui_down"):
			#velocity.y = climb_speed

	# --- Toggle rampement clavier
	if can_ramp and Input.is_action_pressed("ramping") and on_floor:
		toggle_ramping()

	# --- Ramper (mouvement)
	if is_ramping:
		velocity.y = 0
		var ramp_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		velocity.x = ramp_dir * (speed * 0.4)
		if ramp_dir > 0:
			$Sprite.scale.x = abs($Sprite.scale.x)
		elif ramp_dir < 0:
			$Sprite.scale.x = -abs($Sprite.scale.x)

	# --- Tir
	if Input.is_action_pressed("ui_cancel") and can_fire_coco:
		Shoot()

	# --- Potion
	if Input.is_action_just_pressed("ui_accept"):
		use_banane_potion()

	# --- Déplacement
	move_and_slide()

	# --- Animation
	update_animation()


	
func toggle_ramping() -> void:
	if ramp_toggle_locked or not is_on_floor():
		return

	ramp_toggle_locked = true
	is_ramping = !is_ramping

	if is_ramping:
		show_info_popup("🧎 Rampe activée !")
	else:
		show_info_popup("🚶 Rampe désactivée !")

	await get_tree().create_timer(0.2).timeout
	ramp_toggle_locked = false


func update_can_heal():
	can_heal = heal_potions.size() > 0 and pv < max_pv and not is_in_cooldown


func start_banane_cooldown():
	is_in_cooldown = true
	update_can_heal()

	var hud = game_state.health_bar.get_parent()
	if hud and hud.has_method("start_banane_cooldown"):
		hud.start_banane_cooldown(cooldown_popo)

	await get_tree().create_timer(cooldown_popo).timeout

	is_in_cooldown = false
	update_can_heal()

	if hud and hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal)


func use_banane_potion() -> void:
	# Si PV déjà à fond → priorité au message "PV au max"
	if pv == max_pv:
		show_info_popup("PV au max !")
		return

	# Ensuite seulement, si cooldown actif → affiche recharge
	if is_in_cooldown:
		show_info_popup("⏳ Potion en recharge...")
		return

	# Plus de potion
	if heal_potions.is_empty():
		show_info_popup("Aucune potion !")
		return

	# ✅ Utilisation normale
	var amount = game_state.heal_amount
	can_heal = false
	is_in_cooldown = true
	heal_potions.pop_front()
	heal(amount)

	update_can_heal()

	var hud = game_state.health_bar.get_parent()
	if hud and hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal)

	await start_banane_cooldown()


func heal(amount: int) -> void:
	pv += amount
	pv = clamp(pv, 0, max_pv)

	# Mise à jour de la barre de vie
	if game_state:
		game_state.health_bar.set_value(pv)

	# Mise à jour du nombre de potions restantes
	banane_count = heal_potions.size()
	if game_state:
		game_state.banane_count = banane_count

	update_banane_display()


func unlock_ramp():
	can_ramp = true
	show_info_popup("Rampement activé !")
	var hud = game_state.health_bar.get_parent()
	if hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Ramp"), true)


func start_ramping():
	if not is_ramping:
		is_ramping = true

func stop_ramping():
	if is_ramping:
		is_ramping = false


func apply_gaz_effect():
	if is_gazed:
		return
	is_gazed = true
	# Ralentit le joueur
	speed = initial_speed * 0.2
	# Timer non bloquant
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(func():
		speed = initial_speed
		is_gazed = false
		timer.queue_free()
	)

func update_animation() -> void:
	if animation_locked:
		return
	if is_climbing:
		$anim.play("climb")
		return
	# 🐒 Ramper uniquement si on rampe ET qu'on se déplace
	if is_ramping and abs(velocity.x) > 0.1:
		$anim.play("ramp")
		return
	elif is_ramping:
		$anim.play("idle")  # anim immobile
		return
	if is_climbingCoco:
		$anim.play("climb_coco")
		return
	if velocity.y < 0:
		$anim.play("jump_up")
		$Sound/Jump.play()
	elif velocity.y > 0:
		$anim.play("jump_down")
	elif velocity.x != 0:
		# ✅ Si gazé joue "walk_gaz"
		if is_gazed:
			$anim.play("walk_gaz")
		else:
			$anim.play("walk")
	else:
		$anim.play("idle")


func on_hit(damage: int) -> void:
	pv -= damage
	pv = clamp(pv, 0, max_pv)
	game_state.health_bar.set_value(pv)
	show_damage_popup(damage)
	update_can_heal()

	var hud = game_state.health_bar.get_parent()
	if hud and hud.has_method("set_button_enabled"):
		hud.set_button_enabled(hud.get_node("Gamepad/Health"), can_heal)
	print("PV après coup :", pv)

func show_damage_popup(amount: int) -> void:
	var popup = preload("res://ItemsDecors/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)  # position flottante au-dessus du joueur
	popup.show_damage(amount)

func kill_by_plant() -> void:
	visible = false


func show_info_popup(text: String) -> void:
	var popup = preload("res://ItemsDecors/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)
	popup.show_damage(text)


func die() -> void:
	print("☠️ Le joueur est mort !")
	get_tree().reload_current_scene()


# Mise à jour du HUD
func update_banane_display():
	if banane_label:
		banane_label.text = "x %d" % banane_count


func update_coco_display():
	if coco_label:
		coco_label.text = "x %d" % coco_count


func update_seed_display():
	if seed_label:
		seed_label.text = "x %d" % seed_count


# loot
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


func collect_coco(amount: int = 1, enable_shooting: bool = false) -> void:
	coco_count += amount

	if enable_shooting:
		can_fire_coco = true
		show_info_popup("Lancé de coco activé !")
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
	# Récuperation des données des variables de GameState
	if game_state:
		game_state.seed_count = seed_count
	#mise a jour de l'HUD
	update_seed_display()
	print("Graines collectées :", seed_count)

# ralentissement (toile mygale)
func apply_web_effect():
	speed *= 0.5
	await get_tree().create_timer(10.0).timeout
	speed *= 2  # ou remets la valeur initiale

# Tir
func Shoot() -> void:
	#direction du tir
	var direction: int
	if $Sprite.scale.x < 0:
		direction = -1
	else:
		direction = 1
	# config touche tir de coco (ui_cancel)
	if Input.is_action_just_pressed("ui_cancel") and can_fire_coco:
		if coco_count > 0:
			coco_count -= 1
			update_coco_display()

			if game_state:
				game_state.coco_count = coco_count

			var coco_spell = spellCoco.instantiate()
			var spawn_pos = get_node("TurnAxis/CastPoint").get_global_position()
			coco_spell.start(spawn_pos, direction)
			get_tree().current_scene.add_child(coco_spell)

			await get_tree().create_timer(rate_of_fire).timeout
			can_fire_coco = true

		# Si plus de cocos, désactive tir
		if coco_count == 0:
			can_fire_coco = false

		# Mise à jour uniquement du bouton Coco
		var hud = game_state.health_bar.get_parent()
		if hud and hud.has_method("set_button_enabled"):
			hud.set_button_enabled(hud.get_node("Gamepad/Coco"), can_fire_coco)
		
		# ✅ Met à jour can_heal sans toucher au bouton de heal
		update_can_heal()


# reset des animations à chaque changements de lvl (geré dans le GameState)
func reset_state() -> void:
	animation_locked = false
	set_physics_process(true)
	$anim.stop()
