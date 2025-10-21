extends Node2D

@export var swing_speed = 240.0
@export var max_angle = 30.0

var swinging = false
var angle_direction = 0
var attached_player = null
var expect_exit = false

@onready var pivot = $Pivot
@onready var collision_shape = $Pivot/Area2D/CollisionShape2D

func _process(delta):
	var target = 0.0
	if swinging:
		if angle_direction < 0:
			target = -max_angle
		elif angle_direction > 0:
			target = max_angle

	var diff = target - pivot.rotation_degrees
	var step = swing_speed * delta
	if abs(diff) <= step:
		pivot.rotation_degrees = target
	else:
		pivot.rotation_degrees += step * sign(diff)

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		attached_player = body
		body.attach_to_liana(self)
		swinging = true
		expect_exit = false

func _on_area_2d_body_exited(body):
	if body == attached_player and expect_exit:
		swinging = false
		angle_direction = 0
		attached_player = null
		expect_exit = false

func on_player_detach():
	swinging = false
	angle_direction = 0
	attached_player = null
	if pivot.rotation_degrees < 0.5:
		pivot.rotation_degrees = 0.0

func disable_collision_temporarily(time = 0.3):
	collision_shape.disabled = true
	await get_tree().create_timer(time).timeout
	collision_shape.disabled = false
