# res://Levels/Lvl3/Lvl_3b/Assets/Tribune/tribune_thrower.gd 


extends Node2D

@onready var intro_loots = $WaveIntroLoots
@onready var snake_loots = $WaveSnakeLoots
@onready var croco_loots = $WaveCrocoLoots
@onready var cannibal_loots = $WaveCannibalLoots

@export var throw_intro_wave = false
@export var throw_snake_wave = false
@export var throw_croco_wave = false
@export var throw_cannibal_wave = false
@export var throw_aoe_wave = false


func _process(_delta):
	if throw_intro_wave:
		throw_intro_wave = false
		throw_loots(intro_loots)

	if throw_snake_wave:
		throw_snake_wave = false
		throw_loots(snake_loots)

	if throw_croco_wave:
		throw_croco_wave = false
		throw_loots(croco_loots)

	if throw_cannibal_wave:
		throw_cannibal_wave = false
		throw_loots(cannibal_loots)

	if throw_aoe_wave:
		throw_aoe_wave = false

func throw_loots(container):
	print("🎁 THROW CONTAINER :", container.name, " count=", container.get_child_count())

	for loot in container.get_children():
		print("➡️ loot :", loot.name, " visible=", loot.visible, " pos=", loot.global_position)

		if loot.has_method("throw_now"):
			loot.throw_now()
		else:
			print("❌ pas de throw_now sur :", loot.name)
