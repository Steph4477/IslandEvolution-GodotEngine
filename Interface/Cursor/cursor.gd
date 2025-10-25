extends CanvasLayer

@export var cursor_speed = 900
@export var confine_to_screen = true
@export var idle_hide_delay = 5.0

var cursor
var sprite
var idle_time = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)

	cursor = $Cursor
	sprite = cursor.get_node("Sprite2D")
	sprite.visible = false

	var r = get_tree().root.get_visible_rect()
	cursor.position = r.position + r.size * 0.5

func _process(delta):
	var move = Vector2.ZERO

	if Input.is_action_pressed("gc_right"):
		move.x += 1
	if Input.is_action_pressed("gc_left"):
		move.x -= 1
	if Input.is_action_pressed("gc_down"):
		move.y += 1
	if Input.is_action_pressed("gc_up"):
		move.y -= 1

	if move != Vector2.ZERO:
		cursor.position += move.normalized() * cursor_speed * delta
		on_activity()

	if confine_to_screen:
		var r = get_tree().root.get_visible_rect()
		cursor.position = cursor.position.clamp(r.position, r.position + r.size)

	if Input.is_action_just_pressed("gc_click"):
		mouse_button(true, MOUSE_BUTTON_LEFT)
		on_activity()
	if Input.is_action_just_released("gc_click"):
		mouse_button(false, MOUSE_BUTTON_LEFT)
		on_activity()

	idle_time += delta
	if idle_time >= idle_hide_delay and sprite.visible:
		sprite.visible = false

func unhandled_input(event):
	if event is InputEventMouseMotion:
		cursor.position = event.position
		if confine_to_screen:
			var r = get_tree().root.get_visible_rect()
			cursor.position = cursor.position.clamp(r.position, r.position + r.size)
		on_activity()

func mouse_button(pressed, button):
	var ev = InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = pressed
	ev.position = cursor.position
	ev.global_position = cursor.position
	get_viewport().push_input(ev)

func on_activity():
	idle_time = 0.0
	if sprite.visible == false:
		sprite.visible = true
