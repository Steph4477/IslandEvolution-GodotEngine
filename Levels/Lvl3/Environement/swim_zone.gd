extends Node2D

@onready var area = $Area2D

@export var current = Vector2(-120, 0)

var gs

func _ready():
	gs = get_node("/root/GameState")

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		body.is_swimming = true
		body.water_current = current

	if body.is_in_group("EnemiesSwim"):
		body.is_swim_croco = true
		body.water_current = current

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		body.is_swimming = false
		body.water_current = Vector2.ZERO

	if body.is_in_group("EnemiesSwim"):
		body.is_swim_croco = false
		body.water_current = Vector2.ZERO
