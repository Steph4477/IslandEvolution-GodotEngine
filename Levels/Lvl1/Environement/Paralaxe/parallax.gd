extends Node2D

@export var tree_speed = 0.1
@export var sky_speed = 0.05
@export var plant_speed = 0.10
@export var image_scale = 2.0
@export var level_width = 10000.0

var gs
var camera = null
var last_camera_x = 0.0
var ready_parallax = false

@onready var tree_layer = $TreeLayer
@onready var tree_sprite = $TreeLayer/Sprite2D

@onready var sky_layer = $SkyLayer
@onready var sky_sprite = $SkyLayer/Sprite2D

@onready var plant_layer = $PlantLayer
@onready var plant_sprite = $PlantLayer/Sprite2D


func _ready():


	gs = get_node("/root/GameState")

	setup_layer(tree_layer, tree_sprite)
	setup_layer(sky_layer, sky_sprite)
	setup_layer(plant_layer, plant_sprite)

	await get_tree().process_frame
	await get_tree().create_timer(5.0).timeout

	camera = gs.player.get_node("Camera2D")
	last_camera_x = camera.global_position.x
	ready_parallax = true


func setup_layer(layer, sprite_ref):
	sprite_ref.centered = false
	sprite_ref.scale = Vector2(image_scale, image_scale)

	var width = sprite_ref.texture.get_width() * image_scale
	var count = int(level_width / width) + 4

	for i in range(count):
		var sprite = sprite_ref.duplicate()
		layer.add_child(sprite)
		sprite.centered = false
		sprite.scale = Vector2(image_scale, image_scale)
		sprite.position.x = width * i
		sprite.position.y = 0
		sprite.visible = true

	sprite_ref.visible = false


func _process(_delta):
	if ready_parallax == false:
		return

	var camera_delta = camera.global_position.x - last_camera_x
	last_camera_x = camera.global_position.x

	tree_layer.position.x -= camera_delta * tree_speed
	sky_layer.position.x -= camera_delta * sky_speed
	plant_layer.position.x -= camera_delta * plant_speed
