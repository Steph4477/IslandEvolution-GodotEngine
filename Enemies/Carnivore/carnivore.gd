extends CharacterBody2D

@export var damage = 9999  # dégâts énormes = oneshot
@onready var anim = $anim
@onready var stem := $Rotator/Stem
@onready var rotator := $Rotator
@onready var mouth := $Rotator/Mouth

var player: Node2D = null
var attacking := false
var flipped := false  # indique si la tige est retournée

func _ready() -> void:
	find_and_bind_player()
	anim.play("attaque")

func find_and_bind_player():
	var gs = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	if gs:
		player = gs.player
		gs.connect("player_updated", Callable(self, "_on_player_changed"))

func _on_player_changed(new_player: Node2D) -> void:
	player = new_player

func show_burp_popup():
	var popup := Label.new()
	popup.text = "BURP!"
	popup.label_settings = LabelSettings.new()
	popup.label_settings.font_size = 32
	popup.label_settings.outline_size = 2
	popup.label_settings.outline_color = Color.BLACK
	popup.modulate = Color.LIGHT_GREEN
	popup.anchor_left = 0.5
	popup.anchor_top = 1.0
	popup.position = Vector2(0, -40)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	add_child(popup)

	var tween := create_tween()
	tween.tween_property(popup, "position:y", popup.position.y - 30, 0.6)
	tween.tween_property(popup, "modulate:a", 0.0, 0.6)
	tween.tween_callback(Callable(popup, "queue_free"))

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body != player or attacking:
		return

	attacking = true
	anim.play("attaque")

	await get_tree().create_timer(0.2).timeout  # morsure

	if player.has_method("kill_by_plant"):
		player.kill_by_plant()

		var ghost_sprite := Sprite2D.new()
		var sprite_ref = player.get_node("Sprite")

		ghost_sprite.texture = sprite_ref.texture
		ghost_sprite.hframes = sprite_ref.hframes if sprite_ref.has_method("hframes") else 1
		ghost_sprite.vframes = sprite_ref.vframes if sprite_ref.has_method("vframes") else 1
		ghost_sprite.frame = sprite_ref.frame if sprite_ref.has_method("frame") else 0
		ghost_sprite.scale = sprite_ref.scale
		ghost_sprite.rotation = sprite_ref.rotation
		ghost_sprite.flip_h = sprite_ref.flip_h
		ghost_sprite.flip_v = sprite_ref.flip_v

		ghost_sprite.global_position = $Muzzle.global_position
		get_tree().current_scene.add_child(ghost_sprite)

		var tween := create_tween()
		tween.tween_property(ghost_sprite, "scale", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(ghost_sprite, "rotation_degrees", 720.0, 0.5)
		await tween.finished
		ghost_sprite.queue_free()

		show_burp_popup()

		await get_tree().create_timer(0.3).timeout
		player.die()

	await anim.animation_finished
	
	attacking = false

func _process(delta: float) -> void:
	if not player:
		return

	var player_dir = player.global_position.x - global_position.x

	# Flip horizontal de toute la plante
	if player_dir < 0 and not flipped:
		rotator.scale.x = 1
		flipped = true
	elif player_dir > 0 and flipped:
		rotator.scale.x = -1
		flipped = false

	# Rotation bouche fluide
	var mouth_pos = mouth.global_position
	var dir = player.global_position - mouth_pos
	var target_angle = dir.angle() + PI
	mouth.rotation = lerp_angle(mouth.rotation, target_angle, delta * 5.0)
