extends Node2D

@export var symbol_name = ""
@export var texture_off: Texture2D
@export var texture_on: Texture2D

@onready var turn_on = $TurnOn
@onready var turn_off = $TurnOff

var revealed = false

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
	if revealed:
		return
	if body.is_in_group("Player") :
		revealed = true
		turn_on.visible = true
		turn_off.visible = false
		
		var gs = get_node("/root/GameState")
		if not gs.correct_symbols.has(symbol_name) and gs.correct_symbols.size() < 3:
			gs.correct_symbols.append(symbol_name)
