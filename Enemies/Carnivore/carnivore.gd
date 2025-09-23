extends CharacterBody2D

@onready var anim = $anim
@onready var stem := $Rotator/Stem
@onready var rotator := $Rotator
@onready var mouth := $Rotator/Mouth
@onready var burp_sprite := $Rotator/BurpSprite
@onready var burp_anim := $BurpAnimationPlayer

var player: Node2D = null
var attacking := false
var flipped := false

func _ready() -> void:
	find_and_bind_player()
	anim.play("attaque")
	burp_sprite.visible = false

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player: Node2D) -> void:
	player = new_player

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body != player or attacking:
		return

	if body.is_dead or not body.can_be_damaged:
		return

	attacking = true
	anim.play("attaque")

	# 👻 Ghost Moko avalé
	player.kill_by_plant()

	var ghost_sprite := Sprite2D.new()
	var sprite_ref = player.get_node("Sprite")
	ghost_sprite.texture = sprite_ref.texture
	ghost_sprite.scale = sprite_ref.scale
	ghost_sprite.rotation = sprite_ref.rotation
	ghost_sprite.flip_h = sprite_ref.flip_h
	ghost_sprite.flip_v = sprite_ref.flip_v
	ghost_sprite.global_position = $Muzzle.global_position
	get_tree().current_scene.add_child(ghost_sprite)

	var tween := create_tween()
	tween.tween_property(ghost_sprite, "scale", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(ghost_sprite, "queue_free"))
	await get_tree().create_timer(1.0).timeout

	# 🤢 Burp 
	burp_sprite.visible = true
	await get_tree().process_frame 
	burp_anim.play("burp")
	await burp_anim.animation_finished
	burp_sprite.visible = false

	# 💥 Inflige les dégâts (oneshot)
	body.on_hit(body.max_pv)

	attacking = false

func _process(delta: float) -> void:
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
