extends Node2D

@onready var col = $Area2D/Col
@onready var sprite = $Fire

var gs
var collected = false

func _ready():
	gs = get_node("/root/GameState")

	if gs.fire_buff_unlocked:
		queue_free()

func _on_area_2d_body_entered(body):
	if collected:
		return

	if body.is_in_group("Player"):
		collected = true
		body.collect_skills.collect_fire()
		queue_free()
