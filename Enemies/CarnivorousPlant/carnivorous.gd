extends CharacterBody2D

@onready var anim = $anim
@onready var stem = $Rotator/Stem
@onready var rotator = $Rotator
@onready var mouth = $Rotator/Mouth
@onready var burp_sprite = $BurpSprite
@onready var burp_anim = $BurpAnimationPlayer

var player = null
var attacking = false
var flipped = false


func _ready():
	find_and_bind_player()
	anim.play("attaque")
	burp_sprite.visible = false


func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))


func _on_player_changed(new_player):
	player = new_player


func _on_area_2d_body_entered(body):
	if body != player or attacking:
		return

	if body.is_dead or not body.can_be_damaged:
		return

	attacking = true
	anim.play("attaque")

	# 👻 cache Moko 
	player.visible = false

	_spawn_ghost_from_player()

	await get_tree().create_timer(1.0).timeout

	# 🤢 Burp
	burp_sprite.visible = true
	await get_tree().process_frame
	burp_anim.play("burp")
	await burp_anim.animation_finished
	burp_sprite.visible = false

	# 💥 oneshot
	if body.damage_mod:
		body.damage_mod.on_hit(body.max_pv)
	else:
		body.on_hit(body.max_pv)

	attacking = false


func _spawn_ghost_from_player():
	var sprite_ref = player.get_node_or_null("Node2D/Sprite")
	if sprite_ref == null:
		return

	var tex = sprite_ref.texture
	if tex == null:
		return

	var ghost_sprite = Sprite2D.new()
	ghost_sprite.texture = tex

	# Copie visuel
	ghost_sprite.scale = sprite_ref.scale
	ghost_sprite.rotation = sprite_ref.rotation
	ghost_sprite.flip_h = sprite_ref.flip_h
	ghost_sprite.flip_v = sprite_ref.flip_v
	ghost_sprite.z_index = 999

	# Position spawn (Muzzle > bouche)
	var spawn_pos = mouth.global_position
	if has_node("Muzzle"):
		spawn_pos = $Muzzle.global_position
	ghost_sprite.global_position = spawn_pos

	# IMPORTANT : même parent que le player (pas current_scene)
	player.get_parent().add_child(ghost_sprite)

	var tween = create_tween()
	tween.tween_property(ghost_sprite, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(ghost_sprite, "queue_free"))


func _process(delta):
	if not player:
		return

	var player_dir = player.global_position.x - global_position.x

	if player_dir < 0 and not flipped:
		rotator.scale.x = 1
		flipped = true
	elif player_dir > 0 and flipped:
		rotator.scale.x = -1
		flipped = false

	var mouth_pos = mouth.global_position
	var dir = player.global_position - mouth_pos
	var target_angle = dir.angle() + PI
	mouth.rotation = lerp_angle(mouth.rotation, target_angle, delta * 5.0)
