extends Node2D

@onready var area = $Area2D
@export var water_line_y = 600
@export var current = Vector2(-120, 0)

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.start_underwater_breath()
		body.is_swimming_under_water = true
		body.water_current = current
		
	if body.is_in_group("EnemiesSwim"):
		body.is_swim_croco = true
		body.water_current = current

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		body.stop_underwater_breath(true)
		body.is_swimming_under_water = false
		body.water_current = Vector2.ZERO

	if body.is_in_group("EnemiesSwim"):
		body.is_swim_croco = false
		body.water_current = Vector2.ZERO
