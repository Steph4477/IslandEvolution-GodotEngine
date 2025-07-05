extends CanvasLayer

@onready var root = $Root
@onready var base = $Root/Base
@onready var stick = $Root/Stick

var dragging := false
var input_vector := Vector2.ZERO
const RADIUS := 100.0

func _ready():
	# Toujours visible, centré sur la base au départ
	stick.position = base.position

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging = true
		else:
			_reset_joystick()

	elif event is InputEventScreenDrag and dragging:
		var local_pos = root.get_local_mouse_position()
		var start_pos = base.position
		var delta = local_pos - start_pos

		if delta.length() > RADIUS:
			delta = delta.normalized() * RADIUS

		input_vector = delta / RADIUS
		stick.position = start_pos + delta
		_emit_actions(input_vector)

func _reset_joystick():
	dragging = false
	input_vector = Vector2.ZERO
	stick.position = base.position  # ✅ centre parfaitement

	# Relâche toutes les directions
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")

func _emit_actions(dir: Vector2):
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	Input.action_release("ui_up")
	Input.action_release("ui_down")

	if dir.x < -0.4:
		Input.action_press("ui_left")
	elif dir.x > 0.4:
		Input.action_press("ui_right")

	if dir.y < -0.4:
		Input.action_press("ui_up")
	elif dir.y > 0.4:
		Input.action_press("ui_down")
