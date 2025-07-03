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

	# Recharge les potions depuis GameState
	for i in range(banane_count):
		heal_potions.append(game_state.heal_amount)
	
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
		return  # Ignore toute physique pendant une animation verrouillée si passage de porte
		
	# Gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		jump_count = 0
		
	# Ramper
	if is_ramping:
		velocity.y = 0  # Pas de saut ni chute quand on rampe
		
	# Direction 
	var direction := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if moving_left:
		direction = -1
	elif moving_right:
		direction = 1
	velocity.x = direction * speed
	
	# Flip sprite direction marche
	if direction > 0:
		$Sprite.scale.x = abs($Sprite.scale.x)
	elif direction < 0:
		$Sprite.scale.x = -abs($Sprite.scale.x)
		
	# Détecte si on est en train de grimper sur bananier
	if can_climb and Input.is_action_pressed("ui_up"):
		is_climbing = true
	elif !can_climb:
		is_climbing = false
		
	# Détecte si on est en train de grimper sur cocotier
	if can_climbCoco and Input.is_action_pressed("ui_up"):
		is_climbingCoco = true
	elif !can_climbCoco:
		is_climbingCoco = false
		
	# Appliquer mouvement vertical(escalade bananier)
	if is_climbing:
		# On grimpe
		velocity.y = 0  # neutralise la gravité
		if Input.is_action_pressed("ui_up"):
			velocity.y = -climb_speed
		elif Input.is_action_pressed("ui_down"):
			velocity.y = climb_speed
		
	# Appliquer mouvement vertical(escalade cocotier)
	if is_climbingCoco:
		# On grimpe
		velocity.y = 0  # neutralise la gravité
		if Input.is_action_pressed("ui_up"):
			velocity.y = -climb_speed
		elif Input.is_action_pressed("ui_down"):
			velocity.y = climb_speed
	else:
		# On saute et on peut faire un double saut
		if Input.is_action_just_pressed("ui_up") and jump_count < 2:
		#if (Input.is_action_just_pressed("ui_up") or jumping) and jump_count < 2: # Avec UI
			velocity.y = jump_force
			jump_count += 1
			#jumping = false # Avec UI
		else:
			# Appliquer gravité si pas de saut
			velocity.y += gravity * delta
		
	# Aplliquer mouvement ramper
	if can_ramp and Input.is_action_pressed("ramping") and is_on_floor():
		start_ramping()
		#appliquer la direction
		var ramp_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		velocity.x = ramp_dir * (speed * 0.4)
		# Flip sprite
		if ramp_dir > 0:
			$Sprite.scale.x = abs($Sprite.scale.x)
		elif ramp_dir < 0:
			$Sprite.scale.x = -abs($Sprite.scale.x)
		# Pas de saut / chute
		velocity.y = 0
	else:
		stop_ramping()
	
	# Appliquer mouvement
	move_and_slide()
	
	# Animation
	update_animation()
	
	# Tir
	if Input.is_action_pressed("ui_cancel") and can_fire_coco:
		SkillLoop()
	
	# Potion banane
	if Input.is_action_just_pressed("ui_accept"):
		use_banane_potion()


func use_banane_potion() -> void:
	if not can_heal:
		show_info_popup("⏳ En recharge...")
		return
	if pv >= max_pv:
		show_info_popup("PV au max !")
		return
	if heal_potions.is_empty():
		show_info_popup("Aucune potion !")
		return

	var amount = game_state.heal_amount if game_state and "heal_amount" in game_state else 0
	if amount <= 0:
		show_info_popup("Potion invalide !")
		return

	# 🧪 Active la potion
	can_heal = false
	heal_potions.pop_front()
	heal(amount)
	update_hud_buttons()

	# ⏱️ Cooldown visuel (cercle vert)
	if game_state.health_bar.get_parent():
		var hud = game_state.health_bar.get_parent()
		if hud.has_method("start_banane_cooldown"):
			hud.start_banane_cooldown(cooldown_popo)

	# ⏳ Délai avant de pouvoir reprendre une potion
	await get_tree().create_timer(cooldown_popo).timeout
	can_heal = true
	update_hud_buttons()

func heal(amount: int) -> void:
	pv = min(pv + amount, max_pv)
	if game_state:
		game_state.health_bar.set_value(pv)
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
	if Input.is_action_just_released("ui_up") or Input.is_action_just_released("ui_down"):
		is_climbingCoco = false
		velocity.y = 0
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


func show_damage_popup(amount: int) -> void:
	var popup = preload("res://ItemsDecors/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)  # position flottante au-dessus du joueur
	popup.show_damage(amount)
	if pv <= 0:
		die()


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


# Gestion de l'état des boutons du hud
func update_hud_buttons() -> void:
	if game_state.health_bar.get_parent():
		var hud = game_state.health_bar.get_parent()
		if hud.has_method("update_hud_buttons"):
			hud.update_hud_buttons(can_fire_coco, can_heal)



# loot
func collect_banane(amount: int = 1) -> void:
	if game_state:
		for i in range(amount):
			heal_potions.append(game_state.heal_amount)
	banane_count = heal_potions.size()
	if game_state:
		game_state.banane_count = banane_count
		# 🔓 Active le bouton tactile si dispo
		var hud = game_state.health_bar.get_parent()
		if hud and hud.has_method("set_button_enabled"):
			hud.set_button_enabled(hud.get_node("Gamepad/Health"), true)  # ← adapte le chemin si nécessaire
	update_banane_display()
	show_info_popup("5 jus de bananes récupérés !")
	update_hud_buttons()


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
	update_hud_buttons()

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
func SkillLoop() -> void:
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
			update_hud_buttons() 


# reset des animations à chaque changements de lvl (geré dans le GameState)
func reset_state() -> void:
	animation_locked = false
	set_physics_process(true)
	$anim.stop()


# --- Signaux boutons UI ---
#func _on_left_pressed() -> void:
	#moving_left = true
#func _on_left_released() -> void:
	#moving_left = false
#
#func _on_right_pressed() -> void:
	#moving_right = true
#func _on_right_released() -> void:
	#moving_right = false
#
#func _on_jump_pressed() -> void:
	#jumping = true
#func _on_jump_released() -> void:
	#jumping = false
#
#func _on_down_pressed() -> void:
	#moving_down = true
#func _on_down_released() -> void:
	#moving_down = false
#
#func _on_shoot_released() -> void:
	#pass # Replace with function body.
#func _on_shoot_pressed() -> void:
	#pass # Replace with function body.
