extends CharacterBody2D

@export var max_hp = 300
@export var speed = 800
@export var attack_range = 1000
@export var stop_distance = 60
@export var cooldown = 1
@export var damage = 100

const GRAVITY = 2000

@onready var health_bar = $HealthBar/ProgressBar
@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var gloups_sprite = $GloupsSprite
@onready var burp_anim = get_node_or_null("BurpAnimationPlayer")

var pv = 0
var player = null
var is_attacking = false

func _ready():
	pv = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = pv
	find_and_bind_player()
	if gloups_sprite:
		gloups_sprite.visible = false

func _physics_process(delta):
	apply_gravity(delta)

	if is_instance_valid(player) and not is_attacking:
		var target_pos = player.global_position
		var turn_axis = player.get_node_or_null("TurnAxis")
		if turn_axis:
			target_pos = turn_axis.global_position

		var to_target = target_pos - global_position
		var distance = to_target.length()

		# ⚡ Flip du Rotator entier au lieu du sprite seulement
		if distance > 1:
			if to_target.x > 0:
				$Rotator.scale.x = abs($Rotator.scale.x)
			else:
				$Rotator.scale.x = -abs($Rotator.scale.x)

		if distance < attack_range and distance > stop_distance:
			var direction = to_target.normalized()
			velocity.x = direction.x * speed
		else:
			velocity.x = 0
	else:
		velocity.x = 0

	move_and_slide()


func apply_gravity(delta):
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += GRAVITY * delta

# --- Combat ---
func on_hit(damage_taken):
	pv -= damage_taken
	if health_bar:
		if pv < 0:
			health_bar.value = 0
		else:
			health_bar.value = pv
	show_damage_popup(damage_taken)
	if pv <= 0:
		die()

func show_damage_popup(amount):
	var scene = preload("res://Interface/Popup/Damage_popup/damage_popup.tscn")
	var popup = scene.instantiate()
	add_child(popup)
	popup.position = Vector2(0, -500)
	popup.show_damage(amount)

func die():
	queue_free()

# --- Trouve Moko ----
func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player):
	player = new_player

# ============================ ZONES ===========================
func _on_area_2d_body_entered(body):
	if is_attacking:
		return
	if body.is_in_group("Player") or body.name == "Player":
		is_attacking = true
		velocity.x = 0

		# 🐊 Joue l'animation d'attaque
		if anim:
			if anim.has_animation("attaque"):
				anim.play("attaque")
			elif anim.has_animation("attack"):
				anim.play("attack")

		# 👻 Crée le ghost à la position de Moko
		var sprite_ref = body.get_node_or_null("Node2D/Sprite")
		var ghost_sprite = null
		if sprite_ref:
			ghost_sprite = Sprite2D.new()
			ghost_sprite.texture = sprite_ref.texture
			ghost_sprite.scale = sprite_ref.scale
			ghost_sprite.rotation = sprite_ref.rotation
			ghost_sprite.flip_h = sprite_ref.flip_h
			ghost_sprite.flip_v = sprite_ref.flip_v
			if has_node("Rotator/Muzzle"):
				ghost_sprite.global_position = $Rotator/Muzzle.global_position
			else:
				ghost_sprite.global_position = global_position
			get_tree().current_scene.add_child(ghost_sprite)

		# 🫥 Cache Moko immédiatement
		if body.has_method("kill_by_plant"):
			body.kill_by_plant()

		# 💀 Ghost avalé
		if ghost_sprite:
			var tween = create_tween()
			tween.tween_property(ghost_sprite, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(Callable(ghost_sprite, "queue_free"))

		# ⏳ Attente de la fin de l'anim attaque
		if anim:
			await anim.animation_finished

		# 🤢 Gloups après attaque
		if gloups_sprite:
			gloups_sprite.visible = true
			if burp_anim and burp_anim.has_animation("burp"):
				burp_anim.play("burp")
				await burp_anim.animation_finished
			else:
				await get_tree().create_timer(0.5).timeout
			gloups_sprite.visible = false

		# ☠️ Tue Moko
		if body.has_method("die"):
			body.die()
		elif body.has_method("on_hit"):
			body.on_hit(1000000)

		await get_tree().create_timer(cooldown).timeout
		is_attacking = false
