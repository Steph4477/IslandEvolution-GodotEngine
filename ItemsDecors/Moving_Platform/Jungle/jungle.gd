extends Node2D

@export var speed: float = 100.0
@export var distance: float = 200.0
@export_enum("Horizontal", "Vertical") var direction := 0

var start_position: Vector2
var moving_forward := true
var player: Node = null

func _ready():
	start_position = global_position

func _process(delta):
	var move := Vector2.ZERO

	if direction == 0:
		move.x = speed * delta
	else:
		move.y = speed * delta

	if not moving_forward:
		move = -move

	global_position += move

	if player:
		player.global_position += move

	if global_position.distance_to(start_position) >= distance:
		moving_forward = not moving_forward

func _on_player_detector_body_entered(body):
	if body.name == "Player":
		player = body

func _on_player_detector_body_exited(body):
	if body == player:
		player = null
