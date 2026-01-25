extends CharacterBody2D

@export var max_hp = 300
@export var speed = 800
@export var attack_range = 1000
@export var stop_distance = 60
@export var cooldown = 1
@export var damage = 100

const GRAVITY = 2000

@onready var sprite = $Rotator/Sprite2D
@onready var anim = $Rotator/AnimationPlayer
@onready var gloups_sprite = $GloupsSprite

var pv = 0
var player = null
var is_attacking = false

func _ready():
	pv = max_hp
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
		
		# Flip du Rotator
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
		
	if body.is_in_group("Player"):
		is_attacking = true
		velocity.x = 0
		
		#Joue l'animation d'attaque
		if anim.has_animation("attack"):
			anim.play("attack")
		
		# ========= CRÉATION DU GHOST =========
		var sprite_ref = null
		
		# Chemin pour le sprite de Moko
		if body.has_node("Node2D/Sprite"):
			sprite_ref = body.get_node("Node2D/Sprite")
		
		var ghost_sprite = null
		
		if sprite_ref and sprite_ref.texture:
			ghost_sprite = Sprite2D.new()
			ghost_sprite.texture = sprite_ref.texture
			ghost_sprite.scale = sprite_ref.scale
			ghost_sprite.rotation = sprite_ref.rotation
			ghost_sprite.flip_h = sprite_ref.flip_h
			ghost_sprite.flip_v = sprite_ref.flip_v
			
			# On part de la position de Moko
			ghost_sprite.global_position = body.global_position
			
			# On s'assure qu'il est devant le décor
			ghost_sprite.z_index = 100
			
			get_tree().current_scene.add_child(ghost_sprite)
			
		# Cache / tue Moko immédiatement 
		if body.effects_mod.has_method("kill_by_plant"):
			body.effects_mod.kill_by_plant()
		
		# Ghost avalé 
		if ghost_sprite:
			var tween = create_tween()
			# Position vers la bouche 
			if has_node("Rotator/Muzzle"):
				tween.tween_property(ghost_sprite, "global_position", $Rotator/Muzzle.global_position, 0)
			tween.tween_property(ghost_sprite, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_callback(Callable(ghost_sprite, "queue_free"))
			
		# Attente de la fin de l'anim attaque
		await anim.animation_finished
		
		# Gloups après attaque
		if gloups_sprite:
			gloups_sprite.visible = true
			await get_tree().create_timer(0.5).timeout
			gloups_sprite.visible = false
		
		# Tue Moko 
		if body.damage_mod.has_method("die"):
			body.damage_mod.die()
		
		is_attacking = false
