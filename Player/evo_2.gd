extends CharacterBody2D

@export var speed = 500
@export var max_hp = 2000
@export var jump_force = -1200
@export var gravity = 1200
@export var pv = max_hp
@onready var health_bar = $HealthBar/ProgressBar
@onready var banane_label = get_node("../Hud/HBoxContainerBanane/BananeCountLabel")
@onready var coco_label = get_node("../Hud/HBoxContainerCoco/CocoCountLabel")

# GameState
var game_state
var can_fire_banane
var banane_count
var can_fire_coco
var coco_count

# Double saut
var jump_count = 0

# Tir

var spellCoco = preload("res://Tir/coco.tscn")
var rate_of_fire = 0.4

# Escalade
var is_climbing = false
var is_climbingCoco = false
var climb_speed = 100.0
var can_climb = false
var can_climbCoco = false

# Mouvement
var moving_left = false
var moving_right = false
var jumping = false
var moving_down = false

# Effet toile
var is_webbed = false

func _ready():
	$Camera2D.make_current()
	await get_tree().process_frame

	var game_state = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	if game_state:
		set_game_state(game_state)
	health_bar.max_value = max_hp
	health_bar.value = pv

func set_game_state(gs):
	game_state = gs
	banane_count = game_state.banane_count
	coco_count = game_state.coco_count
	can_fire_banane = game_state.can_fire_banane
	can_fire_coco = game_state.can_fire_coco
	gs.set_player(self)

func set_can_climb(value: bool) -> void:
	can_climb = value
	if !value:
		is_climbing = false

func set_can_climbCoco(value: bool) -> void:
	can_climbCoco = value
	if !value:
		is_climbingCoco = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		jump_count = 0

	var direction := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if moving_left:
		direction = -1
	elif moving_right:
		direction = 1
	velocity.x = direction * speed

	if direction > 0:
		$anim.flip_h = false
	elif direction < 0:
		$anim.flip_h = true

	if can_climb and Input.is_action_pressed("ui_up"):
		is_climbing = true
	elif !can_climb:
		is_climbing = false

	if can_climbCoco and Input.is_action_pressed("ui_up"):
		is_climbingCoco = true
	elif !can_climbCoco:
		is_climbingCoco = false

	if is_climbing:
		velocity.y = 0
		if Input.is_action_pressed("ui_up"):
			velocity.y = -climb_speed
		elif Input.is_action_pressed("ui_down"):
			velocity.y = climb_speed

	if is_climbingCoco:
		velocity.y = 0
		if Input.is_action_pressed("ui_up"):
			velocity.y = -climb_speed
		elif Input.is_action_pressed("ui_down"):
			velocity.y = climb_speed
	else:
		if Input.is_action_just_pressed("ui_up") and jump_count < 2:
			velocity.y = jump_force
			jump_count += 1
		else:
			velocity.y += gravity * delta

	move_and_slide()

	update_animation()



func update_animation() -> void:
	if is_webbed:
		$anim.play("walk_toile")
		return
	if is_climbing:
		$anim.play("climb")
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
		$anim.play("walk")
	else:
		$anim.play("idle")

func on_hit(damage: int) -> void:
	pv -= damage
	pv = clamp(pv, 0, max_hp)
	if health_bar:
		health_bar.value = pv
	show_damage_popup(damage)

func show_damage_popup(amount: int) -> void:
	var popup = preload("res://ItemsDecors/damage_popup.tscn").instantiate()
	add_child(popup)
	popup.position = Vector2(0, -30)
	popup.show_damage(amount)
	if pv <= 0:
		die()

func die() -> void:
	get_tree().reload_current_scene()

func update_banane_display():
	if banane_label:
		banane_label.text = "x %d" % banane_count

func update_coco_display():
	if coco_label:
		coco_label.text = "x %d" % coco_count

func collect_banane(amount: int = 1, enable_shooting: bool = false) -> void:
	banane_count += amount
	if enable_shooting:
		can_fire_banane = true
	if game_state:
		game_state.can_fire_banane = can_fire_banane
		game_state.banane_count = banane_count
	update_banane_display()

func collect_coco(amount: int = 1, enable_shooting: bool = false) -> void:
	coco_count += amount
	if enable_shooting:
		can_fire_coco = true
	if game_state:
		game_state.can_fire_coco = can_fire_coco
		game_state.coco_count = coco_count
	update_coco_display()

func apply_web_effect():
	if is_webbed:
		return
	is_webbed = true

	var original_speed = speed
	speed *= 0.5
	$anim.play("walk_toile")

	await get_tree().create_timer(3.0).timeout

	speed = original_speed
	is_webbed = false
