extends Node2D

@export var texture_off: Texture2D
@export var texture_on: Texture2D

@onready var area = $Area2D
@onready var turn_on = $TurnOn
@onready var turn_off = $TurnOff

func _ready():
	# Applique les textures exportées à l'instance
	if texture_off:
		turn_off.texture = texture_off
	if texture_on:
		turn_on.texture = texture_on

	# État initial
	turn_on.visible = false
	turn_off.visible = true

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		turn_on.visible = true
		turn_off.visible = false
