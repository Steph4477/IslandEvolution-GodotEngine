extends Node2D

@onready var intro_loots = $WaveIntroLoots
@onready var snake_loots = $WaveSnakeLoots
@onready var croco_loots = $WaveCrocoLoots

@export var throw_intro_wave = false
@export var throw_snake_wave = false
@export var throw_croco_wave = false


func _process(_delta):
	if throw_intro_wave:

		throw_intro_wave = false

		for loot in intro_loots.get_children():
			loot.throw_now()

	if throw_snake_wave:

		throw_snake_wave = false

		for loot in snake_loots.get_children():
			loot.throw_now()

	if throw_croco_wave:

		throw_croco_wave = false

		for loot in croco_loots.get_children():
			loot.throw_now()
