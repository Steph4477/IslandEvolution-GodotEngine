extends Node2D

@onready var base = $Base
@onready var stick = $Stick

var dragging := false
var input_vector := Vector2.ZERO
const RADIUS := 100.0
var jump_triggered := false

func _ready():
	var screen_size = get_viewport().get_visible_rect().size
	position = screen_size - Vector2(200, 200)
	base.position = Vector2.ZERO
	stick.position = Vector2.ZERO

func _input(event):
	if event is InputEventScreenTouch and not event.pressed:
		_reset_joystick()

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if not is_touch_inside_joystick(event.position):
			return
		if event.pressed:
			dragging = true

	elif event is InputEventScreenDrag and dragging:
		var delta = event.position - global_position
		if delta.length() > RADIUS:
			delta = delta.normalized() * RADIUS

		input_vector = delta / RADIUS
		stick.position = delta
		_emit_actions(input_vector)

func _reset_joystick():
	if not dragging:
		return
	dragging = false
	input_vector = Vector2.ZERO
	stick.position = Vector2.ZERO

	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_down")

	# 🔁 Pas de reset de `ui_up` si sur arbre (on vérifie dans _emit_actions)

func _emit_actions(dir: Vector2):
	Input.action_release("ui_left")
	Input.action_release("ui_right")

	# Déplacement horizontal
	if dir.x < -0.4:
		Input.action_press("ui_left")
	elif dir.x > 0.4:
		Input.action_press("ui_right")

	# --- Récupération du joueur depuis GameState ---
	var gs = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	var player = gs.player if gs and gs.has_method("player") else null

	var climbing := false
	if player:
		climbing = player.can_climb or player.can_climbCoco

	# GRIMPE = on maintient ui_up tant que le joueur est collé à un arbre
	if dir.y < -0.4:
		Input.action_press("ui_up")
	else:
		# ❗ On ne relâche ui_up que si PAS en train de grimper
		if not climbing:
			Input.action_release("ui_up")

	# SAUT : seulement si fort vers le haut et pas déjà sauté ni en grimpe
	if dir.y < -0.8 and not climbing and not jump_triggered:
		if gs and gs.has_method("trigger_player_jump"):
			print("📡 joystick vers le haut -> trigger_player_jump()")
			gs.trigger_player_jump()
			jump_triggered = true
	elif dir.y > -0.6:
		jump_triggered = false

func is_touch_inside_joystick(screen_pos: Vector2) -> bool:
	var dist = screen_pos.distance_to(global_position)
	return dist <= RADIUS
