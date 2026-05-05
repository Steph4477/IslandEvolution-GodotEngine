extends Node2D

@onready var base = $Base
@onready var stick = $Stick

const RADIUS = 100.0
var dragging = false
var input_vector := Vector2.ZERO
var joystick_dir := Vector2.ZERO

func _input(event):
	if event is InputEventScreenTouch and not event.pressed:
		_reset_joystick()

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if is_touch_inside_joystick(event.position) and event.pressed:
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
	joystick_dir = Vector2.ZERO
	_release_all_inputs()

	var gs = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	if gs and gs.player:
		gs.player.joystick_up = false
		gs.player.joystick_active = false

func _emit_actions(dir: Vector2):
	joystick_dir = dir.normalized()

	_release_all_inputs()

	if dir.x < -0.4:
		Input.action_press("ui_left")
	elif dir.x > 0.4:
		Input.action_press("ui_right")

	if dir.y < -0.4:
		Input.action_press("ui_up")
	elif dir.y > 0.4:
		Input.action_press("ui_down")

	# 📦 Envoi à Moko
	var gs = get_node_or_null("/root/GameManagement/SceneContainer/GameState")
	if gs and gs.player:
		gs.player.joystick_up = (dir.y < -0.4)
		gs.player.joystick_active = dir.length() > 0.2

func _release_all_inputs():
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")

func is_touch_inside_joystick(screen_pos: Vector2) -> bool:
	return screen_pos.distance_to(global_position) <= RADIUS
