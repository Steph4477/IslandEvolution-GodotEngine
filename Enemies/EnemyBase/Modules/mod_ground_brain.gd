extends Node
# Brain ground générique : décide state + anim + move/attack simple

@export var walk_speed = 80
@export var detect_range = 260
@export var attack_range = 40
@export var attack_cooldown = 1.2

var e = null
var anim = null

var state = ""
var can_attack = true

func setup(enemy):
	e = enemy
	anim = e.get_node("Rotator/AnimationPlayer")

func tick(_delta):
	if e.player == null:
		e.velocity.x = 0
		_set_state("idle")
		return

	_face_player()

	var dist = e.global_position.distance_to(e.player.global_position)

	# détection simple (sans dépendre d’Area2D)
	if dist <= detect_range:
		e.player_detected = true
	else:
		e.player_detected = false

	# attaque
	if e.player_detected and dist <= attack_range:
		e.velocity.x = 0
		_try_attack()
		return

	# poursuite
	if e.player_detected:
		e.velocity.x = walk_speed * e.facing
		_set_state("walk")
		return

	# idle
	e.velocity.x = 0
	_set_state("idle")

func on_player_updated(_p):
	pass

func on_hit(_dmg):
	if e.is_dead:
		return
	_set_state("onhit")
	await e.get_tree().create_timer(0.2).timeout
	state = ""

func on_dead():
	_set_state("die")

func _try_attack():
	if not can_attack:
		_set_state("idle")
		return

	can_attack = false
	_set_state("attack")
	await e.get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _face_player():
	var dx = e.player.global_position.x - e.global_position.x
	if dx > 0:
		e.set_facing(1)
	elif dx < 0:
		e.set_facing(-1)

func _set_state(s):
	if state == s:
		return
	state = s
	anim.play(s)
