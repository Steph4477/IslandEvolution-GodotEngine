extends Node2D

@onready var area = $Area2D
@onready var breath_timer = $Area2D/BreathDelayTimer

@export var water_line_y = 600
@export var current = Vector2(-120, 0)

var gs
var player_in_water = false

func _ready():
	gs = get_node("/root/GameState")
	breath_timer.one_shot = true
	breath_timer.wait_time = 1.0

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		player_in_water = true

		# IMPORTANT: on force le hide au moment de l'entrée
		if gs.hud:
			gs.hud.hide_breathbar()

		body.start_underwater_breath()
		body.is_swimming_under_water = true
		body.water_current = current

		breath_timer.stop()
		breath_timer.start()

	if body.is_in_group("EnemiesSwim"):
		body.is_swim_croco = true
		body.water_current = current

func _on_area_2d_body_exited(body):
	if body.is_in_group("Player"):
		player_in_water = false

		breath_timer.stop()
		if gs.hud:
			gs.hud.hide_breathbar()

		body.stop_underwater_breath(true)
		body.is_swimming_under_water = false
		body.water_current = Vector2.ZERO

		# FIX: autorise un saut immédiat en sortie d'eau
		body.jump_count = 0
		body.did_double_jump = false

	if body.is_in_group("EnemiesSwim"):
		body.is_swim_croco = false
		body.water_current = Vector2.ZERO

func _on_breath_delay_timer_timeout():
	if not player_in_water:
		return
	if gs.hud:
		gs.hud.show_breathbar()

func _on_area_2d_area_exited(bubble):
	if bubble.is_in_group("air_bubbles"):
		var bubble_root = bubble.get_parent()  # AirBubble (Node2D)
		bubble_root.queue_free()
