extends EnemyBase
class_name EnemyFlightBase

var flight_velocity = Vector2.ZERO

var sprite = null
var rotator = null

func _ready():
	super._ready()

	if has_node("Rotator"):
		rotator = $Rotator

	if has_node("Rotator/Sprite"):
		sprite = $Rotator/Sprite
	elif has_node("Sprite"):
		sprite = $Sprite

func refresh_player():
	if gs == null:
		gs = get_node("/root/GameState")

	player = gs.player

func get_target_position():
	if player == null:
		refresh_player()
		if player == null:
			return global_position

	if player.has_node("TurnAxis"):
		return player.get_node("TurnAxis").global_position

	return player.global_position

func get_target_distance():
	return global_position.distance_to(get_target_position())

func move_flight():
	velocity = flight_velocity
	move_and_slide()

func stop_flight():
	flight_velocity = Vector2.ZERO
	velocity = Vector2.ZERO

func update_flip():
	if sprite == null:
		return

	if flight_velocity.x == 0:
		return

	if flight_velocity.x < 0:
		sprite.scale.x = abs(sprite.scale.x)
	else:
		sprite.scale.x = -abs(sprite.scale.x)

func play_flight_anim(anim_name):
	if anim == null:
		return

	if not anim.has_animation(anim_name):
		return

	if anim.current_animation != anim_name:
		anim.play(anim_name)

func can_flight_attack_player():
	if not can_attack_player():
		return false

	return true

func do_attack_damage():
	player.damage_mod.on_hit(damage)
